ARG GOLANG_VERSION='1.25'
FROM golang:$GOLANG_VERSION-alpine as go

FROM alpine:3.18

COPY --from=go /usr/local/go /usr/local/go

ENV GOLANG_VERSION $GOLANG_VERSION

# don't auto-upgrade the gotoolchain
# https://github.com/docker-library/golang/issues/472
ENV GOTOOLCHAIN=local

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

COPY --from=go /go /go

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 1777 "$GOPATH"
WORKDIR $GOPATH

ARG BUILD_DATE
ARG VCS_REF

LABEL org.opencontainers.image.title="bdwyertech/go-crosscompile" \
    org.opencontainers.image.description="For cross-compiling with CGO enabled" \
    org.opencontainers.image.authors="Brian Dwyer <bdwyertech@github.com>" \
    org.opencontainers.image.url="https://hub.docker.com/r/bdwyertech/go-crosscompile" \
    org.opencontainers.image.source="https://github.com/bdwyertech/dkr-go-crosscompile.git" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE \
    org.label-schema.name="bdwyertech/go-crosscompile" \
    org.label-schema.description="For cross-compiling with CGO enabled" \
    org.label-schema.url="https://hub.docker.com/r/bdwyertech/go-crosscompile" \
    org.label-schema.vcs-url="https://github.com/bdwyertech/docker-go-crosscompile.git"\
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.build-date=$BUILD_DATE

RUN apk add bash clang curl git gcc gtk+3.0-dev libayatana-appindicator-dev libc++-dev mingw-w64-gcc musl-dev musl-fts

# RUN apk add libayatana-appindicator-dev --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community

RUN git clone --depth 1 https://github.com/tpoechtrager/osxcross.git /osxcross

RUN curl -sfLo /osxcross/tarballs/MacOSX11.1.sdk.tar.xz https://github.com/bdwyertech/dkr-crosscompile/releases/download/macsdk/MacOSX11.1.sdk.tar.xz \
    && apk add --no-cache --virtual .build-deps build-base bsd-compat-headers clang-dev cmake libxml2-dev libunwind-dev ocaml-dev openssl-dev musl-fts-dev python3 xz \
    && OSX_VERSION_MIN=10.14 UNATTENDED=1 /osxcross/build.sh \
    && rm -f /osxcross/tarballs/MacOSX11.1.sdk.tar.xz \
    && apk del .build-deps

# ARM64
RUN curl -sfL "https://musl.cc/aarch64-linux-musl-cross.tgz" | tar zxf - -C /usr/ --strip-components=1

ENV LD_LIBRARY_PATH=/osxcross/target/lib
ENV PATH /osxcross/target/bin:$PATH

WORKDIR /go
