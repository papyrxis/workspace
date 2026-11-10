FROM debian:bookworm-slim AS log-build

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential ca-certificates cmake git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch v0.1.0 https://github.com/m-mdy-m/log.c.git /tmp/log.c \
    && cmake -S /tmp/log.c -B /tmp/log.c/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/mmlog \
      -DBUILD_SHARED_LIBS=ON \
      -DM_MDY_M_LOG_BUILD_TESTS=OFF \
      -DM_MDY_M_LOG_BUILD_EXAMPLES=OFF \
    && cmake --build /tmp/log.c/build --parallel \
    && cmake --install /tmp/log.c/build

FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    M_MDY_M_LOG_LIBRARY=/opt/mmlog/lib/libm-mdy-m-log.so.0.1.0 \
    LD_LIBRARY_PATH=/opt/mmlog/lib

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      latexmk \
      texlive-latex-base \
      texlive-latex-recommended \
      texlive-latex-extra \
      texlive-xetex \
      texlive-lang-arabic \
      fonts-lmodern \
      fonts-dejavu-core \
      fonts-hosny-amiri \
      pandoc \
      make \
      git \
    && rm -rf /var/lib/apt/lists/*

COPY --from=log-build /opt/mmlog/lib/ /opt/mmlog/lib/
WORKDIR /opt/workspace
COPY pyproject.toml README.md ./
COPY px ./px
COPY common ./common
COPY examples ./examples
RUN python -m pip install --no-cache-dir .

RUN useradd --create-home --uid 10001 px \
    && mkdir -p /workspace \
    && chown -R px:px /workspace
WORKDIR /workspace
USER px

LABEL org.opencontainers.image.title="Papyrxis Workspace" \
      org.opencontainers.image.description="Reusable multi-document publishing toolchain" \
      org.opencontainers.image.source="https://github.com/papyrxis/workspace"

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["px", "--help"]

ENTRYPOINT ["px"]
CMD ["--help"]
