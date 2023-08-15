# Kube-proxy

`kube-proxy` is another per-node daemon in Kubernetes, like Kubelet.

`kube-proxy` provides **basic load balancing functionality within the cluster**. It implements services and relies on Endpoints/EndpointSlices. It may help to reference that section, but the following is the relevant and quick explanation:

- Services define a load balancer for a set of pods.
- Endpoints (and endpoint slices) list a set of ready pod IPs. They are created automatically from a service, with the same pod selector as the service.

Most types of services have an **IP address for the service, called the cluster IP address, which is not routable outside the cluster**.

`kube-proxy` is responsible for routing requests to a service’s cluster IP address to healthy pods. `kube-proxy` is by far the most common implementation for Kubernetes services, but there are alternatives to `kube-proxy`, such as a <u>replacement mode Cilium</u>.

kube-proxy has four modes, which change its runtime mode and exact feature set:
- `userspace`
- `iptables`
- `ipvs`
- `kernelspace`
 
You can specify the mode using `--proxy-mode <mode>`. It’s worth noting that all modes rely on iptables to some extent.

And You can check the mode that using below command

```
kubectl logs -f [YOUR_POD_NAME] -n kube-system
```

## userspace Mode

<img width="502" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/f6e37dc7-c7ce-42b8-8ee7-18f704da7faa">


<details>
<summary>Chains</summary>
<div markdown="1">

---

**KUBE-PORTALS-CONTAINER**
  
```bash
Chain KUBE-PORTALS-CONTAINER (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 REDIRECT   tcp  --  *      *       0.0.0.0/0            10.96.98.173         /* default/my-nginx-loadbalancer: */ tcp dpt:80 redir ports 38023
    0     0 REDIRECT   tcp  --  *      *       0.0.0.0/0            172.35.0.200         /* default/my-nginx-loadbalancer: */ tcp dpt:80 redir ports 38023
    0     0 REDIRECT   tcp  --  *      *       0.0.0.0/0            10.103.1.234         /* default/my-nginx-cluster: */ tcp dpt:80 redir ports 36451
    0     0 REDIRECT   tcp  --  *      *       0.0.0.0/0            10.97.229.148        /* default/my-nginx-nodeport: */ tcp dpt:80 redir ports 44257
``` 

---

**KUBE-NODEPORT-CONTAINER**

```bash
Chain KUBE-NODEPORT-CONTAINER (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 REDIRECT   tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/my-nginx-loadbalancer: */ tcp dpt:30781 redir ports 38023
    0     0 REDIRECT   tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/my-nginx-nodeport: */ tcp dpt:30915 redir ports 44257
```

---

**KUBE-PORTALS-HOST**
  
```bash
Chain KUBE-PORTALS-HOST (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            10.96.98.173         /* default/my-nginx-loadbalancer: */ tcp dpt:80 to:172.35.0.100:38023
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            172.35.0.200         /* default/my-nginx-loadbalancer: */ tcp dpt:80 to:172.35.0.100:38023
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            10.103.1.234         /* default/my-nginx-cluster: */ tcp dpt:80 to:172.35.0.100:46635
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            10.97.229.148        /* default/my-nginx-nodeport: */ tcp dpt:80 to:172.35.0.100:32847
```

---

**KUBE-NODEPORT-HOST**
  
```bash
Chain KUBE-NODEPORT-HOST (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/my-nginx-loadbalancer: */ tcp dpt:30781 to:172.35.0.100:38023
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/my-nginx-nodeport: */ tcp dpt:30915 to:172.35.0.100:44257
```

</div>
</details>

The first and oldest mode is `userspace mode`. In userspace mode, `kube-proxy` runs a web server and **routes all service IP addresses to the web server, using iptables.** The web server terminates connections and proxies the request to a pod in the service’s endpoints. 

**userspace mode's disadvantage**

The kube-proxy belongs to the User Space area as it operates as a Process. And Netfilter, which is in charge of Host's networking, belongs to the Kernel area.

Essentially, the operation of User Space (Process) is done through Kernel. The User Space program is much slower than the Kernel's own service because it has a system that requests services from Kernel when the Process needs CPU time for calculation, disk for I/O operations, and memory.

