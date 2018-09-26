#!/bin/bash
MONITORDIR="/media/pi/F1BB-58CC/GOES16/proc/"

inotifywait -m -r -e close_write --format '%w%f' "${MONITORDIR}" |
    while read LATEST_GOES16_PNG; do
	echo $LATEST_GOES16_PNG
	if [[ $LATEST_GOES16_PNG =~ .*\.png$ ]]; then
            cp ${LATEST_GOES16_PNG} ${MONITORDIR}../latest.png
	fi
    done