FROM ubuntu:focal

WORKDIR /backups

RUN apt update && apt install -y curl jq gawk && \
curl https://dl.min.io/client/mc/release/linux-arm64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc && \
chmod +x $HOME/minio-binaries/mc && \
export PATH=$PATH:$HOME/minio-binaries/

COPY entrypoint.sh entrypoint.sh

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

