FROM debian:bookworm-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        tftpd-hpa \
        nginx \
        supervisor \
        curl \
    && rm -rf /var/lib/apt/lists/*

# TFTP root and HTTP docroot (overlaid by compose bind mounts)
RUN mkdir -p /var/lib/tftpboot /var/www/html /data/iso \
    && chown -R nobody:nogroup /var/lib/tftpboot \
    && chown -R www-data:www-data /var/www/html

COPY docker/tftpd-hpa /etc/default/tftpd-hpa
COPY docker/nginx-default.conf /etc/nginx/sites-available/default
COPY docker/supervisord.conf /etc/supervisor/conf.d/tftp-boot.conf
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && rm -f /etc/nginx/sites-enabled/default \
    && ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

EXPOSE 69/udp 80/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
