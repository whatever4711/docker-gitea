ARG IMAGE_TARGET=alpine

# first image to download qemu and gitea make them executable
FROM alpine AS qemu
ARG QEMU=x86_64
ARG GITEA_ARCH=amd64
ARG VERSION=1.3.3
ADD https://github.com/multiarch/qemu-user-static/releases/download/v2.11.0/qemu-${QEMU}-static /qemu-${QEMU}-static
ADD https://github.com/go-gitea/gitea/releases/download/v${VERSION}/gitea-${VERSION}-linux-${GITEA_ARCH} /gitea
RUN chmod +x /qemu-${QEMU}-static /gitea

# second image to be deployed on dockerhub
FROM ${IMAGE_TARGET}
ARG QEMU=x86_64
COPY --from=qemu /qemu-${QEMU}-static /usr/bin/qemu-${QEMU}-static
ARG ARCH=amd64
ARG VERSION=1.3.3
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL

RUN apk --no-cache --no-progress add \
    su-exec \
    ca-certificates \
    sqlite \
    bash \
    git \
    linux-pam \
    s6 \
    curl \
    openssh \
    gettext \
    tzdata
RUN addgroup \
    -S -g 1000 \
    git && \
  adduser \
    -S -H -D \
    -h /data/git \
    -s /bin/bash \
    -u 1000 \
    -G git \
    git && \
  echo "git:$(dd if=/dev/urandom bs=24 count=1 status=none | base64)" | chpasswd

ENV USER git
ENV GITEA_CUSTOM /data/gitea
ENV GODEBUG=netdns=go

COPY gitea/docker /
COPY --from=qemu /gitea /app/gitea/gitea

VOLUME ["/data"]
EXPOSE 3000 22
ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/bin/s6-svscan", "/etc/s6"]

LABEL de.whatever4711.gitea.version=$VERSION \
    de.whatever4711.gitea.name="Gitea" \
    de.whatever4711.gitea.docker.cmd="docker run -d -p 3000:3000 -p 2222:22 whatever4711/gitea" \
    de.whatever4711.gitea.vendor="Marcel Grossmann" \
    de.whatever4711.gitea.architecture=$ARCH \
    de.whatever4711.gitea.vcs-ref=$VCS_REF \
    de.whatever4711.gitea.vcs-url=$VCS_URL \
    de.whatever4711.gitea.build-date=$BUILD_DATE
