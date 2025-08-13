
`kube-proxy`는 Kubernetes의 노드별 데몬이며, Service를 사용 가능한 네트워킹 규칙으로 변환하는 역할을 한다. 정확히는, Service에 따른 Endpoint들을 등록한다.

- Service는 Pod 집합에 대한 로드 밸런서를 정의한다.
- Endpoint(및 endpoint slice)는 준비된 Pod IP 목록을 나열한다. Service와 동일한 Pod 셀렉터를 사용하여 Service로부터 자동으로 생성된다.

대부분의 Service 유형은 **클러스터 외부에서 라우팅할 수 없는 cluster IP 주소라고 하는 Service용 IP 주소**를 가지고 있다.

`kube-proxy` is responsible for routing requests to a service’s cluster IP address to healthy pods. `kube-proxy` is by far the most common implementation for Kubernetes services, but there are alternatives to `kube-proxy`, such as a <u>replacement mode Cilium</u>.

kube-proxy는 런타임 모드와 정확한 기능 집합을 변경하는 네 가지 모드가 있다:

- `userspace`
- `iptables`
- `ipvs`
- `kernelspace`

You can specify the mode using `--proxy-mode <mode>`. It’s worth noting that all modes rely on iptables to some extent.

그리고 아래 명령으로 사용 중인 모드를 확인할 수 있다

```
kubectl logs -f [YOUR_POD_NAME] -n kube-system
```

## Service IP 동기화 타이밍

Service가 생성되거나 업데이트될 때, kube-proxy는 이러한 변경사항을 반영하기 위해 라우팅 룰(iptables, IPVS 등)을 업데이트해야 한다. 이 동기화 타이밍은 두 가지 주요 파라미터로 제어된다:

### minSyncPeriod

- iptables/IPVS 룰을 커널과 재동기화하는 시도 간의 최소 시간을 제어한다.
- 기본값: **1초**
- `0s`로 설정하면 kube-proxy는 모든 Service 또는 EndpointSlice 변경에 대해 즉시 룰을 동기화한다.
- 기본값인 `1s` 설정에서는 1초 내에 발생하는 여러 변경사항을 하나의 업데이트로 집계할 수 있어 계산 오버헤드를 줄인다.

### Watch API를 통한 이벤트 감지

kube-proxy는 Kubernetes Watch API를 통해 Service와 Endpoint 변경사항을 수신한다:

