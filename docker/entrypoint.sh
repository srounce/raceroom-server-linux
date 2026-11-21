#!/bin/sh
set -eu

# Runs a setup step quietly, showing its output only if it fails.
quiet() {
    if ! "$@" >/tmp/setup.log 2>&1; then
        cat /tmp/setup.log >&2
        exit 1
    fi
}

# app_info_print forces steamcmd to fetch the app metadata before app_update,
# which otherwise fails with "Missing configuration" on a fresh install.
quiet /opt/steamcmd/steamcmd.sh \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir /data/server \
    +login anonymous \
    +app_info_update 1 \
    +app_info_print 354060 \
    +app_update 354060 \
    +quit

# The server's registration code fails on wine-mono with "Invalid IL code",
# so the prefix gets Microsoft's .NET Framework instead. This has to run
# before a display exists: with one, creating the prefix blocks on Wine's
# dialog offering to download wine-mono.
if ! grep -qx dotnet48 /data/.wine/winetricks.log 2>/dev/null; then
    echo "Installing .NET Framework 4.8 into the Wine prefix, this takes a few minutes"
    quiet winetricks -q dotnet48
    wineserver -w
fi

# DedicatedServer.exe, which the manager spawns per game server, aborts on
# start when it cannot create a window. The lock file is left behind when
# the container is restarted.
rm -f /tmp/.X99-lock
Xvfb :99 -screen 0 640x480x24 -nolisten tcp >/dev/null 2>&1 &
export DISPLAY=:99

haproxy -D -f /etc/raceroom-haproxy.cfg

# Wine ignores SIGTERM as PID 1, so shut it down through wineserver instead.
trap 'wineserver -k' TERM INT
cd /data/server
# .NET's Console.ReadKey throws when there is no console, so the server
# runs on a pty.
script -qfc 'wine RRRE_Dedicated.exe' /dev/null &
wait $!
