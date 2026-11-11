"""Command-line interface for the Papyrxis Workspace publishing engine."""
from __future__ import annotations

import argparse
import time
from pathlib import Path

from .build import BuildError, clean_project
from .changelog import generate_changelog
from .config import ConfigError, load_config
from .export import ExportError, export_project
from .logger import close_all, get_logger, log, native_logger_available
from .process import CommandError, run_checked
from .project import build_documents, clean_document, list_documents, verify_manifest
from .tags import generate_tags


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="px", description="Build and publish LaTeX documents")
    parser.add_argument("--root", default=".", help="project directory")
    parser.add_argument("--config", default="workspace.yml", help="project YAML configuration")
    commands = parser.add_subparsers(dest="command", required=True)

    init = commands.add_parser("init", help="create a project configuration and a basic source")
    init.add_argument("--type", default="book", choices=("book", "booklet", "article", "cv", "collection"))
    init.add_argument("--language", default="en", choices=("en", "fa", "both"))
    init.add_argument("--force", action="store_true")
    init.add_argument("--style", choices=("personal", "academic", "ieee", "technical"),
                       help="article profile (valid for --type article or collection)")

    build = commands.add_parser("build", help="build all documents or a selected document")
    build.add_argument("document_id", nargs="?", help="optional document id")
    build.add_argument("--edition", help="optional edition id")
    build.add_argument("--language", action="append", default=[], help="v1-compatible edition selector")
    build.add_argument("--dry-run", action="store_true")
    build.add_argument("--keep-going", action="store_true")
    list_cmd = commands.add_parser("list", help="list documents, editions and build status")
    list_cmd.add_argument("--json", action="store_true")
    clean = commands.add_parser("clean", help="remove generated output")
    clean.add_argument("document_id", nargs="?")
    clean.add_argument("--edition", help="optional edition id when cleaning one v2 document")
    commands.add_parser("verify", help="verify build manifest and generated PDFs")
    watch = commands.add_parser("watch", help="rebuild when source files change")
    watch.add_argument("--interval", type=float, default=1.5)

    export = commands.add_parser("export", help="export configured sources to Markdown")
    export.add_argument("--target", action="append", default=[])

    commands.add_parser("tags", help="print normalized export tags")
    changelog = commands.add_parser("changelog", help="generate categorized release notes")
    changelog.add_argument("--output", default="CHANGELOG.md")
    changelog.add_argument("--version", default="Unreleased")
    changelog.add_argument("--dry-run", action="store_true")

    tag = commands.add_parser("tag", help="create an annotated Git tag")
    tag.add_argument("name")
    tag.add_argument("--sign", action="store_true")
    push = commands.add_parser("push", help="push current branch and optionally tags")
    push.add_argument("--tags", action="store_true")

    log_cmd = commands.add_parser("log", help="write a structured log through m-mdy-m/log.c")
    log_cmd.add_argument("--level", choices=("trace", "debug", "info", "warn", "error", "fatal"), default="info")
    log_cmd.add_argument("--component", default="legacy-shell")
    log_cmd.add_argument("message", nargs="+")
    verify = commands.add_parser("verify-pdf", help="verify a generated PDF artifact")
    verify.add_argument("path")
    commands.add_parser("doctor", help="check publishing tools and the native logger")
    return parser


