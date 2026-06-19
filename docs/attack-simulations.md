# Attack Simulation Exercises — MITRE ATT&CK Mapped

Documented attack simulations run from Kali Linux against lab target VMs, with detection validation in the Wazuh SIEM dashboard.

> **Purpose:** Prove the monitoring stack works end-to-end by generating real attacks and confirming they trigger the expected alerts.

---

## Exercise 1 — SSH Brute Force

| Field | Detail |
|---|---|
| **MITRE ATT&CK** | T1110 — Brute Force |
| **Attack Tool** | Hydra |
| **Source** | Kali Linux (192.168.x.10) |
| **Target** | Ubuntu Server (192.168.x.20) |
| **Target Service** | SSH (port 22) |

**Attack Command:**

```bash
hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://TARGET_IP -t 4 -w 5
```

**Expected Detection:**

| Wazuh Rule ID | Description | Level |
|---|---|---|
| 5710 | Attempt to login using a non-existent user | 5 |
| 5503 | PAM: User login failed | 5 |

**Result:** Wazuh generated a burst of authentication failure alerts within seconds of the attack starting. The alert volume and pattern (rapid sequential failures from a single source IP) is consistent with an automated brute force tool.

**SOC Takeaway:** In a production environment, this pattern would trigger an investigation into the source IP, followed by a temporary block and credential review for the targeted account.

---

## Exercise 2 — Sudo Privilege Escalation Attempt

| Field | Detail |
|---|---|
| **MITRE ATT&CK** | T1548 — Abuse Elevation Control Mechanism |
| **Attack Method** | Repeated `su root` with incorrect passwords |
| **Source** | Kali Linux → SSH into Ubuntu Server |
| **Target** | Ubuntu Server (192.168.x.20) |

**Attack Steps:**

```bash
# SSH into target
ssh user@TARGET_IP

# Attempt privilege escalation with wrong passwords
su root
# Enter wrong password 5-6 times
```

**Expected Detection:**

| Wazuh Rule ID | Description | Level |
|---|---|---|
| 5301 | User missed the password to change UID | 5 |
| 5503 | PAM: User login failed | 5 |

**Result:** Wazuh flagged each failed `su` attempt as a UID change failure paired with a PAM authentication failure. The sequence clearly shows an attacker with valid SSH access attempting to escalate to root.

**SOC Takeaway:** This is a post-compromise indicator — the attacker already has a foothold (valid SSH session) and is trying to escalate. The response would include reviewing how the initial access was obtained and whether any escalation succeeded.

---

## Exercise 3 — File Integrity Modification

| Field | Detail |
|---|---|
| **MITRE ATT&CK** | T1565.001 — Data Manipulation: Stored Data Manipulation |
| **Attack Method** | Modifying a system file monitored by Wazuh FIM |
| **Target** | Ubuntu Server — `/etc/hosts` |

**Attack Steps:**

```bash
# While SSH'd into the target
sudo echo "test" >> /etc/hosts
```

**Expected Detection:**

| Wazuh Rule ID | Description | Level |
|---|---|---|
| 550 | Integrity checksum changed | 7 |

**Result:** Wazuh's File Integrity Monitoring (syscheck) detected the modification to `/etc/hosts` and generated an alert with the file path, timestamp, and change details.

**SOC Takeaway:** Unauthorized changes to system files like `/etc/hosts` can indicate DNS hijacking or persistence mechanisms. FIM alerts on critical system files should always be investigated.

---

## Detection Coverage Summary

| Attack Type | Detection Layer | MITRE ATT&CK | Detected? |
|---|---|---|---|
| SSH Brute Force | Wazuh (endpoint logs) | T1110 | ✅ Yes |
| Privilege Escalation (su) | Wazuh (endpoint logs) | T1548 | ✅ Yes |
| File Integrity Change | Wazuh (FIM/syscheck) | T1565.001 | ✅ Yes |
| Network Port Scan (nmap) | Suricata (network IDS) | T1046 | ⚠️ Not on same VLAN |

**Key Insight:** Nmap scans between VMs on the same VLAN bypass pfSense entirely (traffic goes directly through the Proxmox bridge), so Suricata never sees them. This is a real-world detection gap — lateral movement within a flat network segment is invisible to network IDS. Endpoint detection (Wazuh agents) and micro-segmentation are the mitigations.

---

> All IP addresses have been sanitized. Exercises were performed in an isolated lab environment.
