FROM emmanuelgeo77ray/ffmpeg:6.1-ubuntu2004-libzimg

# Install time and x264 for benchmark
RUN apt-get install -y time

RUN mkdir /input && mkdir /output
COPY skydiver_10sec.mp4 /input
ENV WRITE_FOLDER=/output
VOLUME [ "/output" ]

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]