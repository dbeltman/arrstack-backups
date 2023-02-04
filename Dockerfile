FROM alpine:3.17

WORKDIR /backups

RUN apk -q add curl jq gawk && \
curl https://dl.min.io/client/mc/release/linux-arm64/mc \
  --create-dirs \
  -o /usr/bin/mc && \
chmod +x /usr/bin/mc

COPY entrypoint.sh entrypoint.sh

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

