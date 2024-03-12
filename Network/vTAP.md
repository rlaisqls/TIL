Being able to capture network packets from inside a network at strategic points is invaluable, whether it is done to troubleshoot or for security monitoring.

If, for example, users report that a website is intermittently inaccessible, IT can analyze the [captured network packets](https://www.techtarget.com/searchunifiedcommunications/tip/Check-packet-loss-to-manage-call-quality) and find an underlying issue by looking at the interactions between the client and the web server or router.

It's also possible to use an intrusion detection system (IDS) that listens to a stream of network traffic and alerts users when it identifies suspicious or malicious traffic based on known signatures or traffic anomalies.

<img width="567" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/ad7d9b8d-35b6-44ee-bf29-b203e0739be9">

### What is a TAP?

- In order to obtain these packets, they need to be intercepted.

- **A network Test Access Point (TAP)** can be either a virtual or a physical device that **listens to the network traffic on its network interfaces** and either **sends copies of the packets to another system or stores them directly to disk**.

- A physical TAP can be as simple as a box with mirrors capable of duplicating the light carried by an incoming fiber optic cable. 
- Alternatively, it can be a powered device, sometimes with built-in logic and software and network interfaces. Many professional switches have the option to assign an interface as a TAP port, as well -- this is called a Switched Port Analyzer, or SPAN.

### vTAP

- A virtual TAP, or vTAP, is located within a hypervisor such as VMware ESX or Oracle VM VirtualBox. It works in a similar manner by connecting to a virtual traffic flow or virtual switch.

- A benefit of a vTAP is that it can monitor traffic between two virtual machines within the same hypervisor without the traffic leaving the hardware.

- With the virtualization of network devices such as firewalls, switches and proxy servers, this has been a popular option in recent years.

- This diagram shows a sample implementation of a VTAP.

<img width="588" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/ec65abd1-1f12-4850-bb60-0fab0ce241e8">

### TAPs in the cloud

- Some cloud service providers (CSPs) have come up with solutions that enable customers to tap into their network traffic. 
  - This is important because whether a system is located in a company's own local data center or it is hosted within a cloud instance, visibility into troubleshooting and security monitoring is important.

- Some challenges CSPs face, however, arise from the fact that their platform environments are multi-tenant, which obviously raises further privacy and security concerns. The CSP cannot provide a customer access to the lower layer of the network infrastructure in a multi-tenant environment.

- Another complication is the location-independent nature of the public cloud. An organization's infrastructure -- including its virtual servers -- can be moved around between data centers and physical systems at any given time. As long as the CSP ensures availability and adheres to all the limitations requested by the customer, such as keeping data within selected geographic areas, this is not an issue. However, this does make it complex to select a static, reliable vTAP.

- Finally, cloud network traffic often uses different CSP-specific headers while the packets are in transit. The CSP removes those headers upon delivery of the traffic, but if the traffic was actually intercepted in transit, it would be hard to use in typical security devices and applications.

- Because vTAP configuration has been challenging for customers, creative users and researchers have come up with workarounds -- such as network address translation setups for AWS.

- Companies relying on network tap for their products to function, such as Gigamon, have also developed new products and services, such as TAP as a service for OpenStack.


---
참고
- https://www.techtarget.com/searchsecurity/tip/How-to-configure-a-vTAP-for-cloud-networks
- https://medium.com/oracledevs/network-monitoring-and-analysis-in-oci-using-vtap-and-opensearch-5100da1dbf23
- https://www.ateam-oracle.com/post/oci-vtap-and-linux-rsyslog
- https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/vtap.htm