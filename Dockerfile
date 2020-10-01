FROM alpine:latest

RUN apk update ; apk add wget tzdata
COPY pfsense-backup.sh /
VOLUME ["/data"]
CMD ["/pfsense-backup.sh"]

