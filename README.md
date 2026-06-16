# 🔒 Home Cybersecurity Lab

A segmented home network lab built from scratch on a single mini PC — featuring VLAN isolation, a dedicated firewall/router, and centralized SIEM monitoring. Designed to simulate an enterprise SOC environment for hands-on threat detection and incident response.

> **📄 Full build documentation:** For the complete phase-by-phase walkthrough with commands, configs, and detailed troubleshooting — see [docs/full-lab-writeup.pdf](docs/full-lab-writeup.pdf)

---

## 🏗️ Architecture

![Network Architecture](docs/architecture-diagram.png)

```
ISP Gateway (NAT mode — no true bridge support)
        │
   [UGREEN USB NIC — Dedicated WAN]
        │
   ┌────┴────┐
   │ pfSense │──── VLAN 1  — Management
   │  2.8.1  │──── VLAN 20 — Isolated Lab (attack/defend)
   │         │──── VLAN 40 — Guest WiFi (internet-only)
   │         │──── VLAN 50 — IoT (restricted)
   └────┬────┘
        │
  [TP-Link TL-SG108E — 802.1Q VLAN Trunking]
        │
  ┌─────┴──────┐
  │  Proxmox   │──── Kali Linux    (attack VM)
  │    VE      │──── Ubuntu Server  (target + Wazuh agent)
  │  M910q     │──── Windows 11     (target + Wazuh agent)
  │            │──── Wazuh 4.14.2   (SIEM — manager/indexer/dashboard)
  └────────────┘
        │
  [TP-Link Omada EAP723 — 3 SSIDs mapped to VLANs]
```

---

## 🛠️ Tech Stack

| Layer | Technology | Role |
|---|---|---|
| Hypervisor | Proxmox VE 9.1.1 | VM hosting on bare metal |
| Firewall / Router | pfSense 2.8.1 | VLAN routing, NAT, DHCP, firewall rules |
| SIEM | Wazuh 4.14.2 | Log collection, file integrity monitoring, alerts |
| Managed Switch | TP-Link TL-SG108E | 802.1Q VLAN trunking |
| Wireless AP | TP-Link Omada EAP723 | 3 SSIDs segmented by VLAN |
| WAN Adapter | UGREEN USB NIC (ASIX AX88179) | Dedicated WAN uplink to pfSense |
| Attack VM | Kali Linux 2025.4 | Offensive security testing |
| Target VMs | Ubuntu Server, Windows 11 | Endpoints with Wazuh agents |

| Hardware | Spec |
|---|---|
| Lenovo ThinkCentre M910q | 32 GB RAM · 1 TB NVMe |

---

## 🌐 Network Design

Four VLANs enforced at the switch and routed through pfSense, each with dedicated DHCP scopes and firewall rule sets:

| VLAN | Name | Purpose | Gateway |
|---|---|---|---|
| 1 | Management | Proxmox admin, PC2 access | — |
| 20 | Lab | Isolated attack/defend network | pfSense LAN |
| 40 | Guest | Internet-only WiFi for visitors | pfSense GUEST |
| 50 | IoT | Restricted smart devices | pfSense IOT |

The ISP gateway (Rogers Ignite) doesn't support true bridge mode, so a **dedicated USB NIC** provides a clean WAN path into pfSense — eliminating double-NAT and keeping WAN traffic completely off the VLAN trunk.

---

## 📊 SIEM — Wazuh 4.14.2

Wazuh runs as a dedicated VM with the full stack (manager, indexer, dashboard). Agents on all three target VMs ship logs over port 1514. The Filebeat pipeline routes parsed events into the indexer for dashboard visualization.

Current monitoring coverage includes file integrity monitoring (FIM), security event correlation, and agent health tracking. pfSense firewall logs are ingested via syslog.

---

## 🧠 Lessons Learned

The PDF documents *what broke and how I fixed it*. This section covers *what those problems actually taught me* — the thinking behind the troubleshooting.

### Every layer affects every other layer
The single biggest lesson. When the Proxmox firewall flag silently killed ARP between VMs, I spent hours suspecting pfSense rules, then switch trunk config, before isolating it to a hypervisor-level setting I didn't think could impact Layer 2. It taught me to challenge assumptions about which layer owns a problem — the answer is often the layer you're not looking at.

### "It works" is not the same as "it's configured correctly"
The TL-SG108E appeared to save VLAN configs but silently reverted on reboot. Ubuntu VMs grabbed the right static IP until cloud-init quietly overwrote it on the next boot. Both worked during testing and failed in production. I now treat "survives a reboot" as the real test, not "works right now."

### Security tooling creates its own security problems
SELinux blocked Wazuh agent communication on port 1514. The quick fix was permissive mode — which I used, and documented. But I also documented that this is a trade-off: in a production environment, the correct move is writing a custom SELinux policy, not disabling enforcement. Knowing the shortcut *and* knowing why it's a shortcut is the difference between a lab exercise and real engineering judgment.

### Workarounds are fine — undocumented workarounds are debt
The Rogers gateway doesn't support true bridge mode. The tap interfaces need post-up scripts after every Proxmox reboot. These aren't failures — they're constraints. But if I hadn't documented them, the next person (or future me) would waste hours rediscovering them. Writing it down is part of the fix.

### Tooling without telemetry is just decoration
Standing up Wazuh was the easy part. The hard part was the Filebeat pipeline — the dashboard showed zero alerts even though agents were reporting. It looked deployed but it wasn't *working*. That gap between "installed" and "generating actionable data" is where most home labs stop. Pushing through it is what makes this a monitoring stack and not just a checkbox.

---

## 📸 Screenshots

| View | Screenshot |
|---|---|
| Proxmox VM Dashboard | ![Proxmox](docs/screenshots/proxmox-dashboard.png) |
| pfSense Interface Assignments | ![pfSense](docs/screenshots/pfsense-interfaces.png) |
| pfSense Firewall Rules | ![pfSense](docs/screenshots/pfsense-rules.png) |
| Wazuh Alert Dashboard | ![Wazuh](docs/screenshots/wazuh-alerts.png) |
| Switch VLAN Config | ![VLANs](docs/screenshots/vlan-config.png) |

---

## 📁 Repository Structure

```
homelab-cybersecurity/
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   ├── full-lab-writeup.pdf
│   ├── architecture-diagram.png
│   └── screenshots/
│       ├── proxmox-dashboard.png
│       ├── pfsense-interfaces.png
│       ├── pfsense-rules.png
│       ├── wazuh-alerts.png
│       └── vlan-config.png
├── configs/
│   ├── pfsense/
│   │   └── firewall-rules-summary.md
│   ├── wazuh/
│   │   ├── ossec.conf.example
│   │   └── filebeat.yml.example
│   ├── proxmox/
│   │   └── interfaces.example
│   └── switch/
│       └── vlan-assignments.md
└── scripts/
    └── post-up-tap.sh
```

---

## 🗺️ Roadmap

- [ ] Deploy Suricata IDS for network-level threat detection
- [ ] Integrate TheHive for incident case management
- [ ] Add Shuffle SOAR for automated response playbooks
- [ ] Feed threat intel via MISP
- [ ] Run MITRE ATT&CK simulations with Atomic Red Team / Caldera
- [ ] Add vulnerability scanning with OpenVAS
- [ ] Expand endpoints with a Linux Mint node (MacBook Pro repurpose)
- [ ] Build Windows Active Directory domain for enterprise-style logging

---

## 🎓 Certifications

- CompTIA Security+
- Google Cybersecurity Analyst Certificate

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

> All IP addresses, MAC addresses, and ISP-specific details have been sanitized throughout this repository.
