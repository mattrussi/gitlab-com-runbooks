ARG GL_ASDF_JSONNET_TOOL_VERSION
ARG GL_ASDF_SHFMT_VERSION

FROM registry.gitlab.com/gitlab-com/gl-infra/jsonnet-tool:v${GL_ASDF_JSONNET_TOOL_VERSION} as jsonnet-tool-image

FROM mvdan/shfmt:v${GL_ASDF_SHFMT_VERSION} as shfmt-image

FROM golang:alpine AS go-jsonnet

ARG GL_ASDF_GO_JSONNET_VERSION
ARG GL_ASDF_JB_VERSION

RUN apk add --no-cache bash git && \
    mkdir -p /build/bin && \
    cd /build && \
    go mod init local/build && \
    go get -d github.com/google/go-jsonnet/cmd/jsonnet@v${GL_ASDF_GO_JSONNET_VERSION} && \
    go build -o /build/bin/jsonnet github.com/google/go-jsonnet/cmd/jsonnet && \
    go get -d github.com/google/go-jsonnet/cmd/jsonnetfmt@v${GL_ASDF_GO_JSONNET_VERSION} && \
    go build -o /build/bin/jsonnetfmt github.com/google/go-jsonnet/cmd/jsonnetfmt && \
    go get -d github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v${GL_ASDF_JB_VERSION} && \
    go build -o /build/bin/jb github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

FROM google/cloud-sdk:alpine
ARG GL_ASDF_PROMTOOL_VERSION
ARG GL_ASDF_THANOS_VERSION

# Make sure these version numbers are not ahead of whats running in Production
ENV ALERTMANAGER_VERSION 0.22.2

RUN apk add --no-cache curl bash git jq alpine-sdk build-base openssl tar gcc libc-dev make

COPY .ruby-version .ruby-version

RUN apk add --no-cache linux-headers openssl-dev zlib-dev && \
  git clone https://github.com/rbenv/ruby-build.git && \
  PREFIX=/usr/local ./ruby-build/install.sh && \
  ruby-build $(cat .ruby-version) /usr/local && \
  apk del --no-cache glib-dev linux-headers openssl-dev zlib-dev && \
  rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

RUN gcloud components install kubectl -q

RUN mkdir /alertmanager && \
  wget -O alertmanager.tar.gz https://github.com/prometheus/alertmanager/releases/download/v$ALERTMANAGER_VERSION/alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz && \
  tar -xvf alertmanager.tar.gz -C /alertmanager --strip-components 1 --wildcards */amtool && \
  rm alertmanager.tar.gz && \
  ln -s /alertmanager/amtool /bin/amtool

RUN mkdir /prometheus && \
  wget -O prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v${GL_ASDF_PROMTOOL_VERSION}/prometheus-${GL_ASDF_PROMTOOL_VERSION}.linux-amd64.tar.gz && \
  tar -xvf prometheus.tar.gz -C /prometheus --strip-components 1 --wildcards */promtool && \
  rm prometheus.tar.gz && \
  ln -s /prometheus/promtool /bin/promtool

# Include Thanos
RUN mkdir /thanos && \
  wget -O thanos.tar.gz https://github.com/thanos-io/thanos/releases/download/v${GL_ASDF_THANOS_VERSION}/thanos-${GL_ASDF_THANOS_VERSION}.linux-amd64.tar.gz && \
  tar -xvf thanos.tar.gz -C /thanos --strip-components 1 --wildcards */thanos && \
  rm thanos.tar.gz && \
  ln -s /thanos/thanos /bin/thanos

COPY --from=nlknguyen/alpine-shellcheck:latest /usr/local/bin/shellcheck /usr/local/bin/shellcheck
COPY --from=shfmt-image /bin/shfmt /usr/local/bin/shfmt

COPY --from=go-jsonnet /build/bin/jsonnet /bin/jsonnet
COPY --from=go-jsonnet /build/bin/jsonnetfmt /bin/jsonnetfmt
COPY --from=go-jsonnet /build/bin/jb /bin/jb

COPY --from=jsonnet-tool-image /usr/local/bin/jsonnet-tool /bin/jsonnet-tool

RUN gem install --no-document json && \
    gem install --no-document yaml-lint && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

ENTRYPOINT ["/bin/sh", "-c"]