The kube-proxy in UserSpace Mode requires a lot of access between UserSpace and Kernel because most networking tasks such as load balancing and packet rule setting are mainly controlled by the kube-proxy itself, which is a process. Because of these issues, the kube-proxy in UserSpace Mode has a problem of slowing networking speed. So userspace mode is no longer commonly used, and we suggest avoiding it unless you have a clear reason to use it.

## iptables Mode

<img width="502" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/0457bc57-9a73-4eb9-97db-add61c012b83">

- Since the request packet transmitted from most Pod is delivered to the Host's Network Namespace through the Pod's veth, the request packet is delivered to the `KUBE-SERVICES Table` by the `PREROUTING Table`.
  - The request packet sent by Pod or Host Process using Host's Network Namespace is delivered to the `KUBE-SERVICES Table` by the `OUTPUT Table`.

- `KUBE-SERVICES Table`
  
  - If the Dest IP and Dest Port of the request packet match the IP and Port of the ClusterIP Service, the request packet is forwarded to the NAT table of the matching ClusterIP Service, `KUBE-SVC-XXX Table`.
  
  - If the Dest IP of the request packet is Node's own IP, the request packet is delivered to the `KUBE-NODEPORTS Table`.

- `KUBE-NODEPORTS Table`

  - If the Dest Port of the request packet matches the Port of the NodePort Service, the request packet is forwarded to the NAT Table of the NodePort Service, `KUBE-SVC-XXX Table`.

- `KUBE-SERVICES Table`

  - If the Dest IP and Dest Port of the request packet match the External IP and Port of the Load Balancer Service, the request packet is delivered to the `KUBE-FW-XXX Table`, the NAT Table of the matching Load Balancer Service, and then to the `KUBE-SVC-XXX Table`.

<details>
<summary>Chains</summary>
<div markdown="1">

---

**KUBE-SERVICES**
```bash
Chain KUBE-SERVICES (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-MARK-MASQ  tcp  --  *      *      !192.167.0.0/16       10.96.98.173         /* default/my-nginx-loadbalancer: cluster IP */ tcp dpt:80
    0     0 KUBE-SVC-TNQCJ2KHUMKABQTD  tcp  --  *      *       0.0.0.0/0            10.96.98.173         /* default/my-nginx-loadbalancer: cluster IP */ tcp dpt:80
    0     0 KUBE-FW-TNQCJ2KHUMKABQTD  tcp  --  *      *       0.0.0.0/0            172.35.0.200         /* default/my-nginx-loadbalancer: loadbalancer IP */ tcp dpt:80
    0     0 KUBE-MARK-MASQ  tcp  --  *      *      !192.167.0.0/16       10.103.1.234         /* default/my-nginx-cluster: cluster IP */ tcp dpt:80
    0     0 KUBE-SVC-52FY5WPFTOHXARFK  tcp  --  *      *       0.0.0.0/0            10.103.1.234         /* default/my-nginx-cluster: cluster IP */ tcp dpt:80 
    0     0 KUBE-MARK-MASQ  tcp  --  *      *      !192.167.0.0/16       10.97.229.148        /* default/my-nginx-nodeport: cluster IP */ tcp dpt:80
    0     0 KUBE-SVC-6JXEEPSEELXY3JZG  tcp  --  *      *       0.0.0.0/0            10.97.229.148        /* default/my-nginx-nodeport: cluster IP */ tcp dpt:80
    0     0 KUBE-NODEPORTS  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service nodeports; NOTE: this must be the last rule in this chain */ ADDRTYPE match dst-type LOCAL
```

---

**KUBE-NODEPORTS**

```bash
Chain KUBE-NODEPORTS (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-MARK-MASQ  tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/my-nginx-loadbalancer: */ tcp dpt:30781
    0     0 KUBE-SVC-TNQCJ2KHUMKABQTD  tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/my-nginx-loadbalancer: */ tcp dpt:30781
    0     0 KUBE-MARK-MASQ  tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/my-nginx-nodeport: */ tcp dpt:30915
    0     0 KUBE-SVC-6JXEEPSEELXY3JZG  tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/my-nginx-nodeport: */ tcp dpt:30915 
```

---

**KUBE-FW-XXX**

