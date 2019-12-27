# Golang build container
FROM golang:1.12 as serv-builder

ADD serv /building
WORKDIR /building

RUN GOPROXY=https://goproxy.cn go build -o redis-admin-serv .

# Node buid container
FROM node:8 as web-builder
RUN npm config set registry https://registry.npm.taobao.org

ADD web /building
WORKDIR /building

RUN npm install && npm run build:prod

# Fianl container
FROM alpine:3.11

RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
	wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.30-r0/glibc-2.30-r0.apk && \
	apk add glibc-2.30-r0.apk && \
	rm -rf glibc-2.30-r0.apk

WORKDIR /usr/share/redis-admin
ENV GIN_MODE=release

COPY --from=serv-builder /building/redis-admin-serv /building/config.ini ./
COPY --from=web-builder /building/dist/ ./www/

EXPOSE 80
ENTRYPOINT /usr/share/redis-admin/redis-admin-serv

