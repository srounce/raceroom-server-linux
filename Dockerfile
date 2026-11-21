FROM debian:trixie-slim

ARG WINE_URL=https://github.com/srounce/wine/releases/download/sangria-11.18/wine-sangria-11.18-amd64.tar.xz
ARG WINE_SHA256=fa4d4a604f4128575eb8f13f41284554cebcb4176ec92c60fe9bfb8aa0176bca
ARG WINETRICKS_VERSION=20260125

# The Wine build is WoW64, so it runs the 32-bit server without i386 host
# libraries. lib32gcc-s1 is for steamcmd, which is a 32-bit ELF. Without
# libfontconfig1 Wine cannot create its desktop and spawns explorer.exe in
# an endless loop.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl xz-utils cabextract haproxy xvfb libx11-6 libxext6 \
      lib32gcc-s1 libfontconfig1 libfreetype6 libgnutls30t64 \
 && mkdir -p /opt/wine /opt/steamcmd \
 && curl -fsSL -o /tmp/wine.tar.xz "$WINE_URL" \
 && echo "$WINE_SHA256  /tmp/wine.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/wine.tar.xz -C /opt/wine --strip-components=1 --exclude='*/include' \
 && rm /tmp/wine.tar.xz \
 && curl -fsSL -o /usr/local/bin/winetricks \
      https://raw.githubusercontent.com/Winetricks/winetricks/${WINETRICKS_VERSION}/src/winetricks \
 && chmod +x /usr/local/bin/winetricks \
 && curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
      | tar -xz -C /opt/steamcmd \
 && useradd --uid 1000 --home-dir /data --no-create-home raceroom \
 && mkdir /data \
 && chown raceroom: /data /opt/steamcmd -R \
 && rm -rf /var/lib/apt/lists/*

COPY docker/haproxy.cfg /etc/raceroom-haproxy.cfg
COPY --chmod=755 docker/entrypoint.sh /entrypoint.sh

USER raceroom
# HOME is the volume so the server files, steamcmd cache and Wine prefix
# (which holds the server's config under AppData) all persist together.
ENV HOME=/data \
    PATH=/opt/wine/bin:$PATH \
    WINEDEBUG=-all \
    WINEDLLOVERRIDES=winemenubuilder.exe=d
VOLUME /data
WORKDIR /data
EXPOSE 8080/tcp

ENTRYPOINT ["/entrypoint.sh"]
