# RaceRoom dedicated server in Docker

Runs the Windows-only RaceRoom dedicated server (Steam app 354060) under Wine.
The server files are downloaded by steamcmd on every start into `/data`, which
also holds the Wine prefix and with it the server's configuration.

```sh
docker build -t raceroom-server .
docker run -d --name raceroom \
    -v raceroom-data:/data \
    -p 127.0.0.1:8088:8080 \
    -p 60000-60002:60000-60002/udp -p 60000-60002:60000-60002/tcp \
    raceroom-server
```

The first start installs .NET Framework 4.8 into the Wine prefix, which takes
a few minutes and brings the volume to about 3GB. Later starts take seconds.

The web UI is then at http://localhost:8088. It has no authentication, so do
not publish it on a public interface.

Each game server uses a UDP port, a UDP time port and TCP port + 1, starting
at 60000 by default. The range above covers the first one.

A bind mount used for `/data` must be writable by uid 1000.
