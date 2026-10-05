FROM debian:bookworm-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        tftpd-hpa \
        nginx \
        supervisor \
        curl \
        nfs-kernel-server \
        rpcbind \
    && rm -rf /var/lib/apt/lists/*

# TFTP root and HTTP docroot (overlaid by compose bind mounts)
RUN mkdir -p /var/lib/tftpboot /var/www/html /data/iso \
    && chown -R nobody:nogroup /var/lib/tftpboot \
    && chown -R www-data:www-data /var/www/html

COPY docker/tftpd-hpa /etc/default/tftpd-hpa
COPY docker/nginx-default.conf /etc/nginx/sites-available/default
COPY docker/exports /etc/exports
COPY docker/supervisord.conf /etc/supervisor/conf.d/tftp-boot.conf
COPY docker/start-nfs.sh /usr/local/bin/start-nfs.sh
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /usr/local/bin/start-nfs.sh \
    && rm -f /etc/nginx/sites-enabled/default \
    && ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# TFTP / HTTP / NFS (casper netboot=nfs). Host networking binds these on the Docker host.
EXPOSE 69/udp 80/tcp 111/tcp 111/udp 2049/tcp 2049/udp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
