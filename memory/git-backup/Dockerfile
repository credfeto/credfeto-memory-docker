FROM alpine:3.22
RUN apk add --no-cache git openssh-client && adduser -D -u 1000 -h /home/backup backup
COPY --chmod=0755 backup.sh /usr/local/bin/backup.sh
ENTRYPOINT ["/bin/sh", "/usr/local/bin/backup.sh"]
