# RaceRoom dedicated server in Docker

Runs the Windows-only RaceRoom dedicated server (Steam app 354060) under Wine.
The server files are downloaded by steamcmd on every start into `/data`, which
also holds the Wine prefix and with it the server's configuration.

```sh
docker build -t raceroom-server .
docker run -d --name raceroom \
    -v raceroom-data:/data \
    -p 127.0.0.1:8088:8080 \
    -p 27015-27017:27015-27017/udp -p 27015-27017:27015-27017/tcp \
    raceroom-server
```

The web UI is then at http://localhost:8088. It has no authentication, so do
not publish it on a public interface.

Each game server created in the UI uses a UDP port, a UDP time port and TCP
port + 1. Publish whichever ports you set there, the range above is an example.

A bind mount used for `/data` must be writable by uid 1000.
