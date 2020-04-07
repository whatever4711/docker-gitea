FROM golang:alpine as build

ENV GOOS=linux
ENV CGO_ENABLED=1
ARG VERSION=master
ARG TAGS="sqlite"
ENV TAGS "bindata $TAGS"

WORKDIR ${GOPATH}/src/code.gitea.io
RUN apk add -U --no-cache build-base git nodejs npm && \
    git clone --branch ${VERSION} --depth 1 https://github.com/go-gitea/gitea.git
WORKDIR ${GOPATH}/src/code.gitea.io/gitea

RUN export PATH=$PATH:/go/bin/ && \
    make clean && \
    echo "replace github.com/go-macaron/cors v0.0.0-20190309005821-6fd6a9bfe14e9 => github.com/go-macaron/cors v0.0.0-20190418220122-6fd6a9bfe14e" >> go.mod && \
    echo "replace github.com/census-instrumentation/opencensus-proto v0.1.0-0.20181214143942-ba49f56771b8 => github.com/census-instrumentation/opencensus-proto v0.0.3-0.20181214143942-ba49f56771b8" >> go.mod && \
    GO111MODULE=on go mod vendor && \
    make generate build



# second image to be deployed on dockerhub
FROM alpine
ARG TARGETPLATFORM
ARG VERSION=master
ARG GITEA_ARCH=amd64
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL

COPY --from=build /go/src/code.gitea.io/gitea/gitea /app/gitea/gitea
COPY --from=build /go/src/code.gitea.io/gitea/docker/root /

RUN ln -s /app/gitea/gitea /usr/local/bin/gitea && \
    apk -U --no-cache --no-progress add \
    su-exec ca-certificates sqlite bash git linux-pam s6 curl openssh \
    gettext tzdata && \
    addgroup -S -g 1000 git && \
    adduser -S -H -D -h /data/git -s /bin/bash -u 1000 -G git git && \
    echo "git:$(dd if=/dev/urandom bs=24 count=1 status=none | base64)" | chpasswd

ENV USER git
ENV GITEA_CUSTOM /data/gitea
ENV GODEBUG=netdns=go

VOLUME ["/data"]
EXPOSE 3000 22
ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/bin/s6-svscan", "/etc/s6"]

LABEL de.whatever4711.gitea.version=$VERSION \
    de.whatever4711.gitea.name="Gitea" \
    de.whatever4711.gitea.docker.cmd="docker run -d -p 3000:3000 -p 2222:22 whatever4711/gitea" \
    de.whatever4711.gitea.vendor="Marcel Grossmann" \
    de.whatever4711.gitea.architecture=$TARGETPLATFORM \
    de.whatever4711.gitea.vcs-ref=$VCS_REF \
    de.whatever4711.gitea.vcs-url=$VCS_URL \
    de.whatever4711.gitea.build-date=$BUILD_DATE
