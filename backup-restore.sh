#!/bin/bash

DOCKER=$(which docker)
ENV_FILE="$1"
SQL_FILE="$2"
TAG="$3"
IMAGE="dud380/mysql-backup-restore"
STATUS=0
LOGDIR="$4"


if [ ! -x "$DOCKER" ];then
    echo "Couldn't find docker."
    exit
fi

if [ -z "$ENV_FILE" ] || [ ! -f "$ENV_FILE" ] || [ -z "$TAG" ] || [ -z "$SQL_FILE" ] || [ ! -f "$SQL_FILE" ] || [ ! -d "$LOGDIR" ];then
    echo "Usage: backup-restore-sh <docker .env -file> <sql .sql -file> <5.6|5.7|8.0> <log path>"
    exit 1
fi
NAME=$(basename $ENV_FILE)
NAME=${NAME%.env}

# check image
if [ -z "$($DOCKER images -q $IMAGE:$TAG)" ];then
    echo "Image '$IMAGE:$TAG' is missing!"
    echo "To pull image do:"
    echo "docker pull '$IMAGE:$TAG'"
    exit 2
fi

#mkdir -p $LOGDIR

LOGFILE="$LOGDIR/$NAME.$(date +'%Y-%m-%d-%H-%M').log"

# delete container if exist
if $DOCKER container inspect $NAME > /dev/null 2>&1;then
    $DOCKER container stop $NAME > /dev/null
    $DOCKER container rm $NAME > /dev/null
fi

# delete volume if exist 
if $DOCKER volume inspect $NAME > /dev/null 2>&1;then
    $DOCKER volume rm $NAME > /dev/null
fi
$DOCKER volume create $NAME > /dev/null

# run backup/restore
start=$(date +"%Y-%m-%dT%H:%M")

$DOCKER run --name $NAME -v $NAME:/dump -v $SQL_FILE:/docker-entrypoint-initdb.d/2.tests.sql --env-file $ENV_FILE "$IMAGE:$TAG"

STATUS="$?"

end=$(date +"%Y-%m-%dT%H:%M")

status_message="OK"
if [ "$STATUS" -ne 0 ]; then
    # failed
    status_message="Failed. See '$LOGFILE' for more information."
    $DOCKER logs $NAME > $LOGFILE 2>&1
else
    $DOCKER container stop $NAME > /dev/null
    $DOCKER container rm $NAME > /dev/null
    $DOCKER volume rm $NAME > /dev/null
fi


# update main log
echo "$NAME,$start,$end,$TAG,$status_message" >> $LOGDIR/backup-restore.log
