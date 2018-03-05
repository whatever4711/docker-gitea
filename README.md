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
networks:
  backend:
    driver: bridge
  frontend:
    driver: bridge

volumes:
  git:
  db:

services:
  postgres:
    image: postgres:alpine
    networks:
      - backend
    volumes:
      - db:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=gitea
      - POSTGRES_PASSWORD=test
      - POSTGRES_DB=gitea
    labels:
      - traefik.enable=false

  gogs:
    image: whatever4711/gitea
    depends_on:
      - postgres
    volumes:
      - git:/data
    ports:
      - 22:22
    networks:
      - frontend
      - backend
    labels:
      - traefik.backend=gitea
      - traefik.port=3000
      - traefik.frontend.rule=Host:gitea.localdomain
      - traefik.docker.network=dockergogs_frontend

  traefik:
    image: traefik
    command: --docker --docker.domain=localdomain --docker.watch --web
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - 80:80
      - 443:443
    networks:
      - frontend
    labels:
      - traefik.backend=traefik
      - traefik.port=8080
      - traefik.frontend.rule=Host:traefik.localdomain
      - traefik.docker.network=dockergogs_frontend
```
