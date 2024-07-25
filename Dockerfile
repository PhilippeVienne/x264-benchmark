FROM emmanuelgeo77ray/ffmpeg:6.1-ubuntu2004-libzimg

RUN mkdir /input && mkdir /output
COPY skydiver_10sec.mp4 /input
ENV WRITE_FOLDER=/output
VOLUME [ "/output" ]

COPY entrypoint.sh /
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]