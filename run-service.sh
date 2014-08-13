#!/usr/bin/env bash
set -e

# Use this script to start your meteor project, for instance from crontab with a entry like this:
# * * * * * /home/debian/meteor-udoo/run-service.sh

# change PROJECT_DIR to the path to your meteor project
PROJECT_DIR="/home/debian/udoo-radio"


if [ "`ps aux | grep -v grep | grep bin/node | grep meteor | grep tools/main.js | wc -l`" = "0" ]; then

cd $PROJECT_DIR
if [ -f "./meteor/local/db/mongod.lock" ]; then rm "./meteor/local/db/mongod.lock" ; fi
authbind --deep meteor --port 80

else
echo meteor is already running...
fi
