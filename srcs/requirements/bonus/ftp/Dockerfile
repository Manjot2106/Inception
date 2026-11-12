FROM debian:bookworm

RUN apt-get update && apt-get install -y vsftpd

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY conf/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /var/run/vsftpd/empty

EXPOSE 21

CMD ["/entrypoint.sh"]