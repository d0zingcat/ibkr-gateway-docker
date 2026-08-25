# syntax=docker/dockerfile:1
FROM debian:bookworm-slim AS installer

ARG IBC_VERSION=3.18.0
ARG IBC_SHA256=a59f5be6f9e2e6044733eb7b2fef450ddb4f74d08ce1e51b14a2a11b6d92374b

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN curl -fsSL "https://github.com/IbcAlpha/IBC/releases/download/${IBC_VERSION}/IBCLinux-${IBC_VERSION}.zip" -o ibc.zip \
  && echo "${IBC_SHA256}  ibc.zip" | sha256sum -c - \
  && mkdir -p /opt/ibc \
  && unzip -q ibc.zip -d /opt/ibc \
  && chmod -R 755 /opt/ibc

# Runtime image
FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    procps \
    socat \
    xvfb \
    libxtst6 \
    libxrender1 \
    libxi6 \
    default-jre-headless \
  && rm -rf /var/lib/apt/lists/*

RUN useradd --system --uid 10001 --create-home gateway

COPY --from=installer --chown=10001:10001 /opt/ibc /opt/ibc
COPY --chown=10001:10001 scripts /opt/gateway/scripts

RUN chmod +x /opt/gateway/scripts/*.sh /opt/ibc/*.sh

USER 10001:10001
WORKDIR /home/gateway

ENV DISPLAY=:1 \
    IBC_PATH=/opt/ibc \
    TWS_PATH=/opt/gateway \
    TWS_API_PORT=4001 \
    TRADING_MODE=live \
    READ_ONLY_API=yes

EXPOSE 4001 4002

ENTRYPOINT ["/opt/gateway/scripts/entrypoint.sh"]
