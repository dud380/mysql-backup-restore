#!/bin/bash

LOGDIR="$1"
LOGFILE="$LOGDIR/backup-restore.log"

if [ ! -d "$LOGDIR" ] || [ ! -f "$LOGFILE" ];then
    echo "Usage: backup-restore-mailer.sh <log dir>"
    exit 1
fi


LOGDIR="$LOGDIR"
MJ_APIKEY_PUBLIC=""
MJ_APIKEY_PRIVATE=""
SENDER_EMAIL="sender@example.com"
SENDER_NAME="Sender name"
RECIPIENT_EMAIL="recipient@example.com"
RECIPIENT_NAME="Recipient name"
SUBJECT="Example subject"
TEXT="Only html"
date=$(date +"%Y-%m-%d")
CSS="
<style>
table {
  border-collapse: collapse;
  width: 100%;
}

th, td {
  text-align: left;
  padding: 8px;
}

tr:nth-child(even){background-color: #f2f2f2}

th {
  background-color: #4CAF50;
  color: white;
}
</style>
"
HTML="<!DOCTYPE html><html>
<head>$CSS</head>
<body><h2>Backup-Restore $date</h2></br><table border='1'><tr><th>Name</th><th>Start</th><th>Finnish</th><th>Tag</th><th>Status</th></tr>"

HTML+=$(awk -F',' -v pattern="^$date" '$2 ~ pattern { sub(/^.*T/,"" , $2);sub(/^.*T/,"" , $3); print "<tr><td>" $1 "</td><td> " $2 " </td><td> " $3 "</td><td>" $4 "</td><td>" $5 "</td></tr>" }' "$LOGFILE" )

HTML+="</table><br /><br />For more information and troubleshooting, see <a href='https://github.com/dud380/mysql-backup-restore'>MySQL-Backup-Restore</a>.</body></html>"

# remove all carriage returns. It will break json otherwise
HTML=$(echo $HTML|tr -d '\n')

# TODO - check json if failed
curl -s -X POST --user "$MJ_APIKEY_PUBLIC:$MJ_APIKEY_PRIVATE" https://api.mailjet.com/v3.1/send \
-H 'Content-Type: application/json' \
-d "{
    \"Messages\":[
            {
                    \"From\": {
                            \"Email\": \"$SENDER_EMAIL\",
                            \"Name\": \"$SENDER_NAME\"
                    },
                    \"To\": [
                            {
                                    \"Email\": \"$RECIPIENT_EMAIL\",
                                    \"Name\": \"$RECIPIENT_NAME\"
                            }
                    ],
                    \"Subject\": \"$SUBJECT\",
                    \"TextPart\": \"$TEXT\",
                    \"HTMLPart\": \"$HTML\"
            }
    ]
}" > /dev/null
