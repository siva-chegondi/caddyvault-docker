FROM golang:1.12.4-alpine as builder

ENV GO111MODULE=on GOOS=linux GOARCH=amd64

RUN set -x && apk update && apk add --no-cache --upgrade git sed openssl ca-certificates

RUN mkdir -p $GOPATH/src/github.com/mholt \
	&& cd $GOPATH/src/github.com/mholt \
	&& git clone https://github.com/mholt/caddy.git

WORKDIR $GOPATH/src/github.com/mholt/caddy/caddy

RUN sed -i 's/\/\/ This is where other plugins get plugged in (imported)/_ \"github.com\/siva-chegondi\/caddyvault\"/' caddymain/run.go && \
	go build -o caddy main.go && \
	mv caddy /caddy

RUN /caddy -plugins

# Building completed

FROM alpine:latest

COPY --from=builder /caddy /usr/bin/caddy

# add certificate authorities
RUN apk update && apk add --upgrade ca-certificates openssl libcap && rm -rf /var/cache/apk/* && \
	setcap cap_net_bind_service=+ep /usr/bin/caddy

# RUN caddy with caddypath enabling
ENV CADDYPATH /.caddy
ENV CADDY_CLUSTERING=vault

# add site content here
RUN mkdir -p /var/www/html
ADD index.html /var/www/html
ADD Caddyfile /var/www/html

# RUN application
WORKDIR /var/www/html
EXPOSE 443 80 2015
CMD ["caddy", "-agree"]
