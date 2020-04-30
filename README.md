[![CircleCI](https://circleci.com/gh/whatever4711/docker-gitea.svg?style=svg)](https://circleci.com/gh/whatever4711/docker-gitea)

[![](https://images.microbadger.com/badges/version/whatever4711/gitea.svg)](https://microbadger.com/images/whatever4711/gitea "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/whatever4711/gitea.svg)](https://microbadger.com/images/whatever4711/gitea "Get your own image badge on microbadger.com")

# Gitea in a Container

Currently, this is a docker image based on Alpine Linux, which has [Gitea](https://gitea.io/) installed.

## Supported Architectures
This multiarch image supports `amd64`, `i386`, `arm32v6`, and `arm64v8` on Linux

## Starting the Container
`docker run -d --name gitea -p 3000:3000 -p 22:22 whatever4711/gitea`
Thereafter you can access gitea on http://localhost:3000

## With DB and Traefik (Multiarch)

Install `docker-compose` and run `docker-compose up -d`

```[docker-compose.yml]
version: '3'

volumes:
  git:
  db:

services:
  postgres:
    image: postgres:alpine
    volumes:
      - db:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=${DB_USER:-gitea}
      - POSTGRES_PASSWORD=${DB_PASSWD:-test}
      - POSTGRES_DB=${DB_NAME:-gitea}
    labels:
      - traefik.enable=false

  gitea:
    image: whatever4711/gitea
    environment:
      - SSH_DOMAIN=gitea.localdomain
      - SSH_PORT=2222
      - SSH_LISTEN_PORT=22
      - DB_TYPE=postgres
      - DB_HOST=postgres
      - DB_NAME=${DB_NAME:-gitea}
      - DB_USER=${DB_USER:-gitea}
      - DB_PASSWD=${DB_PASSWD:-test}
    depends_on:
      - postgres
    volumes:
      - git:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.gitea-web.rule=Host(`gitea.localdomain`)"
      - "traefik.http.routers.gitea-web.entrypoints=web"
      - "traefik.http.routers.gitea-web.service=gitea-web-svc"
      - "traefik.http.services.gitea-web-svc.loadbalancer.server.port=3000"
      - "traefik.tcp.routers.gitea-ssh.rule=HostSNI(`*`)"
      - "traefik.tcp.routers.gitea-ssh.entrypoints=ssh"
      - "traefik.tcp.routers.gitea-ssh.service=gitea-ssh-svc"
      - "traefik.tcp.services.gitea-ssh-svc.loadbalancer.server.port=22"

  traefik:
    image: traefik
    command:
      #- "--log.level=DEBUG"
      - "--api=true"
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.ssh.address=:2222"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "80:80"
      - "2222:2222"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik-http.entrypoints=web"
      - "traefik.http.routers.traefik-http.rule=Host(`traefik.localdomain`)"
      - "traefik.http.routers.traefik-http.service=api@internal"
```
