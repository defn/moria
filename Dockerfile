FROM vault:1.4.1

COPY config /config

COPY service /service
RUN chmod 755 /service

ENTRYPOINT [ "sh", "/service" ]
