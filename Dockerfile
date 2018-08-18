FROM alpine:3.8

RUN apk update ; apk add wget
COPY pfsense-backup.sh /
VOLUME ["/data"]
CMD ["/pfsense-backup.sh"]
