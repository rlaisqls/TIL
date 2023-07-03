# Cobbler

Cobbler is a Linux installation server that allows for rapid setup of network installation environments. It glues together and automates many associated Linux tasks so you do not have to hop between many various commands and applications when deploying new systems, and, in some cases, changing existing ones. Cobbler can help with provisioning, managing DNS and DHCP, package updates, power management, configuration management orchestration.

Just as configuration management systems rely on templates to simplify updates, so too does Cobbler. Templates are used extensively for management of services like DNS and DHCP, and the response files given to the various distributions (kickstart, preseed, etc.) are all templated to maximize code reuse.

In addition to templates, Cobbler relies on a system of snippets - small chunks of code (which are really templates themselves) that can be embedded in other templates. This allows admins to write things once, use it wherever they need it via a simple include, all while managing the content in just one place.

Automation is the key to speed, consistency and repeatability. These properties are critical to managing an infrastructure, whether it is comprised of a few servers or a few thousand servers. Cobbler helps by automating the process of provisioning servers from bare metal, or when deploying virtual machines onto various hypervisors.

---
reference
- https://en.wikipedia.org/wiki/Cobbler_(software)
- https://cobbler.readthedocs.io/en/latest/quickstart-guide.html