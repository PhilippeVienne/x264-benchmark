#!/bin/sh

CORES=`grep -c ^processor /proc/cpuinfo`
WRITE_FOLDER=${WRITE_FOLDER:-/output}

cp /input/skydiver_10sec.mp4 $WRITE_FOLDER/skydiver_10sec.mp4

INPUT=$WRITE_FOLDER/skydiver_10sec.mp4
OUTPUT=$WRITE_FOLDER/o-

if [ -z ${THREADS+x} ]; then THREADS=$(($CORES / 2)); fi

for resolution in 1280x720 1920x1080
do
  for framerate in 30 60
  do
    printf "\n%10s: %10s @ %2s fps\n" "resolution" ${resolution} ${framerate}
    for preset in ultrafast superfast veryfast faster fast
    do
      printf "%10s: " ${preset}
      # TIME IN ms
      START=$(date +%s%N)
      ffmpeg -y -i $INPUT -s ${resolution} -r ${framerate} -c:v libx264 -preset ${preset} -threads ${THREADS} ${OUTPUT}${resolution}_${framerate}_${preset}.mp4 2> ${OUTPUT}${resolution}_${framerate}_${preset}.log 1> ${OUTPUT}${resolution}_${framerate}_${preset}.log
      END=$(date +%s%N)
      DIFF=$((($END - $START)/1000000))
      printf "Time: %2s\n" ${DIFF}
    done
  done
done