#!/bin/sh
# Run ON the OpenWrt router (SSH as root) to remove PXE boot options.
# Pass TFTP_SERVER_IP in the environment (see .env.example).
set -eu

TFTP_SERVER_IP="${TFTP_SERVER_IP:-192.168.1.50}"
BOOTFILE="${BOOTFILE:-grubx64.efi}"

echo "Removing OpenWrt DHCP PXE options (bootfile ${BOOTFILE}, server ${TFTP_SERVER_IP})"

uci delete dhcp.@dnsmasq[0].dhcp_boot 2>/dev/null || true
uci del_list dhcp.lan.dhcp_option="66,${TFTP_SERVER_IP}" 2>/dev/null || true
uci del_list dhcp.lan.dhcp_option="67,${BOOTFILE}" 2>/dev/null || true

uci commit dhcp
/etc/init.d/dnsmasq restart

echo "PXE options cleared. dnsmasq restarted."
