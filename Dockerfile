FROM python:3.12

ARG USE_UV=""

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    coreutils findutils grep sed gawk diffutils patch \
    less file tree bc man-db \
    # Networking
    curl wget net-tools iputils-ping dnsutils netcat-openbsd socat telnet \
    openssh-client rsync \
    # Editors
    vim nano \
    # Version control
    git \
    # Build tools
    build-essential cmake make \
    # Scripting & languages
    perl ruby-full lua5.4 \
    # Data processing
    jq xmlstarlet sqlite3 \
    # Media & documents
    ffmpeg pandoc imagemagick texlive-latex-base \
    # Compression
    zip unzip tar gzip bzip2 xz-utils zstd p7zip-full \
    # System
    procps htop lsof strace sysstat \
    sudo tmux screen \
    ca-certificates gnupg apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Node.js (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Docker CLI + Compose + Buildx (mount socket at runtime for access)
RUN curl -fsSL https://get.docker.com | sh

WORKDIR /app

RUN if [ "$USE_UV" = "true" ]; then
        pip install --no-cache-dir uv;
    fi

ENV PKGM=${USE_UV:+uv pip}
ENV PKGM=${PKGM:-pip}
ENV UV_SYSTEM_PYTHON=${USE_UV:+1}

# Cached separately, re-runs if core-requirements.txt changes
COPY core-requirements.txt .
RUN $PKGM install --no-cache-dir -r core-requirements.txt

COPY . .
RUN $PKGM install --no-cache-dir .

RUN useradd -m -s /bin/bash user && echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER user
ENV SHELL=/bin/bash
ENV PATH="/home/user/.local/bin:${PATH}"
WORKDIR /home/user

EXPOSE 8000

COPY entrypoint.sh /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
