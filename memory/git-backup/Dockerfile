FROM alpine:3.22
RUN apk add --no-cache git openssh-client
COPY backup.sh /usr/local/bin/backup.sh
ENTRYPOINT ["/bin/sh", "/usr/local/bin/backup.sh"]
