#!/bin/sh

if [ $# -eq 0 ]
then
 PORT=2222
 USER=vagrant
 HOST=localhost
 KEY_FILE=/home/melesh/virtual/.vagrant/machines/default/virtualbox/private_key
 LOCAL_DIR=../../see_through
 REMOTE_DIR=/home/vagrant/
else
 HOST=$1
 USER=$2
 PORT=22
 KEY_FILE=$3
 LOCAL_DIR=$4
 REMOTE_DIR=box
fi

scp -rp -P$PORT -i $KEY_FILE $LOCAL_DIR/see_through.zip $USER@$HOST:$REMOTE_DIR/see_through
#ssh -i $KEY_FILE -p $PORT $USER@$HOST $REMOTE_DIR/see_through/ops/provision.sh
#ssh -i $KEY_FILE -p $PORT $USER@$HOST "cd box && vagrant ssh -c \"/vagrant/see_through/ops/provision.sh\""
