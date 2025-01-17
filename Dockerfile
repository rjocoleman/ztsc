ARG ALPINE_VERSION=3.17
ARG CADDDY_VERSION=2.6.4

FROM caddy:${CADDDY_VERSION}-builder-alpine as caddy

RUN xcaddy build --with github.com/caddy-dns/lego-deprecated

FROM alpine:${ALPINE_VERSION} as zt-builder

ARG ZT_VERSION=1.10.6

RUN apk add --no-cache --update clang clang-dev alpine-sdk linux-headers cargo openssl-dev \
  && git clone --depth 1 --branch ${ZT_VERSION} https://github.com/zerotier/ZeroTierOne.git /src \
  && cd /src \
  && make -f make-linux.mk zerotier-one

FROM alpine:${ALPINE_VERSION}

LABEL maintainer="jonathan.camp@intelecy.com"

RUN apk add --update --no-cache libc6-compat libstdc++ nss-tools jq

COPY --from=zt-builder /src/zerotier-one /usr/sbin/

RUN mkdir -p /var/lib/zerotier-one \
  && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-idtool \
  && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-cli

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy

RUN mkdir /etc/caddy/ && printf "http://\n\nrespond \"ZeroTier sidecar is working! Now you just need a real Caddyfile.\"" > /etc/caddy/Caddyfile

ADD exec.sh /usr/local/bin

CMD ["exec.sh"]