- **HTTP long-lived stream**을 사용하여 API 서버와 지속적인 연결을 유지한다.
- 이는 다른 Kubernetes 컴포넌트(Scheduler, Kubelet)가 Pod, ConfigMap/Secret, PVC 상태 변화를 감지하는 것과 동일한 메커니즘이다.
- [Kubernetes API Concepts - Efficient detection of changes](https://kubernetes.io/docs/reference/using-api/api-concepts/#efficient-detection-of-changes) 섹션에 문서화되어 있다.
- 지속적인 폴링 없이 리소스 변경에 대한 실시간 알림을 제공한다.

### syncPeriod

- 모든 룰의 전체 동기화를 수행하는 간격을 제어한다.
- 기본값: **30초**
- Service/EndpointSlice 변경과 직접적으로 관련되지 않은 추가 유지보수 작업을 처리한다.
- 개별 변경 이벤트가 누락되더라도 최종 일관성을 보장한다.

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

**userspace mode의 단점**

kube-proxy는 프로세스로 작동하므로 User Space 영역에 속한다. 그리고 호스트의 네트워킹을 담당하는 Netfilter는 Kernel 영역에 속한다.

본질적으로 User Space(프로세스)의 작동은 Kernel을 통해 이루어진다. User Space 프로그램은 프로세스가 계산을 위한 CPU 시간, I/O 작업을 위한 디스크, 메모리가 필요할 때 Kernel에 서비스를 요청하는 시스템을 가지고 있기 때문에 Kernel 자체 서비스보다 훨씬 느리다.

UserSpace Mode의 kube-proxy는 로드 밸런싱 및 패킷 규칙 설정과 같은 대부분의 네트워킹 작업이 주로 프로세스인 kube-proxy 자체에 의해 제어되기 때문에 UserSpace와 Kernel 간에 많은 액세스가 필요하다. 이러한 문제로 인해 UserSpace Mode의 kube-proxy는 네트워킹 속도가 느려지는 문제가 있다. 따라서 userspace 모드는 더 이상 일반적으로 사용되지 않으며, 명확한 이유가 없는 한 사용하지 않는 것이 좋다.

## iptables Mode

<img width="502" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/0457bc57-9a73-4eb9-97db-add61c012b83">

- 대부분의 Pod에서 전송되는 요청 패킷은 Pod의 veth를 통해 호스트의 네트워크 네임스페이스로 전달되므로, 요청 패킷은 `PREROUTING Table`에 의해 `KUBE-SERVICES Table`로 전달된다.
  - 호스트의 네트워크 네임스페이스를 사용하는 Pod 또는 호스트 프로세스에서 보낸 요청 패킷은 `OUTPUT Table`에 의해 `KUBE-SERVICES Table`로 전달된다.

- `KUBE-SERVICES Table`
  
  - 요청 패킷의 목적지 IP와 목적지 포트가 ClusterIP Service의 IP와 포트와 일치하면, 요청 패킷은 일치하는 ClusterIP Service의 NAT 테이블인 `KUBE-SVC-XXX Table`로 전달된다.
  
  - 요청 패킷의 목적지 IP가 노드 자체의 IP인 경우, 요청 패킷은 `KUBE-NODEPORTS Table`로 전달된다.

- `KUBE-NODEPORTS Table`

  - 요청 패킷의 목적지 포트가 NodePort Service의 포트와 일치하면, 요청 패킷은 NodePort Service의 NAT Table인 `KUBE-SVC-XXX Table`로 전달된다.

- `KUBE-SERVICES Table`

  - 요청 패킷의 목적지 IP와 목적지 포트가 Load Balancer Service의 External IP와 포트와 일치하면, 요청 패킷은 일치하는 Load Balancer Service의 NAT Table인 `KUBE-FW-XXX Table`로 전달되고, 그 다음 `KUBE-SVC-XXX Table`로 전달된다.

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

서비스 요청 패킷의 소스 IP는 유지되거나 Masquerade를 통해 호스트의 IP로 SNAT된다. **`KUBE-MARK-MASQ` Table은 요청 패킷의 Masquerade를 위해 패킷에 마킹을 수행하는 테이블이다.** 마킹된 패킷은 `KUBE-POSTROUTING` Table에서 Masquerade되고, 소스 IP는 호스트의 IP로 SNAT된다. iptables 테이블을 보면, Masquerade를 수행할 패킷이 `KUBE-MARK-MASQ` Table을 통해 마킹되는 것을 볼 수 있다.

`externalTrafficPolicy` 값이 Local로 설정되면, `KUBE-MARK-MASQ` Table에서 `KUBE-NODEPORTS` Table이 사라지고 Masquerade가 수행되지 않는다. 따라서 요청 패킷의 소스 IP는 그대로 유지된다. 또한, 요청 패킷은 호스트에서 로드 밸런싱되지 않고, 요청 패킷이 전달된 호스트에서 실행 중인 타겟 Pod에만 전달된다. 타겟 Pod가 없는 호스트로 요청 패킷이 전달되면, 요청 패킷은 드롭된다.

아래 그림의 왼쪽은 external Traffic Policy를 Local로 설정하여 Masquerade를 수행하지 않는 경우를 보여준다.

<img width="633" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/6315bc3b-0f79-4e9a-9b45-a7c4343d348e">

`ExternalTrafficPolicy` Local은 주로 `LoadBalancer` Service에서 사용된다. 이는 요청 패킷의 소스 IP를 유지할 수 있고, 클라우드 제공업체의 Load Balancer가 로드 밸런싱을 수행하므로 호스트의 로드 밸런싱 과정이 불필요하기 때문이다.

`externalTrafficPolicy` 값이 Local인 경우, 타겟 Pod가 없는 호스트에서 패킷이 드롭되므로, 클라우드 제공업체의 LoadBalancer가 수행하는 호스트 헬스 체크 과정에서 타겟 Pod가 없는 호스트는 로드 밸런싱 대상에서 제외된다. 따라서 클라우드 제공업체의 Load Balancer는 타겟 Pod가 있는 호스트에만 요청 패킷을 로드 밸런싱한다.

Pod에서 자신이 속한 서비스의 IP로 요청 패킷을 전송하여 요청 패킷이 자기 자신에게 반환되는 경우에도 Masquerade가 필요하다.

- 위 그림의 왼쪽은 이 경우를 보여준다. 요청 패킷이 DNAT되고, 패킷의 소스 IP와 목적지 IP 모두 Pod의 IP가 된다.
- 따라서 Pod에서 반환된 요청 패킷에 대한 응답 패킷을 보내면, 패킷이 호스트의 NAT Table을 거치지 않고 Pod에서 처리되기 때문에 SNAT이 수행되지 않는다.

- Masquerade는 **Pod에 반환된 요청 패킷을 호스트로 강제로 보내 SNAT을 수행할 수 있도록 한다**. 이렇게 의도적으로 패킷을 우회시켜 수신하는 기법을 **hairpinning**이라고 한다.
  - 위 그림의 오른쪽은 Masquerade를 사용한 hairpinning을 적용하는 경우를 보여준다.

- `KUBE-SEP-XXX` Table에서 요청 패킷의 소스 IP가 DNAT될 IP와 같은 경우, 즉 Pod가 Service로 보낸 패킷이 자기 자신에게 수신되는 경우, 요청 패킷은 `KUBE-MARK-MASQ` Table을 통해 마킹되고 `KUBE-POSTROUTING` Table에서 Masquerade된다.
- Pod가 수신한 패킷의 소스 IP가 호스트의 IP로 설정되므로, Pod의 응답은 호스트의 NAT Table로 전달되고, 그 다음 SNAT, DNAT되어 Pod로 전달된다.

## ipvs Mode

<img width="502" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/38220084-58e3-4c14-8878-a1470d8b1a54">

- 대부분의 Pod에서 전송되는 요청 패킷은 Pod의 veth를 통해 호스트의 네트워크 네임스페이스로 전달되므로, 요청 패킷은 `PREROUTING Table`에 의해 `KUBE-SERVICES Table`로 전달된다.
  - 호스트의 네트워크 네임스페이스를 사용하는 Pod 또는 호스트 프로세스에서 보낸 요청 패킷은 `OUTPUT Table`에 의해 `KUBE-SERVICES Table`로 전달된다. (iptable 모드와 동일)

- `KUBE-SERVICES Table`
  
  - If the Dest IP and Dest Port of the request packet match the IP and Port of the ClusterIP Service, the request packet is delivered to the **`IPVS`.**
  
  - If the Dest IP of the request packet is Node's own IP, the request packet is delivered to the **`IPVS` via the `KUBE-NODE-PORT` Table.**

- `KUBE-NODEPORTS Table`

  - If the Dest Port of the request packet matches the Port of the NodePort Service, the request packet is delivered to the **`IPVS` via the `KUBE-NODE-PORT` Table.**
    - `PREROUTING`과 `OUTPUT` Table의 기본 규칙이 Accept인 경우, 서비스로 전달된 패킷은 `KUBE-SERVICES` Table 없이도 `IPVS`로 전달되므로 **서비스는 영향을 받지 않는다**.

- IPVS는 로드 밸런싱으로 설정된 포트와 Pod의 IP 및 Service로 다음 상황에서 DNAT을 수행한다.
  - 요청 패킷의 목적지 IP, 목적지 포트가 서비스의 Cluster-IP 및 포트와 일치하는 경우,
  - 요청 패킷의 목적지 IP가 노드 자체의 IP이고 목적지 포트가 NodePort Service의 NodePort와 일치하는 경우,
  - 요청 패킷의 목적지 IP, 목적지 포트가 LoadBalancer Service의 External IP 및 포트와 일치하는 경우,
  
- Pod의 IP로 DNAT된 요청 패킷은 CNI Plugin을 통해 구축된 컨테이너 네트워크를 통해 Pod로 전달된다. [IPVS List]는 서비스와 관련된 모든 IP에 대해 로드 밸런싱과 DNAT이 수행됨을 보여준다.

- iptables와 마찬가지로 IPVS도 Linux Kernel의 Contrack의 TCP 연결 정보를 사용한다. 따라서 IPVS에 의한 DNAT으로 전송된 **서비스 패킷의 응답 패킷**은 IPVS에 의해 다시 SNAT되어 서비스를 요청한 Pod 또는 호스트 프로세스로 전달된다.

- IPVS Mode에서는 iptables Mode와 마찬가지로 **서비스 응답 패킷의 SNAT 문제를 해결하기 위해 hairpinning이 적용된다**. `KUBE-POSTROUTING` Table에서 `KUBE-LOOP-BACK` IPset 규칙에 부합하면 Masquerade가 수행된다.
  - `KUBE-LOOP-BACK` IPset에는 **패킷의 소스 IP와 목적지 IP가 동일한 Pod의 IP일 수 있는 모든 경우의 수**가 포함되어 있음을 알 수 있다.

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

Round-robin (`rr`)은 기본 로드 밸런싱 모드이다. It is the closest analog to iptables mode’s behavior (in that connections are made fairly evenly regardless of pod state), though iptables mode does not actually perform round-robin routing.

### kernelspace Mode

`kernelspace`는 가장 새로운 Windows 전용 모드이다. `iptables`와 `ipvs`는 Linux에 특화되어 있기 때문에 Windows의 Kubernetes에서 `userspace` 모드의 대안을 제공한다.

---
reference

- <https://www.slideshare.net/Docker/deep-dive-in-container-service-discovery?from_action=save>
- <https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/>
- <https://ikcoo.tistory.com/130>
- <https://ssup2.github.io/theory_analysis/Kubernetes_Service_Proxy/>

