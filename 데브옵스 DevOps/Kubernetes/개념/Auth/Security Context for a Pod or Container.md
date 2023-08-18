# Security Context for a Pod or Container

A security context defines privilege and access control settings for a Pod or Container. Security context settings include, but are not limited to:

- Descretionary Access Control: Permission to access an object, like a file, is based on [user ID (UID) and group ID (GID)](https://wiki.archlinux.org/index.php/users_and_groups).
- [Security Enhanced Linux (SELinux)](https://en.wikipedia.org/wiki/Security-Enhanced_Linux): Objects are assigned security labels.
- Running as privileged or unprivileged.
- [Linux Capabilities](https://linux-audit.com/linux-capabilities-hardening-linux-binaries-by-removing-setuid/): Give a process some privileges, but not all the privileges of the root user.
- [AppArmor](https://kubernetes.io/docs/tutorials/security/apparmor/): Use program profiles to restrict the capabilities of individual programs.
- [Seccomp](https://kubernetes.io/docs/tutorials/security/seccomp/): Filter a process's system calls.
- `allowPrivilegeEscalation`: Controls whether a process can gain more privileges than its parent process. This bool directly controls whether the `[no_new_privs](https://www.kernel.org/doc/Documentation/prctl/no_new_privs.txt)` flag gets set on the container process. `allowPrivilegeEscalation` is always true when the container:
  - is run as privileged, or
  - has CAP_SYS_ADMIN
- `readOnlyRootFilesystem`: Mounts the container's root filesystem as read-only.


---
reference
- https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
- https://sysdig.com/learn-cloud-native/kubernetes-security/security-contexts/
- https://bcho.tistory.com/1275