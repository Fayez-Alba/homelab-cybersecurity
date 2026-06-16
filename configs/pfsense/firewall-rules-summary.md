# pfSense Firewall Rules Summary

> Sanitized overview of firewall rules configured on pfSense 2.8.1.  
> For full rule details, see the [build documentation](../docs/full-lab-writeup.pdf).

---

## WAN Interface

| # | Action | Source | Destination | Port | Purpose |
|---|--------|--------|-------------|------|---------|
| 1 | Block  | Any    | Any         | *    | Default deny all inbound |

> pfSense blocks all unsolicited WAN traffic by default. No port forwarding is configured.

---

## LAN Interface (VLAN 20 — Lab Network)

| # | Action | Source        | Destination       | Port | Purpose |
|---|--------|---------------|--------------------|------|---------|
| 1 | Allow  | LAN net       | Any                | *    | Lab VMs full outbound access |
| 2 | Block  | LAN net       | Management net     | *    | Prevent lab → management access |

---

## GUEST Interface (VLAN 40)

| # | Action | Source        | Destination       | Port | Purpose |
|---|--------|---------------|--------------------|------|---------|
| 1 | Allow  | GUEST net     | Any                | 80, 443, 53 | Internet access only |
| 2 | Block  | GUEST net     | RFC1918            | *    | Block access to all private networks |

---

## IOT Interface (VLAN 50)

| # | Action | Source        | Destination       | Port | Purpose |
|---|--------|---------------|--------------------|------|---------|
| 1 | Allow  | IOT net       | Any                | 80, 443, 53 | Internet access only |
| 2 | Block  | IOT net       | RFC1918            | *    | Full isolation from internal networks |

---

## Design Notes

- Rules are evaluated **top to bottom — first match wins**
- Source is set to **interface net**, not interface address, for correct subnet matching
- Each interface has its own DHCP server scope
- NAT (outbound) is handled automatically by pfSense for all interfaces
