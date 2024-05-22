FROM alpine:3.20

WORKDIR /backups

RUN apk -q add curl jq gawk file && \
curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc && \
chmod +x $HOME/minio-binaries/mc && \
export PATH=$PATH:$HOME/minio-binaries/

COPY entrypoint.sh entrypoint.sh

RUN chmod +x entrypoint.sh
# CMD [ "sleep","infinity" ]
ENTRYPOINT ["./entrypoint.sh"]

