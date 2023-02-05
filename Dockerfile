FROM alpine:3.17

WORKDIR /backups

RUN apk -q add curl jq gawk

COPY entrypoint.sh entrypoint.sh

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

