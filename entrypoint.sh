#!/usr/bin/env sh

if [ -z ${API_KEY} ] || [ -z ${ARR_HOST} ] || [ -z ${ARR_TYPE} ] || [ -z $S3_HOST ] || [ -z $S3_ACCESSKEY ] || [ -z $S3_SECRETKEY ]; then
	echo "Missing envs!"
	exit 1
fi

curl https://dl.min.io/client/mc/release/linux-arm64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc
chmod +x $HOME/minio-binaries/mc
export PATH=$PATH:$HOME/minio-binaries/

set -e

BACKUP_RETENTION=${BACKUP_RETENTION:-30}
minioclient=$HOME/minio-binaries/mc
$minioclient alias set backupstore $S3_HOST $S3_ACCESSKEY $S3_SECRETKEY
if $minioclient ls backupstore/arrstack-backups; then
    echo "Bucket already exists"
else
    echo "Creating bucket"
    $minioclient mb backupstore/arrstack-backups
fi

case "$ARR_TYPE" in
    radarr)
        BACKUP_URI=$(curl -s "$ARR_HOST/api/v3/system/backup?apiKey=${API_KEY}" | jq -r '. |= sort_by(.time) | last | .path')
        echo "BACKUP_URI: $BACKUP_URI"
        BACKUP_FILE=$(echo ${BACKUP_URI} | awk -F/ '{print $NF}')
        ;;
    *)
        echo "This ARR_TYPE is not supported (yet)"
esac


echo "Downloading ${BACKUP_FILE}"
curl -qso /backups/${BACKUP_FILE} "${ARR_HOST}${BACKUP_URI}?apiKey=${API_KEY}"
$minioclient cp ${BACKUP_FILE} backupstore/arrstack-backups
