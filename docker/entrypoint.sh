#!/bin/sh
set -eu

# app_info_print forces steamcmd to fetch the app metadata before app_update,
# which otherwise fails with "Missing configuration" on a fresh install.
/opt/steamcmd/steamcmd.sh \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir /data/server \
    +login anonymous \
    +app_info_update 1 \
    +app_info_print 354060 \
    +app_update 354060 \
    +quit >/dev/null

haproxy -D -f /etc/raceroom-haproxy.cfg

# Wine ignores SIGTERM as PID 1, so shut it down through wineserver instead.
trap 'wineserver -k' TERM INT
cd /data/server
wine RRRE_Dedicated.exe "$@" &
wait $!