def _init(root: Path, kind: str, language: str, force: bool, style: str | None = None) -> Path:
    import yaml

    root = root.resolve()
    root.mkdir(parents=True, exist_ok=True)
    config_path = root / "workspace.yml"
    if config_path.exists() and not force:
        raise FileExistsError(f"{config_path} already exists; pass --force to replace the config")
    if style is not None and kind not in {"article", "collection"}:
        raise ValueError("--style can only be used with --type article or collection")
    article_style = style or "personal"
    languages = ["en", "fa"] if language == "both" else [language]
    if not languages or any(code not in {"en", "fa"} for code in languages):
        raise ValueError("language must be en, fa or both")

    generated: dict[Path, str] = {}
    directories: set[Path] = {root / "references"}
    entries: dict[str, dict[str, str]] = {}
    title = root.name.replace("-", " ").replace("_", " ").title()

    for code in languages:
        directory = root if len(languages) == 1 else root / code
        directories.update({directory / "figures", directory / "frontmatter", directory / "backmatter"})
        doc_title = "عنوان نمونه" if code == "fa" else title
        author = "نام نویسنده" if code == "fa" else "Your Name"

        if kind in {"book", "booklet"}:
            directories.add(directory / "chapters")
            chapter_path = directory / "chapters" / "chapter-01.tex"
            chapter_title = "فصل اول" if code == "fa" else "Getting Started"
            chapter_text = "متن نمونه برای شروع نگارش." if code == "fa" else "A clean starting point for your book."
            generated[chapter_path] = f"\\chapter{{{chapter_title}}}\n{chapter_text}\n"

            if code == "fa":
                language_preamble = (
                    "\\usepackage{graphicx}\n"
                    "\\usepackage{amsmath,amssymb}\n"
                )
            else:
                language_preamble = (
                    "\\usepackage[T1]{fontenc}\n"
                    "\\usepackage{lmodern}\n"
                    "\\usepackage{microtype}\n"
                    "\\usepackage{graphicx}\n"
                    "\\usepackage{amsmath,amssymb}\n"
                )
            language_preamble += (
                "\\usepackage[backend=biber,style=authoryear,sorting=nyt]{biblatex}\n"
                "\\addbibresource{references/references.bib}\n"
                "\\usepackage{geometry}\n"
            )
            if kind == "book":
                directories.add(directory / "parts")
                geometry = "\\geometry{a4paper,top=2.5cm,bottom=2.5cm,left=2.5cm,right=2.5cm}\n"
                structure = (
                    "\\frontmatter\n"
                    "\\maketitle\n"
                    "\\input{frontmatter/preface}\n"
                    "\\tableofcontents\n"
                    "\\mainmatter\n"
                    "\\include{parts/part-01}\n"
                    "\\appendix\n"
                    "\\input{backmatter/appendix}\n"
                    "\\backmatter\n"
                    "\\printbibliography\n"
                    "\\printindex\n"
                )
                generated[directory / "parts" / "part-01.tex"] = (
                    "\\part{Part I}\n"
                    "\\input{chapters/chapter-01}\n"
                )
                generated[directory / "frontmatter" / "preface.tex"] = (
                    "\\chapter*{پیشگفتار}\n\\addcontentsline{toc}{chapter}{پیشگفتار}\n"
                    "متن پیشگفتار را اینجا بنویسید.\n"
                    if code == "fa" else
                    "\\chapter*{Preface}\n\\addcontentsline{toc}{chapter}{Preface}\n"
                    "Write the purpose and intended audience of this book here.\n"
                )
                generated[directory / "backmatter" / "appendix.tex"] = (
                    "\\chapter{پیوست}\nمطالب تکمیلی را اینجا قرار دهید.\n"
                    if code == "fa" else
                    "\\chapter{Additional Material}\nPlace supplementary material here.\n"
                )
                language_preamble += "\\usepackage{makeidx}\n\\makeindex\n" + geometry
            else:
                geometry = "\\geometry{a5paper,top=1.5cm,bottom=1.5cm,left=1.7cm,right=1.7cm}\n"
                structure = (
                    "\\frontmatter\n"
                    "\\maketitle\n"
                    "\\input{frontmatter/preface}\n"
                    "\\tableofcontents\n"
                    "\\mainmatter\n"
                    "\\include{chapters/chapter-01}\n"
                    "\\backmatter\n"
                    "\\input{backmatter/notes}\n"
                    "\\printbibliography\n"
                )
                generated[directory / "frontmatter" / "preface.tex"] = (
                    "\\chapter*{پیشگفتار}\nمتن کوتاه پیشگفتار.\n"
                    if code == "fa" else
                    "\\chapter*{Preface}\nA short introduction to this booklet.\n"
                )
                generated[directory / "backmatter" / "notes.tex"] = (
                    "\\chapter*{یادداشت‌ها}\n"
                    if code == "fa" else
                    "\\chapter*{Notes}\n"
                )
                language_preamble += geometry
            language_preamble += "\\usepackage{hyperref}\n"
            if code == "fa":
                language_preamble += "\\usepackage{xepersian}\n\\settextfont{Vazirmatn}\n"
            document_class = (
                "\\documentclass[11pt,oneside,openany]{book}\n"
                if kind == "book" else
                "\\documentclass[10pt,oneside,openany]{book}\n"
            )
            generated[directory / "main.tex"] = (
                document_class + language_preamble +
                "\\title{" + doc_title + "}\n"
                "\\author{" + author + "}\n"
                "\\date{\\today}\n"
                "\\begin{document}\n" + structure + "\\end{document}\n"
            )

        elif kind in {"article", "collection"}:
            directories.add(directory / "sections")
            if article_style == "ieee":
                document_class = "\\documentclass[10pt,a4paper,twocolumn]{article}\n"
            else:
                document_class = "\\documentclass[11pt,a4paper]{article}\n"

            if code == "fa":
                language_preamble = (
                    "\\usepackage{graphicx}\n"
                    "\\usepackage{amsmath,amssymb}\n"
                    "\\usepackage{geometry}\n"
                )
                if article_style != "ieee":
                    language_preamble += "\\usepackage[backend=biber,style=authoryear,sorting=nyt]{biblatex}\n"
                if article_style == "ieee":
                    language_preamble += "\\geometry{a4paper,twocolumn,columnsep=0.5cm,top=2cm,bottom=2cm,left=1.5cm,right=1.5cm}\n"
                    language_preamble += "\\usepackage{cite}\n"
                else:
                    language_preamble += "\\geometry{a4paper,top=2.5cm,bottom=2.5cm,left=2.5cm,right=2.5cm}\n"
                    if article_style == "academic":
                        language_preamble += "\\usepackage{amsthm}\n"
                language_preamble += (
                    "\\usepackage{hyperref}\n"
                    "\\usepackage{xepersian}\n"
                    "\\settextfont{Vazirmatn}\n"
                )
            else:
                language_preamble = f"\\input{{common/presets/article/{article_style}}}\n"

            language_preamble += (
                "\\providecommand{\\keywords}[1]{\\par\\noindent\\textbf{Keywords:} #1}\n"
            )
            if article_style != "ieee":
                language_preamble += "\\addbibresource{references/references.bib}\n"

            abstract = (
                "چکیده را در یک پاراگراف بنویسید: مسئله، روش و نتیجه اصلی.\n"
                if code == "fa" else
                "State the problem, approach, and main finding in one concise paragraph.\n"
            )
            keyword_text = "کلیدواژه اول؛ کلیدواژه دوم؛ کلیدواژه سوم" if code == "fa" else "keyword one; keyword two; keyword three"
            intro_title = "مقدمه" if code == "fa" else "Introduction"
            intro_text = "زمینه، مسئله و سهم این نوشته را معرفی کنید." if code == "fa" else "Introduce the context, problem, and contribution of this paper."
            approach_title = "روش" if code == "fa" else "Approach"
            approach_text = "روش، استدلال یا رویکرد خود را توضیح دهید." if code == "fa" else "Describe the method, argument, or approach."
            conclusion_title = "نتیجه‌گیری" if code == "fa" else "Conclusion"
            conclusion_text = "یافته‌ها و محدودیت‌های اصلی را جمع‌بندی کنید." if code == "fa" else "Summarize the main findings and limitations."
            generated[directory / "sections" / "01-introduction.tex"] = f"\\section{{{intro_title}}}\n{intro_text}\n"
            generated[directory / "sections" / "02-approach.tex"] = f"\\section{{{approach_title}}}\n{approach_text}\n"
            generated[directory / "sections" / "03-conclusion.tex"] = f"\\section{{{conclusion_title}}}\n{conclusion_text}\n"

            if article_style == "ieee":
                bibliography = "\\bibliographystyle{IEEEtran}\n\\bibliography{references/references}\n"
            else:
                bibliography = "\\printbibliography\n"
            generated[directory / "main.tex"] = (
                document_class + language_preamble +
                "\\title{" + doc_title + "}\n"
                "\\author{" + author + "}\n"
                "\\date{\\today}\n"
                "\\begin{document}\n"
                "\\maketitle\n"
                "\\begin{abstract}\n" + abstract + "\\end{abstract}\n"
                "\\keywords{" + keyword_text + "}\n"
                "\\input{sections/01-introduction}\n"
                "\\input{sections/02-approach}\n"
                "\\input{sections/03-conclusion}\n"
                + bibliography + "\\end{document}\n"
            )

        else:
            directories.add(directory / "sections")
            section_name = "معرفی" if code == "fa" else "Profile"
            sample = "اطلاعات خود را اینجا اضافه کنید." if code == "fa" else "Add your profile details here."
            generated[directory / "sections" / "01-profile.tex"] = f"\\section{{{section_name}}}\n{sample}\n"
            language_preamble = (
                "\\usepackage{graphicx}\n\\usepackage{hyperref}\n"
                if code == "en" else
                "\\usepackage{graphicx}\n\\usepackage{hyperref}\n\\usepackage{xepersian}\n\\settextfont{Vazirmatn}\n"
            )
            generated[directory / "main.tex"] = (
                "\\documentclass[11pt]{article}\n" + language_preamble +
                "\\title{" + doc_title + "}\n"
                "\\author{" + author + "}\n"
                "\\begin{document}\n\\maketitle\n"
                "\\input{sections/01-profile}\n\\end{document}\n"
            )

        main_path = directory / "main.tex"
        entries[code] = {
            "source": str(main_path.relative_to(root)).replace("\\", "/"),
            "engine": "xelatex" if code == "fa" else "pdflatex",
        }

    generated[root / "references" / "references.bib"] = ""
    for path in generated:
        if path.exists() and not force and path.name != "references.bib":
            raise FileExistsError(f"refusing to overwrite {path}")
    for directory in directories:
        directory.mkdir(parents=True, exist_ok=True)
    for path, content in generated.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.name == "references.bib" and path.exists():
            continue
        path.write_text(content, encoding="utf-8")

    project_name = root.name.lower().replace(" ", "-")
    if kind == "collection":
        cfg = {
            "schema_version": 2,
            "project": {
                "name": project_name,
                "type": "collection",
                "title": title,
                "author": "Your Name",
                "languages": languages,
            },
            "build": {
                "output_dir": "build",
                "default_engine": "xelatex",
                "timeout_seconds": 1800,
            },
            "documents": {
                "first-article": {
                    "type": "article",
                    "title": title,
                    "style": article_style,
                    "editions": entries,
                }
            },
            "export": {
                "output_dir": "build/export",
                "targets": ["devto"],
                "tag_limit": 5,
            },
        }
    else:
        cfg = {
            "schema_version": 1,
            "project": {
                "name": project_name,
                "type": kind,
                "title": title,
                "author": "Your Name",
                "languages": languages,
            },
            "build": {
                "output_dir": "build",
                "default_engine": "xelatex",
                "timeout_seconds": 1800,
                "entries": entries,
            },
            "export": {
                "output_dir": "build/export",
                "targets": ["devto"],
                "tag_limit": 5,
            },
        }
        if kind == "article":
            cfg["project"]["style"] = article_style

    config_path.write_text(yaml.safe_dump(cfg, allow_unicode=True, sort_keys=False), encoding="utf-8")
    makefile = root / "Makefile"
    if not makefile.exists():
        makefile.write_text(
            "PX ?= px\n.PHONY: build build-en build-fa clean export tags changelog\n"
            "build:\n\t$(PX) build\n"
            "build-en:\n\t$(PX) build --language en\n"
            "build-fa:\n\t$(PX) build --language fa\n"
            "clean:\n\t$(PX) clean\n"
            "export:\n\t$(PX) export\n"
            "tags:\n\t$(PX) tags\n"
            "changelog:\n\t$(PX) changelog\n",
            encoding="utf-8",
        )
    return config_path

