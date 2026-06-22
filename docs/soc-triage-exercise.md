# SOC Alert Triage Exercise — SSH Brute Force

A documented walk-through of a real alert triage process using data from the lab's Wazuh SIEM. This exercise demonstrates the structured approach a SOC analyst takes when investigating a security alert, from initial detection through response recommendation.

---

## 1. Alert Overview

| Field | Value |
|---|---|
| **Alert Timestamp** | Jun 22, 2026 @ 13:20:30 UTC |
| **Wazuh Rule ID** | 5760 |
| **Rule Description** | sshd: authentication failed |
| **Severity Level** | 5 (Medium) |
| **Source IP** | 192.168.x.10 |
| **Destination Host** | ubuntu-server-test (192.168.x.20) |
| **Target Account** | root |
| **Protocol / Port** | SSH (port 22) / Source port 56536 |
| **Agent** | ubuntu (ID: 002) |
| **Log Source** | journald → sshd |

**Raw Log:**
```
Jun 22 13:20:30 ubuntu-server-test sshd[201871]: Failed password for root from 192.168.x.10 port 56536 ssh2
```

---

## 2. MITRE ATT&CK Mapping

| Field | Value |
|---|---|
| **Technique IDs** | T1110.001, T1021.004 |
| **Technique Names** | Password Guessing, SSH |
| **Tactics** | Credential Access, Lateral Movement |

**What this means:** The attacker is attempting to guess the root password over SSH. If successful, this provides both credential access and a lateral movement path into the target system.

---

## 3. Compliance Framework Mapping

| Framework | Control |
|---|---|
| **PCI-DSS** | 10.2.4 (Invalid logical access attempts), 10.2.5 (Changes to authentication mechanisms) |
| **GDPR** | IV_35.7.d (Data protection impact assessment), IV_32.2 (Security of processing) |
| **HIPAA** | 164.312.b (Audit controls) |
| **NIST 800-53** | AU.14 (Session audit), AC.7 (Unsuccessful logon attempts) |
| **TSC** | CC6.1, CC6.8, CC7.2, CC7.3 |

---

## 4. Initial Triage Assessment

### 4.1 — Is this expected activity?

**No.** Rapid sequential SSH authentication failures targeting the root account from a single source IP is consistent with an automated brute force attack. Normal user behavior does not produce this pattern.

### 4.2 — Severity Assessment

| Factor | Assessment |
|---|---|
| Target account | **root** — highest privilege, critical severity |
| Attack volume | Multiple rapid failures — automated tool, not manual typos |
| Source location | Internal IP (192.168.x.10) — indicates attacker already has network access |
| Service exposed | SSH — direct shell access if compromised |

**Adjusted Severity: HIGH** — While Wazuh rates this as level 5 (medium), the combination of root targeting from an internal IP elevates the actual risk. An internal host attempting to brute force root over SSH suggests a compromised machine or an insider threat.

### 4.3 — True Positive or False Positive?

**True Positive.** The pattern is unambiguous: rapid sequential password failures from a single source IP targeting root over SSH. This is not a misconfigured service or a user mistyping their password.

---

## 5. IOC Extraction

| IOC Type | Value | Context |
|---|---|---|
| Source IP | 192.168.x.10 | Attack origin — internal network |
| Target IP | 192.168.x.20 | Victim host |
| Target Account | root | Privilege escalation target |
| Service | SSH (port 22) | Attack vector |
| Process | sshd (PID 201871) | Service handling the connection |

---

## 6. Investigation Steps

### 6.1 — Correlate related alerts

Search Wazuh for all alerts from source IP 192.168.x.10 in the same timeframe:

- **Query:** `data.srcip: 192.168.x.10 AND rule.groups: authentication_failed`
- **Result:** Multiple alerts within seconds — confirms automated attack, not manual attempts
- **Additional check:** Search for any successful authentication from the same IP (rule.id: 5715 or 5501) to determine if the brute force succeeded

### 6.2 — Check for successful compromise

Search for authentication success events immediately following the failures:

- **Query:** `data.srcip: 192.168.x.10 AND (rule.id: 5715 OR rule.id: 5501)`
- **Result:** If found — the account is compromised and this becomes a critical incident. If not found — the attack was unsuccessful but the source host needs investigation.

### 6.3 — Investigate the source host

The source IP (192.168.x.10) is an internal machine. Questions to answer:

- Is this host known and authorized? (Check asset inventory)
- Is there a legitimate reason for this host to SSH to the target?
- Are there signs of compromise on the source host? (Check its Wazuh agent alerts)
- What user or process initiated the SSH connections?

### 6.4 — Check Suricata for network-level indicators

**Note:** In this lab environment, both hosts are on the same VLAN (VLAN 20), so traffic between them does not traverse pfSense. Suricata running on pfSense's LAN interface would **not** see this traffic. This is a documented detection gap in the lab architecture.

In a production environment with proper network taps or host-based IDS, network-level indicators (connection volume, timing patterns) would supplement the endpoint logs.

---

## 7. Determination

| Finding | Detail |
|---|---|
| **Classification** | True Positive — SSH Brute Force Attack |
| **Attack Status** | Unsuccessful (no authentication success events detected) |
| **Source** | Internal host (192.168.x.10) |
| **Risk Level** | HIGH — internal origin + root targeting |
| **MITRE ATT&CK** | T1110.001 (Password Guessing) via T1021.004 (SSH) |

---

## 8. Recommended Response Actions

### Immediate (within 15 minutes)

1. **Block the source IP** on the target host's firewall or via pfSense rule:
   ```
   # On Ubuntu target:
   sudo ufw deny from 192.168.x.10 to any port 22
   ```
2. **Verify no successful login occurred** — check `/var/log/auth.log` for "Accepted" entries from the source IP
3. **Notify the system owner** of the target host

### Short-term (within 1 hour)

4. **Investigate the source host** (192.168.x.10) — check for signs of compromise, unauthorized users, or malicious processes
5. **Review SSH configuration** on the target:
   - Disable root login: `PermitRootLogin no` in `/etc/ssh/sshd_config`
   - Implement key-based authentication
   - Consider fail2ban or similar rate limiting
6. **Check other targets** — search Wazuh for the same source IP attacking other hosts

### Long-term (within 24 hours)

7. **Harden SSH across all lab hosts** — disable password authentication, enforce key-only access
8. **Implement automated blocking** via Wazuh active response or Shuffle SOAR playbook to auto-block IPs after N failed attempts
9. **Document the incident** and update detection rules if gaps were identified

---

## 9. Analyst Notes

This exercise demonstrates several real-world SOC principles:

- **Context changes severity.** The same alert from an external IP would be routine internet noise. From an internal IP targeting root, it's a potential compromise indicator. Automated severity ratings don't capture this context — the analyst's judgment does.

- **Detection gaps affect investigation.** The intra-VLAN blind spot meant Suricata couldn't provide network-level corroboration. In a production environment, this would be flagged as a monitoring coverage gap in the after-action report.

- **Unsuccessful doesn't mean unimportant.** The attack failed, but the investigation questions remain: why is an internal host running brute force tools? Is it compromised? Is this a rogue insider? The attack failing doesn't close the investigation — it shifts the focus to the source.

---

> All IP addresses have been sanitized. This triage was performed in an isolated lab environment using controlled attack simulations.
