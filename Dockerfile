FROM vault:1.4.1

COPY config /config

RUN mkdir -p .aws