```bash
Chain KUBE-FW-TNQCJ2KHUMKABQTD (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-MARK-MASQ  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/my-nginx-loadbalancer: loadbalancer IP */
    0     0 KUBE-SVC-TNQCJ2KHUMKABQTD  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/my-nginx-loadbalancer: loadbalancer IP */
    0     0 KUBE-MARK-DROP  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/my-nginx-loadbalancer: loadbalancer IP */
```

---

**KUBE-SVC-XXX**

```bash
Chain KUBE-SVC-TNQCJ2KHUMKABQTD (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-SEP-6HM47TA5RTJFOZFJ  all  --  *      *       0.0.0.0/0            0.0.0.0/0            statistic mode random probability 0.33332999982
    0     0 KUBE-SEP-AHRDCNDYGFSFVA64  all  --  *      *       0.0.0.0/0            0.0.0.0/0            statistic mode random probability 0.50000000000
    0     0 KUBE-SEP-BK523K4AX5Y34OZL  all  --  *      *       0.0.0.0/0            0.0.0.0/0      
```

---

**KUBE-SEP-XXX**

```bash
Chain KUBE-SEP-6HM47TA5RTJFOZFJ (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-MARK-MASQ  all  --  *      *       192.167.2.231        0.0.0.0/0
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp to:192.167.2.231:80 
```

---

**KUBE-POSTROUTING**

```bash
Chain KUBE-POSTROUTING (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MASQUERADE  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service traffic requiring SNAT */ mark match
0x4000/0x4000 
```

---

**KUBE-MARK-MASQ**

```bash
Chain KUBE-MARK-MASQ (23 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MARK       all  --  *      *       0.0.0.0/0            0.0.0.0/0            MARK or 0x4000 
```

---

**KUBE-MARK-DROP**

```bash
Chain KUBE-MARK-DROP (10 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MARK       all  --  *      *       0.0.0.0/0            0.0.0.0/0            MARK or 0x8000 
```

</div>
</details>


### Source IP

<img width="602" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/2f2a2cca-bee0-427b-ae0f-a5f9bf9cbc24">

The Src IP of the Service Request Packet is maintained or SNATed to the IP of the Host through Masquerade. **The `KUBE-MARK-MASQ` Table is a table that performs marking on the packet for Masquerade of the request packet.** The marked packet is Masquerade in the `KUBE-POSTROUTING` Table, and the Src IP is SNATed to the Host's IP. If you look at the iptables tables, you can see that the packet to be performed Masquerade is marked through the `KUBE-MARK-MASQ` Table.

If the `externalTrafficPolicy` value is set to Local, the `KUBE-NODEPORTS` Table disappears from the `KUBE-MARK-MASQ` Table, and Masquerade is not performed. Therefore, the Src IP of the request packet is attracted as it is. In addition, the request packet is not Load Balanced on the Host, but is delivered only to the Target Pod driven on the Host where the request packet was delivered. If the request packet is delivered to a Host without a Target Pod, the request packet is dropped.

The left side of the figure below shows a figure that does not perform Masquerade by setting the external Traffic Policy to Local.

<img width="633" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/6315bc3b-0f79-4e9a-9b45-a7c4343d348e">

`ExternalTrafficPolicy` Local is mainly used in `LoadBalancer` Service. This is because the Src IP of the request packet can be maintained, and the Load Balancer of the Cloud Provider performs Load Balancing, so the Load Balancing process of the Host is unnecessary.

If the `externalTrafficPolicy` value is Local, the packet is dropped on the Host without the Target Pod, so during the Host Health Check process performed by the LoadBalancer of the Cloud Provider, the Host without the Target Pod is excluded from the Load Balancing target. Therefore, Cloud Provider's Load Balancer only load balances the request packet to the Host with the Target Pod.

Masquerade is also necessary if the request packet is returned to itself by sending the request packet from Pod to the IP of the service to which it belongs.
- The left side of the figure above shows this case. The request packet is DNATed, and both the Src IP and Dest IP of the packet become Pod's IP.
- Therefore, if you send a response packet to a request packet returned from Pod, SNAT is not performed because the packet is processed in Pod without going through the NAT Table of the Host.

- Masquerade allows you to **force the request packet returned to Pod to the Host so that SNAT can be performed**. In this way, the technique of deliberately bypassing and receiving a packet is called **hairpinning**.
  - The right side of the above figure shows the case of applying hairpinning using Masqurade.

