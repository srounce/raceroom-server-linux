FROM debian:trixie-slim

# Must match the Wine version installed below, see
# https://gitlab.winehq.org/wine/wine/-/wikis/Wine-Mono#versions
ARG WINE_MONO_VERSION=10.4.1

# RRRE_Dedicated.exe is a 32-bit .NET assembly and steamcmd is a 32-bit ELF,
# hence the i386 architecture. Wine comes from WineHQ because Debian's
# package lags a major version behind.
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl haproxy \
 && curl -fsSL -o /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
 && curl -fsSL -o /etc/apt/sources.list.d/winehq.sources \
      https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources \
 && apt-get update \
 && apt-get install -y --no-install-recommends winehq-stable \
 && mkdir -p /opt/wine-stable/share/wine/mono /opt/steamcmd \
 && curl -fsSL -o /opt/wine-stable/share/wine/mono/wine-mono-${WINE_MONO_VERSION}-x86.msi \
      https://dl.winehq.org/wine/wine-mono/${WINE_MONO_VERSION}/wine-mono-${WINE_MONO_VERSION}-x86.msi \
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
# (which holds the server's config under Documents) all persist together.
ENV HOME=/data \
    WINEDEBUG=-all \
    WINEDLLOVERRIDES=winemenubuilder.exe=d
VOLUME /data
WORKDIR /data
EXPOSE 8080/tcp

ENTRYPOINT ["/entrypoint.sh"]
