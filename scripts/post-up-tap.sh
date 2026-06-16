#!/bin/bash
# =============================================================
# fix-tap-interfaces.sh
# =============================================================
# Fixes tap interfaces stuck in UNKNOWN operational state after
# Proxmox reboots. Without this, VMs on affected bridges may
# have intermittent or no network connectivity.
#
# Install:
#   sudo cp fix-tap-interfaces.sh /usr/local/bin/
#   sudo chmod +x /usr/local/bin/fix-tap-interfaces.sh
#
# Usage:
#   Called automatically via post-up in /etc/network/interfaces
#   Can also be run manually: sudo ./fix-tap-interfaces.sh
#
# Why this is needed:
#   When Proxmox initializes bridges on boot, tap interfaces
#   (tapXXXi0) sometimes fail to transition to UP state,
#   showing "UNKNOWN" in `ip link show`. Explicitly setting
#   them UP after the bridge is ready resolves this.
# =============================================================

LOG_TAG="fix-tap"

# Find all tap interfaces and bring them up
for tap in $(ip -o link show | grep -oP 'tap\d+i\d+'); do
    state=$(ip -o link show "$tap" | grep -oP 'state \K\S+')
    if [ "$state" = "UNKNOWN" ] || [ "$state" = "DOWN" ]; then
        ip link set "$tap" up
        logger -t "$LOG_TAG" "Brought $tap up (was $state)"
    fi
done