- In the `KUBE-SEP-XXX` Table, if the Src IP of the request packet is the same as the IP to be DNAT, that is, if the packet that Pod sent to the Service is received by itself, the request packet is marked through the `KUBE-MARK-MASQ` Table and Masquerade in the `KUBE-POSTROUTING` Table.
- Since the Src IP of the packet that Pod received is set to the IP of the Host, Pod's response is delivered to the Host's NAT Table, and then SNAT, DNAT, and delivered to Pod.

## ipvs Mode

<img width="502" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/38220084-58e3-4c14-8878-a1470d8b1a54">


- Since the request packet transmitted from most Pod is delivered to the Host's Network Namespace through the Pod's veth, the request packet is delivered to the `KUBE-SERVICES Table` by the `PREROUTING Table`.
  - The request packet sent by Pod or Host Process using Host's Network Namespace is delivered to the `KUBE-SERVICES Table` by the `OUTPUT Table`. (same with iptable mode)

- `KUBE-SERVICES Table`
  
  - If the Dest IP and Dest Port of the request packet match the IP and Port of the ClusterIP Service, the request packet is delivered to the **`IPVS`.**
  
  - If the Dest IP of the request packet is Node's own IP, the request packet is delivered to the **`IPVS` via the `KUBE-NODE-PORT` Table.**

- `KUBE-NODEPORTS Table`

  - If the Dest Port of the request packet matches the Port of the NodePort Service, the request packet is delivered to the **`IPVS` via the `KUBE-NODE-PORT` Table.**
    - If the Default Rule of the `PREROUTING` and `OUTPUT` Table is Accept, the packet delivered to the service is delivered to the `IPVS` even without the `KUBE-SERVICES` Table, **so the service is not affected**.


- IPVS performs DNAT in the following situations with the port set by Load Balancing and Pod's IP and Service.
  - If the Dest IP, Dest Port in the request packet matches the Cluster-IP and Port in the service,
  - If the Dest IP of the request packet is Node's own IP and the Dest Port matches the NodePort of the NodePort Service,
  - If the Dest IP, Dest Port of the request packet matches the External IP and Port of the LoadBalancer Service,
  
- The request packet DNATed to Pod's IP is delivered to the Pod through a container network built through CNI Plugin. [IPVS List] shows that Load Balancing and DNAT are performed for all IPs associated with services.

- Like iptables, IPVS also uses TCP Connection information of Contrack of Linux Kernel. Therefore, **the response packet of the service packet** sent by DNAT due to the IPVS is SNATed again by the IPVS and delivered to the Pod or Host Process that requested the service.

- In IPVS Mode, like the iptables Mode, **hairpinning is applied to solve the SNAT problem in the service response packet.** In the `KUBE-POSTROUTING` Table, if the `KUBE-LOOP-BACK` IPset rule is met, Masquerade is performed.
  - It can be seen that the `KUBE-LOOP-BACK` IPset contains the **number of all cases where the Src IP and Dest IP of the packet can be IP of the same Pod**.

<details>
<summary>Chains</summary>
<div markdown="1">

---

**KUBE-SERVICES**

```bash
Chain KUBE-SERVICES (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-LOAD-BALANCER  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* Kubernetes service lb portal */ match-set KUBE-LOAD-BALANCER dst,dst
    0     0 KUBE-MARK-MASQ  all  --  *      *      !192.167.0.0/16       0.0.0.0/0            /* Kubernetes service cluster ip + port for masquerade purpose */ match-set KUBE-CLUSTER-IP dst,dst
    8   483 KUBE-NODE-PORT  all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
    0     0 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            match-set KUBE-CLUSTER-IP dst,dst
    0     0 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            match-set KUBE-LOAD-BALANCER dst,dst
```

---

**KUBE-NODE-PORT**

```bash
Chain KUBE-NODE-PORT (1 references)
 pkts bytes target     prot opt in     out     source               destination
    6   360 KUBE-MARK-MASQ  tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* Kubernetes nodeport TCP port for masquerade purpose */ match-set KUBE-NODE-PORT-TCP dst
```

---

**KUBE-LOAD-BALANCER**

```bash
Chain KUBE-LOAD-BALANCER (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-MARK-MASQ  all  --  *      *       0.0.0.0/0            0.0.0.0/0 
```

---

**KUBE-POSTROUTING**
  
