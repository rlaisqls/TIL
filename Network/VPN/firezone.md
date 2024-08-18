
Firezone is an open source platform to securely manage remote access for any-sized organization. Unlike most VPNs, Firezone takes a granular, least-privileged approach to access management with group-based policies that control access to individual applications, entire subnets, and everything in between.

Unlike traditional VPNs, however, Firezone has the following key differences:

- Open source: All source code is available for anyone to audit on GitHub.
- Scalable: Firezone was designed to be horizontally scalable from the start. Simply deploy more Gateways to handle more traffic.
- Secure: Firezone is built on WireGuard®, a fast, provably-secure VPN protocol. Firezone further builds on this security with ephemeral encryption keys and firewall hole-punching to limit your exposed attack surface.
- Easy to manage: No firewall configuration or complex ACLs are required. Firezone's Policy Engine makes access easy to manage and audit at scale.

### Sites

Sites represent a shared network environment that Gateways and Resources exist within. All Gateways and Resources in a Site must have unobstructed network connectivity to each other.

A Site is a collection of Resources and Gateways that are logically grouped together. A Site can be a physical office location, a data center rack, a homelab network, VPC, or any other grouping that makes sense for your organization.

A Site can be as small as a single Gateway running on a single server managing the access to the Resources on that server, or as large as a data center network managing access to a cluster of servers.

To create a Site, click the Sites tab in the left-hand navigation and then click the Add Site button. You will be prompted to enter a name for the Site.

### Gateways

Gateways are what Clients connect to in order to access Resources in a Site. They're the data plane workhorse of the Firezone architecture and are responsible for securely routing traffic between Clients and Resources.


Gateways implement the industry-standard STUN and TURN protocols to perform secure NAT holepunching. This allows Firezone to establish direct connections between your Users and Resources while keeping your Resources invisible to the public internet.

Ideally, Gateways should be deployed as close to the Resources they're serving -- in some cases, even on the same host. This ensures the lowest possible latency and highest possible throughput for Client connections, and allows you to more easily deploy additional Gateways for other Resources that need to handle more Client connections.


### Resources

Resources define subnets, IP addresses, or DNS names you wish to manage access for.

- DNS: A domain name pattern to match.
    - By default, the pattern will only match exactly the name you enter.
    - To recursively match all subdomains, use a wildcard, such as `*.example.com`. This will match `example.com`, `sub2.example.com`, and `sub1.sub2.example.com`.
    - To non-recursively match all subdomains, use a question mark, such as `?.example.com`. This will match `example.com`, `sub1.example.com`, and `sub2.example.com` but not `sub1.sub2.example.com`.
- IP: A single IPv4 or IPv6 address
- CIDR: A range of IPv4 or IPv6 addresses in CIDR notation, such as `10.1.2.0/24` or `2001:db8::/48`

---
reference
- https://www.firezone.dev/kb
- https://www.firezone.dev/kb/architecture
