#!/bin/bash

useradd -M $FTP_USER
echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

mkdir -p /home/$FTP_USER/ftp
mkdir -p /home/$FTP_USER/ftp/wordpress

chown nobody:nogroup /home/$FTP_USER/ftp
chmod a-w /home/$FTP_USER/ftp
chmod +x /home/$FTP_USER/ftp

ln -s /wordpress_data /home/$FTP_USER/ftp/wordpress

chown -R $FTP_USER:$FTP_USER /home/$FTP_USER/ftp/wordpress
chmod 755 /home/$FTP_USER/ftp/wordpress

chown -h $FTP_USER:$FTP_USER /home/$FTP_USER/ftp/wordpress

exec /usr/sbin/vsftpd /etc/vsftpd.conf