
Configuration Drift is the phenomenon where servers in an infrastructure become more and more different from one another as time goes on, due to manual ad-hoc changes and updates, and general entropy.

A nice automated server provisioning process helps ensure machines are consistent when they are created, but during a given machine’s lifetime it will drift from the baseline, and from the other machines.

There are two main methods to combat configuration drift. One is to use automated configuration tools such as Puppet or Chef, and run them frequently and repeatedly to keep machines in line. The other is to rebuild machine instances frequently, so that they don’t have much time to drift from the baseline.

## Why Configuration Drift Matters

Configuration drift can lead to serious consequences, including:

- **Security vulnerabilities**—misconfigurations or unauthorized changes to configuration can lead to issues like escalation of privilege, use of vulnerable open source components, vulnerable container images, images pulled from untrusted repositories, or containers running as root.
- **Inefficient resource utilization**—configuration drift can result in over-provisioned workloads or older workloads that keep running when they are no longer needed, which can significantly impact cloud costs.
- **Reduced resilience and reliability**—configuration problems in production can cause crashes, bugs, and performance issues, which can be difficult to debug and resolve.

## IaC

An IaC approach helps with drift, but additional drift management is critical. Ansible helps you combat drift with Ansible Playbooks (automation workflows) that can be set up to detect drift. When drift is detected, it sends a notification to the appropriate person who can make the required modification and return the system to its baseline. 

---
reference
- https://opensourceforu.com/2015/03/ten-tools-for-configuration-management/
- http://kief.com/configuration-drift.html
- https://www.aquasec.com/cloud-native-academy/vulnerability-management/configuration-drift/#:~:text=Configuration%20drift%20is%20when%20the%20configuration%20of%20an%20environment%20%E2%80%9Cdrifts,without%20being%20recorded%20or%20tracked.