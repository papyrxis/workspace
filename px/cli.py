"""Command-line interface for the Papyrxis Workspace publishing engine."""
from __future__ import annotations

import argparse
import shutil
import time
from pathlib import Path

from .build import BuildError, build_project, clean_project
from .changelog import generate_changelog
from .config import ConfigError, load_config
from .export import ExportError, export_project
from .logger import get_logger, log, native_logger_available
from .process import CommandError, run_checked
from .tags import generate_tags


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="px", description="Build and publish LaTeX documents")
    parser.add_argument("--root", default=".", help="project directory")
    parser.add_argument("--config", default="workspace.yml", help="project YAML configuration")
    commands = parser.add_subparsers(dest="command", required=True)

    init = commands.add_parser("init", help="create a project configuration and a basic source")
    init.add_argument("--type", default="book", choices=("book", "booklet", "article", "cv"))
    init.add_argument("--language", default="en", choices=("en", "fa", "both"))
    init.add_argument("--force", action="store_true")

    build = commands.add_parser("build", help="build configured language editions")
    build.add_argument("--language", action="append", default=[])
    build.add_argument("--dry-run", action="store_true")

    commands.add_parser("clean", help="remove only the configured generated output")
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

    commands.add_parser("doctor", help="check publishing tools and the native logger")
    return parser


def _init(root: Path, kind: str, language: str, force: bool) -> Path:
    import yaml

    root.mkdir(parents=True, exist_ok=True)
    config_path = root / "workspace.yml"
    if config_path.exists() and not force:
        raise FileExistsError(f"{config_path} already exists; pass --force to replace it")
    languages = ["en", "fa"] if language == "both" else [language]
    entries = {}
    for code in languages:
        if code not in {"en", "fa"}:
            raise ValueError("language must be en, fa or both")
        directory = root if len(languages) == 1 else root / code
        directory.mkdir(parents=True, exist_ok=True)
        source = directory / "main.tex"
        if source.exists() and not force:
            raise FileExistsError(f"refusing to overwrite {source}")
        if code == "fa":
            if kind in {"book", "booklet"}:
                text = "\\documentclass[11pt,oneside]{book}\n\\usepackage{xepersian}\n\\settextfont{Vazirmatn}\n\\begin{document}\n\\frontmatter\n\\title{عنوان نمونه}\\author{نام نویسنده}\\maketitle\\tableofcontents\n\\mainmatter\n\\chapter{مقدمه}\nمتن نمونه برای شروع نگارش.\n\\end{document}\n"
            else:
                text = "\\documentclass{article}\n\\usepackage{xepersian}\n\\settextfont{Vazirmatn}\n\\begin{document}\n\\section{مقدمه}\nمتن نمونه برای شروع نگارش.\n\\end{document}\n"
        else:
            if kind in {"book", "booklet"}:
                text = "\\documentclass[11pt,oneside]{book}\n\\usepackage[T1]{fontenc}\n\\usepackage{lmodern}\n\\begin{document}\n\\frontmatter\n\\title{A Sample Title}\\author{Your Name}\\maketitle\\tableofcontents\n\\mainmatter\n\\chapter{Introduction}\nA clean starting point for your book.\n\\end{document}\n"
            else:
                text = "\\documentclass[11pt]{article}\n\\usepackage[T1]{fontenc}\n\\usepackage{lmodern}\n\\begin{document}\n\\section{Introduction}\nA clean starting point for your document.\n\\end{document}\n"
        source.write_text(text, encoding="utf-8")
        entries[code] = {
            "source": str(source.relative_to(root)).replace("\\", "/"),
            "engine": "xelatex" if code == "fa" else "pdflatex",
        }
    for folder in ("figures", "references", "frontmatter", "backmatter"):
        (root / folder).mkdir(exist_ok=True)
    (root / "references" / "references.bib").touch(exist_ok=True)
    cfg = {
        "schema_version": 1,
        "project": {
            "name": root.name.lower().replace(" ", "-"),
            "type": kind,
            "title": root.name,
            "author": "Your Name",
            "languages": languages,
        },
        "build": {
            "output_dir": "build",
            "default_engine": "xelatex",
            "entries": entries,
        },
        "export": {
            "output_dir": "build/export",
            "targets": ["devto"],
            "tag_limit": 5,
        },
    }
    config_path.write_text(yaml.safe_dump(cfg, allow_unicode=True, sort_keys=False), encoding="utf-8")
    makefile = root / "Makefile"
    if not makefile.exists():
        makefile.write_text(
            "PYTHON ?= python3\n.PHONY: build clean export tags changelog\n"
            "build:\n\t$(PYTHON) -m px build\n"
            "clean:\n\t$(PYTHON) -m px clean\n"
            "export:\n\t$(PYTHON) -m px export\n"
            "tags:\n\t$(PYTHON) -m px tags\n"
            "changelog:\n\t$(PYTHON) -m px changelog\n",
            encoding="utf-8",
        )
    return config_path


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    root = Path(args.root).expanduser().resolve()
    try:
        if args.command == "init":
            path = _init(root, args.type, args.language, args.force)
            log("info", f"Created {path}", component="init", status="ok")
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
            build_project(root, config, args.language, dry_run=args.dry_run)
            return 0
        if args.command == "clean":
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
                for raw in config["build"]["entries"].values():
                    source = root / (raw if isinstance(raw, str) else raw["source"])
                    if source.exists():
                        result[source] = source.stat().st_mtime_ns
                return result
            build_project(root, config)
            previous = snapshot()
            log("info", "Watching configured LaTeX sources; press Ctrl+C to stop", component="watch")
            while True:
                time.sleep(max(0.2, args.interval))
                current = snapshot()
                if current != previous:
                    build_project(root, config)
                    previous = snapshot()
        return 0
    except (ConfigError, BuildError, ExportError, CommandError, OSError, ValueError) as exc:
        log("error", str(exc), component="cli", status="failed")
        return getattr(exc, "code", 1) or 1
    finally:
        get_logger().close()


if __name__ == "__main__":
    raise SystemExit(main())
