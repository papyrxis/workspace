FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      latexmk \
      texlive-latex-base \
      texlive-latex-recommended \
      texlive-latex-extra \
      texlive-xetex \
      texlive-lang-arabic \
      fonts-lmodern \
      fonts-dejavu-core \
      pandoc \
      make \
      git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/workspace
COPY pyproject.toml README.md ./
COPY px ./px
COPY common ./common
RUN python -m pip install --no-cache-dir .

RUN useradd --create-home --uid 10001 px     && mkdir -p /workspace     && chown -R px:px /workspace
WORKDIR /workspace
USER px

LABEL org.opencontainers.image.title="Papyrxis Workspace" \
      org.opencontainers.image.description="Reusable multi-document publishing toolchain" \
      org.opencontainers.image.source="https://github.com/papyrxis/workspace"

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["px", "--help"]

ENTRYPOINT ["px"]
CMD ["--help"]
