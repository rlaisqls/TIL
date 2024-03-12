Sometimes we need access virtual machine OS’s web page, at the VMware Fusion 8, the default network setting is NAT, how to config it.

### 1. Set a Static IP for your virtual machine system.

Modify dhcpd.conf

```bash
sudo vim /Library/Preferences/VMware\ Fusion/vmnet8/dhcpd.conf
```

After where it says End of “DO NOT MODIFY SECTION” enter the following lines:

```
subnet 172.16.68.0 netmask 255.255.255.0 {
  range 172.16.68.128 172.16.68.254;
  option broadcast-address 172.16.68.255;
  option domain-name-servers 172.16.68.2;
  option domain-name localdomain;
  default-lease-time 1800;                # default is 30 minutes
  max-lease-time 7200;                    # default is 2 hours
  option netbios-name-servers 172.16.68.2;
  option routers 172.16.68.2;
}
host vmnet8 {
  hardware ethernet 00:50:56:C0:00:08;
  fixed-address 172.16.68.1;
  option domain-name-servers 0.0.0.0;
  option domain-name "";
  option routers 0.0.0.0;
}
```

hardware ethernet address — use your VMWare Fusion’s virtual MAC address.

> Important: You must allocate an IP address that is outside the range defined inside the DO NOT MODIFY SECTION section.

Quit VMWare Fusion, restart it.

### 2. Change NAT configure file.

```bash
sudo vi /Library/Preferences/VMware\ Fusion/vmnet8/nat.conf
```

find [incomingtcp] part, like this

```bash
[incomingtcp]
# Use these with care — anyone can enter into your VM through these…
# The format and example are as follows:
#<external port number> = <VM’s IP address>:<VM’s port number>
#8080 = 172.16.3.128:80
```

Add your configure, for example:

```bash
[incomingtcp]
# Use these with care — anyone can enter into your VM through these…
# The format and example are as follows:
#<external port number> = <VM’s IP address>:<VM’s port number>
#8080 = 172.16.3.128:80
80 = 172.16.106.128:80
```

It means we map virtual machine 80 port to host machine 80 port.

### 3. Restart network service of VMware Fusion.

Restart network service of VMware Fusion to apply setting.

```bash
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --stop
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --start
```

> The config files you changed will be reset after VMWare Fusion upgrade, please backup it at some where.

---
reference
- https://superuser.com/questions/314394/vmware-fusion-how-is-the-gateway-ip-decided-in-nat-networking-mode
- https://medium.com/@tuweizhong/how-to-setup-port-forward-at-vmware-fusion-8-for-os-x-742ad6ca1344