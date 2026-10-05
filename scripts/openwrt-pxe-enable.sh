#!/bin/sh
# Run ON the OpenWrt router (SSH as root) to point PXE clients at the Docker host.
# Pass TFTP_SERVER_IP in the environment (see .env.example).
set -eu

TFTP_SERVER_IP="${TFTP_SERVER_IP:-192.168.1.50}"
BOOTFILE="${BOOTFILE:-grubx64.efi}"

echo "Configuring OpenWrt DHCP boot → ${BOOTFILE} @ ${TFTP_SERVER_IP}"

# Prefer dhcp_boot (Option A). Clear conflicting list options if present.
uci delete dhcp.@dnsmasq[0].dhcp_boot 2>/dev/null || true
uci set dhcp.@dnsmasq[0].dhcp_boot="${BOOTFILE},,${TFTP_SERVER_IP}"

# Disable router-local TFTP so Docker owns UDP 69 on the server host
uci set dhcp.@dnsmasq[0].enable_tftp='0'
uci delete dhcp.@dnsmasq[0].tftp_root 2>/dev/null || true

# Remove option B style lists if they were added earlier (ignore errors)
uci del_list dhcp.lan.dhcp_option="66,${TFTP_SERVER_IP}" 2>/dev/null || true
uci del_list dhcp.lan.dhcp_option="67,${BOOTFILE}" 2>/dev/null || true

uci commit dhcp
/etc/init.d/dnsmasq restart

echo "Applied. Verify with: uci get dhcp.@dnsmasq[0].dhcp_boot"
uci get dhcp.@dnsmasq[0].dhcp_boot
echo "enable_tftp=$(uci get dhcp.@dnsmasq[0].enable_tftp)"
