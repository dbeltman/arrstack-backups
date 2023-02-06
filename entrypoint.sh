#!/usr/bin/env sh

if [ -z ${API_KEY} ] || [ -z ${ARR_HOST} ] || [ -z ${ARR_TYPE} ] || [ -z $S3_HOST ] || [ -z $S3_ACCESSKEY ] || [ -z $S3_SECRETKEY ] || [ -z $BUCKET_NAME ]; then
	echo "Missing envs!"
	exit 1
fi

set -e
if [ ! -z $DEBUG ];then
    set -x
fi

BACKUP_RETENTION=${BACKUP_RETENTION:-30}
minioclient=$HOME/minio-binaries/mc
$minioclient alias set backupstore $S3_HOST $S3_ACCESSKEY $S3_SECRETKEY
if $minioclient ls backupstore/$BUCKET_NAME; then
    echo "Bucket already exists"
else
    echo "Creating bucket"
    $minioclient mb backupstore/$BUCKET_NAME
fi

echo "$ARR_TYPE detected!"
echo "Getting backup URL"
case "$ARR_TYPE" in
    radarr | sonarr)
        BACKUP_URI=$(curl -fs "${ARR_HOST}/api/v3/system/backup?apiKey=${API_KEY}" | jq -r '. |= sort_by(.time) | last | .path')        
        BACKUP_DOWNLOAD_URI=${ARR_HOST}${BACKUP_URI}?apiKey=${API_KEY}
        ;;
    prowlarr)
        BACKUP_URI=$(curl -fs "${ARR_HOST}/api/v1/system/backup?apiKey=${API_KEY}" | jq -r '. |= sort_by(.time) | last | .path')        
        BACKUP_DOWNLOAD_URI=${ARR_HOST}${BACKUP_URI}?apiKey=${API_KEY}
        ;;        
    bazarr)
        BACKUP_URI=$(curl -H "X-API-KEY: ${API_KEY}" -fs "${ARR_HOST}/api/system/backups" | jq -r '.data | .[length -1].filename')
        BACKUP_DOWNLOAD_URI=${ARR_HOST}/system/backup/download/${BACKUP_URI}
        ;;
    *)
        echo "This ARR_TYPE is not supported (yet)"
esac
BACKUP_FILE=$(echo ${BACKUP_URI} | awk -F/ '{print $NF}')
echo "BACKUP_FILE: ${BACKUP_FILE}"
echo "Downloading ${BACKUP_DOWNLOAD_URI}"
case "$ARR_TYPE" in
    radarr | sonarr | prowlarr)
        curl -fo /backups/${BACKUP_FILE} "${BACKUP_DOWNLOAD_URI}"
        ;;
    bazarr)
        curl -fH "X-API-KEY: ${API_KEY}" -fo /backups/${BACKUP_FILE} "${BACKUP_DOWNLOAD_URI}"
        ;;
    *)
        echo "This ARR_TYPE is not supported (yet)"
esac
echo "Uploading to $S3_HOST"
filetype=$(file $BACKUP_FILE | cut -d ":" -f 2 | xargs)
case $filetype in
    Zip*)
        echo "[INFO] Zip archive found!"
        ;;
    HTML*)
        echo "[ERROR] HTML file found. Check backup url"
        exit 1
        ;;
    empty)
        echo "[ERROR] Empty file found. Check backup url"
        exit 1
        ;;
    *)
        echo "[ERROR] Unknown file type, check backup url/settings."
        exit 1
        ;;
esac
$minioclient cp /backups/${BACKUP_FILE} backupstore/$BUCKET_NAME
