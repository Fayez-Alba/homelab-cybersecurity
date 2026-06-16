# TP-Link TL-SG108E — VLAN Port Assignments

> 802.1Q VLAN configuration for the managed switch.  
> Hardware version: V6 (2023 firmware)

---

## Port Map

| Port | Connected Device         | VLAN 1       | VLAN 20      | VLAN 40      | VLAN 50      | PVID |
|------|--------------------------|--------------|--------------|--------------|--------------|------|
| 1    | ISP Gateway / unused     | Untagged     | —            | —            | —            | 1    |
| 2    | Proxmox PC1 (trunk)      | Tagged       | Tagged       | Tagged       | Tagged       | 1    |
| 3    | TP-Link Omada AP (trunk) | Untagged     | —            | Tagged       | Tagged       | 1    |
| 4    | PC2 (management)         | Untagged     | —            | —            | —            | 1    |
| 5-8  | Unused                   | Untagged     | —            | —            | —            | 1    |

---

## Key Notes

- **Port 2 is the main trunk** — carries all VLANs tagged to Proxmox
- **Port 3** carries Guest (40) and IoT (50) tagged to the AP; management (VLAN 1) is untagged for AP admin access
- **PVID** determines which VLAN receives untagged traffic on that port
- All unused ports default to VLAN 1 untagged

---

## Critical: Save Configuration Procedure

The TL-SG108E **will lose all VLAN settings on reboot** if not explicitly saved.

1. Complete all VLAN changes
2. Navigate to **System → Save Config** in the web UI
3. Click **Save**
4. Only then reboot or power-cycle the switch

> **Warning:** Modifying VLAN 1 will drop your management connection to the switch.  
> Always configure VLANs 20, 40, and 50 first, save, then modify VLAN 1 last.
