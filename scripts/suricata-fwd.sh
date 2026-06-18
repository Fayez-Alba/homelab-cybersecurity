#!/bin/sh
# =============================================================
# suricata-fwd.sh
# =============================================================
# Forwards Suricata EVE JSON alert events from pfSense to
# the Wazuh SIEM manager via UDP syslog.
#
# Why this exists:
#   pfSense's native syslog daemon truncates messages to 480
#   bytes, destroying the JSON alert data. The Wazuh agent
#   package is not available for pfSense's FreeBSD base. This
#   script bypasses both limitations by reading the EVE JSON
#   file directly and forwarding only alert events via UDP.
#
# Install on pfSense:
#   Copy to /usr/local/bin/suricata-fwd.sh
#   chmod +x /usr/local/bin/suricata-fwd.sh
#
# Run:
#   /usr/local/bin/suricata-fwd.sh &
#
# Note:
#   This script does not survive pfSense reboots by default.
#   To persist, add it to shellcmd or /usr/local/etc/rc.d/.
#
# Customize:
#   - EVE_LOG: path to Suricata's EVE JSON log file
#   - WAZUH_IP: your Wazuh manager IP
#   - WAZUH_PORT: syslog port (default 514)
# =============================================================

EVE_LOG="/var/log/suricata/suricata_INTERFACE_ID/eve.json"
WAZUH_IP="WAZUH_MANAGER_IP"
WAZUH_PORT="514"

tail -F "$EVE_LOG" | while read line; do
  case "$line" in
    *event_type*alert*)
      echo "$line" | nc -w 1 -u "$WAZUH_IP" "$WAZUH_PORT"
      ;;
  esac
done
