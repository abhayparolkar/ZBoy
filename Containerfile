# Pi Coding Agent inside an Apple container.
#
# Minimal Node image; pi installed globally, tools for the
# bash tool-call (find, grep, rg) available, /workspace as the
# mount target for the respective project.

FROM node:22-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git \
      ripgrep \
      ca-certificates \
      iproute2 \
      chromium \
      ffmpeg \
      build-essential \
      autoconf \
      bison \
      patch \
      libssl-dev \
      libyaml-dev \
      libreadline-dev \
      zlib1g-dev \
      libffi-dev \
      libgdbm-dev \
      libncurses-dev \
      libsqlite3-dev \
      sqlite3 \
      curl \
 && rm -rf /var/lib/apt/lists/*

# Install latest stable Ruby via ruby-build to /usr/local
RUN git clone --depth 1 https://github.com/rbenv/ruby-build.git /tmp/ruby-build \
 && /tmp/ruby-build/install.sh \
 && RUBY_VERSION=$(ruby-build --definitions | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1) \
 && ruby-build "$RUBY_VERSION" /usr/local \
 && rm -rf /tmp/ruby-build

# Install latest Rails
RUN gem install rails

RUN npm install -g @earendil-works/pi-coding-agent

# Browser agent: agent-browser CLI + system Chromium (no Chrome-for-Testing on ARM64)
RUN npm install -g agent-browser

# Ruby LSP: enables pi-agent to be Ruby-aware
RUN npm install -g @wiechsa/pi-ruby-lsp

ENV AGENT_BROWSER_EXECUTABLE_PATH=/usr/bin/chromium

ARG PI_UID=1000
ARG PI_GID=1000
# node:22 already ships a 'node' user/group at UID/GID 1000; remove it so the
# 'pi' user can own that id range, then create pi.
RUN userdel --remove node 2>/dev/null || true \
 && groupdel node 2>/dev/null || true \
 && groupadd --gid ${PI_GID} pi \
 && useradd --uid ${PI_UID} --gid ${PI_GID} --create-home --shell /bin/bash pi

USER pi
WORKDIR /workspace

# pi reads ~/.pi/agent/* at runtime; the directory is mounted via a volume.
ENTRYPOINT ["pi"]