```bash
Chain KUBE-POSTROUTING (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MASQUERADE  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service traffic requiring SNAT */ mark match 0x4000/0x4000
    1    60 MASQUERADE  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* Kubernetes endpoints dst ip:port, source ip for solving hairpinpurpose */ match-set KUBE-LOOP-BACK dst,dst,src
```

---

**KUBE-MARK-MASQ**
  
```bash
Chain KUBE-MARK-MASQ (3 references)
 pkts bytes target     prot opt in     out     source               destination         
    2   120 MARK       all  --  *      *       0.0.0.0/0            0.0.0.0/0            MARK or 0x4000
```

---

**IPVS List**
  
```bash
Name: KUBE-CLUSTER-IP
Type: hash:ip,port
Revision: 5
Header: family inet hashsize 1024 maxelem 65536
Size in memory: 600
References: 2
Number of entries: 1
Members:
10.96.98.173,tcp:80 
10.97.229.148,tcp:80
10.103.1.234,tcp:80 

Name: KUBE-LOOP-BACK
Type: hash:ip,port,ip
Revision: 5
Header: family inet hashsize 1024 maxelem 65536
Size in memory: 896
References: 1
Number of entries: 3
Members:
192.167.2.231,tcp:80,192.167.2.231
192.167.1.123,tcp:80,192.167.1.123
192.167.2.206,tcp:80,192.167.2.206

Name: KUBE-NODE-PORT-TCP
Type: bitmap:port
Revision: 3
Header: range 0-65535
Size in memory: 8268
References: 1
Number of entries: 2
Members:
30781
30915

Name: KUBE-LOAD-BALANCER
Type: hash:ip,port
Revision: 5
Header: family inet hashsize 1024 maxelem 65536
Size in memory: 152
References: 2
Number of entries: 1
Members:
172.35.0.200,tcp:80 
```

---

**IPset List**

```bash
TCP  172.35.0.100:30781 rr
  -> 192.167.1.123:80             Masq    1      0          0
  -> 192.167.2.206:80             Masq    1      0          0
  -> 192.167.2.231:80             Masq    1      0          0
TCP  172.35.0.100:30915 rr
  -> 192.167.1.123:80             Masq    1      0          0
  -> 192.167.2.206:80             Masq    1      0          0
  -> 192.167.2.231:80             Masq    1      0          0
TCP  172.35.0.200:80 rr
  -> 192.167.1.123:80             Masq    1      0          0
  -> 192.167.2.206:80             Masq    1      0          0
  -> 192.167.2.231:80             Masq    1      0          0    
TCP  10.96.98.173:80 rr
  -> 192.167.1.123:80             Masq    1      0          0
  -> 192.167.2.206:80             Masq    1      0          0
  -> 192.167.2.231:80             Masq    1      0          0
TCP  10.97.229.148:80 rr
  -> 192.167.1.123:80             Masq    1      0          0
  -> 192.167.2.206:80             Masq    1      0          0
  -> 192.167.2.231:80             Masq    1      0          0   
TCP  10.103.1.234:80 rr
  -> 192.167.1.123:80             Masq    1      0          0
  -> 192.167.2.206:80             Masq    1      0          0
  -> 192.167.2.231:80             Masq    1      0          0         
```
</div>
</details>

`ipvs mode` uses **[IPVS](../../../네트워크 Network/L2 internet layer/IPVS.md) for connection load balancing**. ipvs mode supports six load balancing modes, specified with `--ipvs-scheduler`:

- `rr`: Round-robin
- `lc`: Least connection
- `dh`: Destination hashing
- `sh`: Source hashing
- `sed`: Shortest expected delay
- `nq`: Never queue

Round-robin (`rr`) is the default load balancing mode. It is the closest analog to iptables mode’s behavior (in that connections are made fairly evenly regardless of pod state), though iptables mode does not actually perform round-robin routing.

### kernelspace Mode

`kernelspace` is the newest, Windows-only mode. It provides an alternative to `userspace` mode for Kubernetes on Windows, as `iptables` and `ipvs` are specific to Linux.

---
reference
- https://www.slideshare.net/Docker/deep-dive-in-container-service-discovery?from_action=save
- https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/
- https://ikcoo.tistory.com/130
- https://ssup2.github.io/theory_analysis/Kubernetes_Service_Proxy/