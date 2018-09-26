#!/bin/bash

set -x

#directory for goestools config
GOESTOOLS_CONFIG="/media/data/config"

#goesrecv publisher host
GOESRECV_PUBLISHER="tcp://localhost:5004"

#goeslrit output dir
GOESLRIT_OUTPUT="/media/data/ingest/GOES-16/LRIT"

#goesproc output dir
GOESPROC_OUTPUT="/media/data/ingest"

#user to run goestools processes as
GOESTOOLS_RUNUSER="rambler"

#interval for goesrecv verbose output
GOESRECV_INTERVAL="60"

#log directory for goestools output
GOESTOOLS_LOG="/media/data/log"

#time between process stop and start attempts
SLEEP_TIME=".25s"

#process kill signal
SIG="2"

if [ "$EUID" -ne 0 ]
then echo "This script must be run as root!"
exit 1
fi &&

stop ()
{
echo "$(tput setaf 2 2> /dev/null)Stopping goestools...$(tput sgr0 2> /dev/null)" &&
GOESLRIT=$(ps -eo pid,comm,args | grep -w "goeslrit" | grep -v "grep" | awk '$2 == "goeslrit"' | awk '{print $1}') &&
GOESPROC=$(ps -eo pid,comm,args | grep -w "goesproc" | grep -v "grep" | awk '$2 == "goesproc"' | awk '{print $1}') &&
GOESRECV=$(ps -eo pid,comm,args | grep -w "goesrecv" | grep -v "grep" | awk '$2 == "goesrecv"' | awk '{print $1}') &&
while kill -0 $GOESLRIT > /dev/null 2>&1
do
kill -$SIG $GOESLRIT > /dev/null 2>&1 && sleep "$SLEEP_TIME"
done &&
while kill -0 $GOESPROC > /dev/null 2>&1
do
kill -$SIG $GOESPROC > /dev/null 2>&1 && sleep "$SLEEP_TIME"
done &&
while kill -0 $GOESRECV > /dev/null 2>&1
do
kill -$SIG $GOESRECV > /dev/null 2>&1 && sleep "$SLEEP_TIME"
done &&
if [[ $(screen -ls | wc -l) -gt 2 ]]
then
screen -wipe > /dev/null 2>&1
fi &&
wait
}

start ()
{
echo "$(tput setaf 2 2> /dev/null)Starting goestools...$(tput sgr0 2> /dev/null)" &&
if [[ -z "$GOESTOOLS_RUNUSER" ]]
then
GOESTOOLS_RUNUSER="root"
fi &&
screen -dmS goesrecv bash -c "( until goesrecv --config $GOESTOOLS_CONFIG/goesrecv.conf --verbose --interval $GOESRECV_INTERVAL ; do sleep 1s ; done ) 2>&1 | tee -a $GOESTOOLS_LOG/goesrecv.log ; exit" &&
sleep "$SLEEP_TIME" &&
screen -dmS goesproc bash -c "( su -c \"goesproc --config $GOESTOOLS_CONFIG/goesproc.conf --mode packet --subscribe $GOESRECV_PUBLISHER\" $GOESTOOLS_RUNUSER ) 2>&1 | tee -a $GOESTOOLS_LOG/goesproc.log ; exit" &&
sleep "$SLEEP_TIME" &&
screen -dmS goeslrit bash -c "( su -c \"cd $GOESLRIT_OUTPUT && goeslrit --subscribe $GOESRECV_PUBLISHER --images --messages --text\" $GOESTOOLS_RUNUSER ) 2>&1 | tee -a $GOESTOOLS_LOG/goeslrit.log ; exit"
}

if [[ "$@" =~ .*stop.* ]]
then
stop
elif [[ "$@" =~ .*start.* ]]
then
start
else
stop &&
start
fi &&

wait &&
exit