def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    root = Path(args.root).expanduser().resolve()
    try:
        if args.command == "init":
            path = _init(root, args.type, args.language, args.force, args.style)
            log("info", f"Created {path}", component="init", status="ok")
            return 0
        if args.command == "log":
            log(args.level, " ".join(args.message), component=args.component)
            return 0
        if args.command == "verify-pdf":
            from .build import valid_pdf
            path = Path(args.path).expanduser()
            if not valid_pdf(path):
                log("error", f"invalid or incomplete PDF: {path}", component="verify")
                return 1
            log("info", f"validated PDF: {path}", component="verify", status="ok")
            return 0
        if args.command == "doctor":
            checks = {
                "latexmk": shutil.which("latexmk"),
                "pandoc": shutil.which("pandoc"),
                "gix": shutil.which("gix"),
                "psx": shutil.which("psx"),
                "m-mdy-m/log.c": "native" if native_logger_available() else None,
            }
            for name, value in checks.items():
                log("info" if value else "warn", f"{name}: {value or 'not available'}", component="doctor")
            return 0 if checks["latexmk"] and checks["m-mdy-m/log.c"] else 1

        config = load_config(root, args.config)
        if args.command == "build":
            selected_edition = args.edition
            if args.language:
                if selected_edition:
                    raise ValueError("use either --edition or --language, not both")
                selected_edition = args.language[0] if len(args.language) == 1 else args.language
            build_documents(root, config, args.document_id, selected_edition,
                            dry_run=args.dry_run, keep_going=args.keep_going)
            return 0
        if args.command == "list":
            import json
            rows = list_documents(root, config)
            if args.json:
                print(json.dumps(rows, ensure_ascii=False, sort_keys=True, indent=2))
            else:
                for row in rows:
                    print(f"{row['document_id']:<18} {row['edition']:<10} {row['status']:<12} {row['source']}")
            return 0
        if args.command == "verify":
            result = verify_manifest(root, config)
            log("info", f"Verified {result['checked']} PDF artifact(s) from {result['manifest']}",
                component="verify", status="ok")
            return 0
        if args.command == "clean":
            if args.edition and not args.document_id:
                raise ValueError("--edition requires a document id")
            if args.document_id:
                clean_document(root, config, args.document_id, args.edition)
            else:
                clean_project(root, config)
            return 0
        if args.command == "export":
            outputs = export_project(root, config, args.target)
            for path in outputs:
                log("info", f"Created {path.relative_to(root)}", component="export", status="ok")
            return 0
        if args.command == "tags":
            project = config["project"]
            values = list(project.get("tags", [])) + list(project.get("keywords", []))
            for value in generate_tags(values, config["export"]["tag_limit"]):
                print(value)
            return 0
        if args.command == "changelog":
            print(generate_changelog(root, args.output, args.version, args.dry_run), end="")
            return 0
        if args.command == "tag":
            if run_checked(["git", "status", "--porcelain"], cwd=root).stdout.strip():
                raise ValueError("refusing to tag a dirty working tree; commit or stash changes first")
            flag = "-s" if args.sign else "-a"
            run_checked(["git", "tag", flag, args.name, "-m", f"Release {args.name}"], cwd=root)
            log("info", f"Created tag {args.name}", component="release", status="ok")
            return 0
        if args.command == "push":
            run_checked(["git", "push", "origin", "HEAD"], cwd=root)
            if args.tags:
                run_checked(["git", "push", "origin", "--tags"], cwd=root)
            return 0
        if args.command == "watch":
            def snapshot() -> dict[Path, int]:
                result = {}
                if config["schema_version"] == 2:
                    from .project import _documents
                    entries = (edition for doc in _documents(config).values()
                               for edition in doc["editions"].values())
                    sources = (root / entry["source"] for entry in entries)
                else:
                    sources = (root / (raw if isinstance(raw, str) else raw["source"])
                               for raw in config["build"]["entries"].values())
                for source in sources:
                    if source.exists():
                        result[source] = source.stat().st_mtime_ns
                return result
            build_documents(root, config, keep_going=True)
            previous = snapshot()
            log("info", "Watching configured LaTeX sources; press Ctrl+C to stop", component="watch")
            while True:
                time.sleep(max(0.2, args.interval))
                current = snapshot()
                if current != previous:
                    build_documents(root, config, keep_going=True)
                    previous = snapshot()
        return 0
    except (ConfigError, BuildError, ExportError, CommandError, OSError, ValueError) as exc:
        log("error", str(exc), component="cli", status="failed")
        return getattr(exc, "code", 1) or 1
    finally:
        close_all()


if __name__ == "__main__":
    raise SystemExit(main())
