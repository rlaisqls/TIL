
Session Affinity(세션 어피니티)는 특정 클라이언트의 요청이 항상 동일한 Pod로 라우팅되도록 하는 Kubernetes Service의 기능이다. "Sticky Session"이라고도 불리며, 상태를 유지하는 애플리케이션에서 세션 일관성을 보장하기 위해 사용한다.

## 기본 개념

기본적으로 Kubernetes Service는 요청을 모든 엔드포인트에 무작위로 분산한다. 이는 stateless 애플리케이션에는 문제가 없지만, 세션 상태를 메모리에 저장하는 애플리케이션에서는 문제가 된다.

```
┌──────────┐     ┌─────────────┐     ┌─────────┐
│          │ ──▶ │             │ ──▶ │  Pod A  │  요청 1: 로그인 (세션 생성)
│          │     │             │     └─────────┘
│  Client  │     │   Service   │
│          │     │             │     ┌─────────┐
│          │ ──▶ │             │ ──▶ │  Pod B  │  요청 2: 장바구니 조회 (세션 없음!)
└──────────┘     └─────────────┘     └─────────┘
```

위 상황에서 클라이언트가 Pod A에서 로그인했지만, 다음 요청이 Pod B로 라우팅되면 세션 정보가 없어 다시 로그인해야 한다.

Session Affinity를 활성화하면 같은 클라이언트의 요청은 항상 같은 Pod로 라우팅된다.

```
┌──────────┐     ┌─────────────┐     ┌─────────┐
│          │ ──▶ │             │ ──▶ │  Pod A  │  요청 1: 로그인
│          │     │             │     │         │
│  Client  │     │   Service   │     │         │
│          │     │             │     │         │
│          │ ──▶ │             │ ──▶ │  Pod A  │  요청 2: 장바구니 조회 (세션 유지!)
└──────────┘     └─────────────┘     └─────────┘
```

## 설정 방법

Service 스펙에서 `sessionAffinity` 필드를 설정한다.

```yaml

apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 8080
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
            


```

### sessionAffinity 옵션

- **None**: 기본값. Session Affinity를 사용하지 않는다.
- **ClientIP**: 클라이언트 IP 주소를 기반으로 동일한 Pod로 라우팅한다.

### timeoutSeconds

`sessionAffinityConfig.clientIP.timeoutSeconds`는 세션 어피니티가 유지되는 시간(초)이다.

- 기본값: 10800초 (3시간)
- 최대값: 86400초 (24시간)
- 이 시간이 지나면 클라이언트는 다른 Pod로 라우팅될 수 있다

## 동작 원리

Session Affinity 구현은 kube-proxy가 핵심 역할을 담당하며, 모드에 따라 구현 방식이 다르다.

### iptables 모드

> 참고: [Virtual IPs and Service Proxies](https://kubernetes.io/docs/reference/networking/virtual-ips/#proxy-mode-iptables)

iptables 모드에서는 `recent` 모듈을 사용한다. 이 모듈은 커널 메모리에 IP 주소 목록을 유지하면서, 최근에 본 IP인지 확인하고 타임스탬프를 기록한다.

**규칙 체인 흐름**

Service에 3개의 Pod가 있다고 가정하면, kube-proxy는 다음과 같은 iptables 규칙을 생성한다:

```
┌─────────────────────────────────────────────────────────────────┐
│                    KUBE-SERVICES 체인                            │
│  → KUBE-SVC-XXXX (my-service의 ClusterIP 매칭)                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    KUBE-SVC-XXXX 체인                            │
│  1. recent 모듈로 이미 매핑된 클라이언트인지 확인                   │
│     → KUBE-SEP-AAA (Pod A) 테이블에 있으면 → KUBE-SEP-AAA로       │
│     → KUBE-SEP-BBB (Pod B) 테이블에 있으면 → KUBE-SEP-BBB로       │
│     → KUBE-SEP-CCC (Pod C) 테이블에 있으면 → KUBE-SEP-CCC로       │
│  2. 없으면 확률적 분산 (statistic 모듈)                           │
│     → 33% 확률로 KUBE-SEP-AAA                                    │
│     → 50% 확률로 KUBE-SEP-BBB (남은 것 중)                        │
│     → 나머지는 KUBE-SEP-CCC                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    KUBE-SEP-AAA 체인                             │
│  1. recent --set: 클라이언트 IP를 이 테이블에 기록                 │
│  2. DNAT: 목적지를 Pod A IP로 변환                                │
└─────────────────────────────────────────────────────────────────┘
```

**실제 iptables 규칙**

```bash
# 1. 이미 매핑된 클라이언트인지 확인 (recent --rcheck)
-A KUBE-SVC-XXXX -m recent --rcheck --seconds 10800 --reap \
  --name KUBE-SEP-AAA --mask 255.255.255.255 --rsource \
  -j KUBE-SEP-AAA

# 2. 새 클라이언트는 확률적으로 분산
-A KUBE-SVC-XXXX -m statistic --mode random --probability 0.33333 \
  -j KUBE-SEP-AAA
-A KUBE-SVC-XXXX -m statistic --mode random --probability 0.50000 \
  -j KUBE-SEP-BBB
-A KUBE-SVC-XXXX -j KUBE-SEP-CCC

# 3. SEP 체인에서 클라이언트 IP 기록 후 DNAT
-A KUBE-SEP-AAA -m recent --set --name KUBE-SEP-AAA \
  --mask 255.255.255.255 --rsource
-A KUBE-SEP-AAA -p tcp -j DNAT --to-destination 10.0.0.5:8080
```

**recent 모듈의 동작**

recent 모듈은 `/proc/net/xt_recent/` 디렉토리에 각 테이블별 파일을 생성한다:

```bash
$ cat /proc/net/xt_recent/KUBE-SEP-AAA
src=192.168.1.100 ttl: 64 last_seen: 4295806123 oldest_pkt: 1 ...
src=192.168.1.101 ttl: 64 last_seen: 4295805000 oldest_pkt: 1 ...
```

각 엔트리에는 클라이언트 IP와 마지막으로 본 시간(jiffies)이 기록된다. `--seconds 10800`은 3시간이 지난 엔트리를 무시하고, `--reap`은 오래된 엔트리를 정리한다.

**한계점**

recent 모듈은 기본적으로 테이블당 100개의 IP만 저장할 수 있다. 이 값은 커널 모듈 파라미터로 조절 가능하다:

```bash
# 현재 설정 확인
cat /sys/module/xt_recent/parameters/ip_list_tot

# 변경 (모듈 로드 시)
modprobe xt_recent ip_list_tot=1000
```

### IPVS 모드

> 참고: [IPVS-Based In-Cluster Load Balancing Deep Dive](https://kubernetes.io/blog/2018/07/09/ipvs-based-in-cluster-load-balancing-deep-dive/)

IPVS(IP Virtual Server)는 Linux 커널의 L4 로드밸런서로, Session Affinity를 "Persistence"라는 이름으로 네이티브 지원한다.

**Persistence 메커니즘**

IPVS는 커널 내에 connection table을 유지한다. 새 연결이 들어오면:

```
┌─────────────────────────────────────────────────────────────────┐
│                     IPVS Connection Table                        │
│  ┌─────────────┬──────────────┬─────────────┬─────────────────┐ │
│  │ Client IP   │ Virtual IP   │ Real Server │ Timeout         │ │
│  ├─────────────┼──────────────┼─────────────┼─────────────────┤ │
│  │ 192.168.1.1 │ 10.96.0.100  │ 10.0.0.5    │ 10800s          │ │
│  │ 192.168.1.2 │ 10.96.0.100  │ 10.0.0.6    │ 10800s          │ │
│  │ 192.168.1.3 │ 10.96.0.100  │ 10.0.0.5    │ 10800s          │ │
│  └─────────────┴──────────────┴─────────────┴─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

1. 클라이언트 IP로 테이블 조회
2. 매핑이 있으면 해당 Real Server로 전달
3. 없으면 스케줄러(rr, lc, sh 등)로 서버 선택 후 테이블에 기록

**ipvsadm으로 확인**

```bash
# Virtual Service 목록 (persistence timeout 확인)
$ ipvsadm -Ln
IP Virtual Server version 1.2.1
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  10.96.0.100:80 rr persistent 10800
  -> 10.0.0.5:8080                Masq    1      3          0
  -> 10.0.0.6:8080                Masq    1      2          0
  -> 10.0.0.7:8080                Masq    1      1          0

# 현재 connection table
$ ipvsadm -Lnc
IPVS connection entries
pro expire state       source             virtual            destination
TCP 02:59:45 NONE      192.168.1.100:0    10.96.0.100:80     10.0.0.5:8080
TCP 02:58:30 NONE      192.168.1.101:0    10.96.0.100:80     10.0.0.6:8080
```

`persistent 10800`이 Session Affinity timeout이다. `expire` 컬럼은 남은 시간을 보여준다.

**Persistence Granularity**

IPVS는 netmask로 persistence 범위를 조절할 수 있다. kube-proxy는 기본적으로 `/32`(단일 IP)를 사용하지만, 같은 서브넷의 클라이언트를 묶고 싶다면 조절할 수 있다:

```bash
# /24 서브넷 단위로 같은 서버 할당
ipvsadm -A -t 10.96.0.100:80 -s rr -p 10800 -M 255.255.255.0
```

비교

| 항목 | iptables (recent) | IPVS |
|------|-------------------|------|
| 저장 위치 | 커널 해시 테이블 | 커널 connection table |
| 기본 엔트리 제한 | 100개/테이블 | 제한 없음 (메모리 한도) |
| 조회 성능 | O(n) 선형 검색 | O(1) 해시 조회 |
| 대규모 클러스터 | 성능 저하 가능 | 권장 |
| 모니터링 | /proc/net/xt_recent/* | ipvsadm -Lnc |

### nftables 모드

> 참고: [NFTables mode for kube-proxy](https://kubernetes.io/blog/2025/02/28/nftables-kube-proxy/)

Kubernetes 1.29부터 nftables 기반 kube-proxy가 도입되었다. nftables에서는 `meter` (이전 이름: `set`)를 사용하여 Session Affinity를 구현한다:

```
table ip kube-proxy {
    set affinity-my-service {
        type ipv4_addr
        timeout 3h
        flags dynamic
    }

    chain service-my-service {
        ip saddr @affinity-my-service goto endpoint-pod-a
        # 새 클라이언트는 확률 분산 후 set에 추가
        numgen random mod 3 vmap {
            0 : goto endpoint-pod-a,
            1 : goto endpoint-pod-b,
            2 : goto endpoint-pod-c
        }
    }

    chain endpoint-pod-a {
        update @affinity-my-service { ip saddr timeout 3h }
        dnat to 10.0.0.5:8080
    }
}
```

nftables는 iptables보다 효율적인 자료구조를 사용하고, timeout 기반 자동 정리가 내장되어 있다.

## NodePort와 LoadBalancer에서의 동작

ClusterIP가 아닌 NodePort나 LoadBalancer 타입에서는 Session Affinity가 조금 다르게 동작한다. 핵심은 **kube-proxy가 보는 클라이언트 IP가 무엇이냐**이다.

### externalTrafficPolicy의 영향

`externalTrafficPolicy`는 외부 트래픽이 들어올 때 클라이언트 IP를 어떻게 처리할지 결정한다.

**externalTrafficPolicy: Cluster (기본값)**

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌─────────┐
│  Client  │────▶│  Node A  │────▶│  Node B  │────▶│  Pod    │
│ 1.2.3.4  │     │ (NodePort)│     │  (SNAT)  │     │         │
└──────────┘     └──────────┘     └──────────┘     └─────────┘
                                        │
                                        ▼
                               Source IP가 Node A IP로 변경됨
```

트래픽이 다른 노드의 Pod로 전달될 때 SNAT(Source NAT)이 발생한다. kube-proxy는 클라이언트의 원래 IP(1.2.3.4)가 아니라 Node A의 IP를 보게 된다.

이 경우 Session Affinity가 클라이언트 단위가 아니라 **노드 단위**로 동작한다:

```
클라이언트 A (1.1.1.1) ──▶ Node 1 ──┬──▶ Pod-X
클라이언트 B (2.2.2.2) ──▶ Node 1 ──┘    (둘 다 Source IP가 Node 1 IP로 보임)

클라이언트 A (1.1.1.1) ──▶ Node 2 ──────▶ Pod-Y  ← 같은 클라이언트인데 다른 Pod!
```

- 같은 노드로 들어온 다른 클라이언트들이 같은 Pod로 몰린다
- 같은 클라이언트가 다른 노드로 들어오면 다른 Pod로 라우팅된다

**externalTrafficPolicy: Local**

```
┌──────────┐     ┌──────────┐     ┌─────────┐
│  Client  │────▶│  Node A  │────▶│  Pod    │  (같은 노드의 Pod로만 전달)
│ 1.2.3.4  │     │ (NodePort)│     │         │
└──────────┘     └──────────┘     └─────────┘
                                       │
                                       ▼
                              Source IP 보존됨 (1.2.3.4)
```

트래픽을 받은 노드에 있는 Pod로만 전달한다. SNAT이 발생하지 않으므로 클라이언트 원본 IP가 보존된다.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: NodePort
  externalTrafficPolicy: Local
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
  ports:
    - port: 80
      nodePort: 30080
```

다만 `Local` 정책은 해당 노드에 Pod가 없으면 트래픽을 drop한다. 따라서 로드밸런서의 헬스체크와 함께 사용해야 한다.

### LoadBalancer 타입

LoadBalancer 타입은 클라우드 로드밸런서가 앞단에 위치한다. 여기서 두 가지 레이어의 Session Affinity를 고려해야 한다:

```
┌──────────┐     ┌──────────────┐     ┌──────────┐     ┌─────────┐
│  Client  │────▶│  Cloud LB    │────▶│   Node   │────▶│   Pod   │
│          │     │              │     │          │     │         │
└──────────┘     └──────────────┘     └──────────┘     └─────────┘
                  ▲                    ▲
                  │                    │
            LB 레벨 Affinity      K8s 레벨 Affinity
            (어느 노드로?)         (어느 Pod로?)
```

일부 클라우드 LB는 백엔드로 트래픽을 전달할 때 Source IP를 LB 자신의 IP로 바꾼다. 이 경우 모든 클라이언트가 같은 IP로 보이므로 Kubernetes의 Session Affinity가 무용지물이 된다.

**해결책 1: Proxy Protocol 사용**

AWS NLB 등에서 Proxy Protocol을 활성화하면 원본 클라이언트 IP를 별도 헤더로 전달한다. 다만 이건 L4에서 동작하므로 애플리케이션이나 Ingress Controller가 파싱해야 한다.

**해결책 2: externalTrafficPolicy: Local + LB 헬스체크**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    # AWS NLB 예시
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  sessionAffinity: ClientIP
  ports:
    - port: 80
```

`Local` 정책을 사용하면 클라이언트 IP가 보존된다. 클라우드 LB는 자동으로 Pod가 있는 노드만 healthy로 인식한다.

**해결책 3: 클라우드 LB의 Sticky Session 사용**

클라우드 LB 자체의 Session Affinity 기능을 사용할 수도 있다:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    # AWS ALB 예시 (Ingress Controller 사용 시)
    alb.ingress.kubernetes.io/target-group-attributes: stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=3600
```

이 경우 LB가 같은 클라이언트를 같은 노드로 보내고, Kubernetes Session Affinity가 같은 Pod로 보낸다. 두 레이어가 협력하는 구조다.

### NodePort + 외부 LB 조합

클라우드가 아닌 환경에서 외부 LB(HAProxy, NGINX 등)를 사용할 때:

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌─────────┐
│  Client  │────▶│ HAProxy  │────▶│   Node   │────▶│   Pod   │
│ 1.2.3.4  │     │          │     │ :30080   │     │         │
└──────────┘     └──────────┘     └──────────┘     └─────────┘
```

**HAProxy 설정 예시**

```
backend k8s-nodeport
    balance roundrobin
    option forwardfor        # X-Forwarded-For 헤더 추가
    stick-table type ip size 100k expire 3h
    stick on src             # 클라이언트 IP 기반 sticky
    server node1 192.168.1.10:30080 check
    server node2 192.168.1.11:30080 check
```

HAProxy가 같은 클라이언트를 같은 노드로 보내도록 설정하고, Kubernetes Session Affinity가 같은 Pod로 보내도록 한다.

### 정리

| Service 타입 | externalTrafficPolicy | 클라이언트 IP 보존 | Session Affinity 동작 |
|-------------|----------------------|------------------|---------------------|
| ClusterIP | - | 항상 보존 | 클라이언트 단위 |
| NodePort | Cluster | SNAT 발생 | 노드 단위 (의도와 다름) |
| NodePort | Local | 보존 | 클라이언트 단위 |
| LoadBalancer | Cluster | SNAT 발생 | 노드 단위 (의도와 다름) |
| LoadBalancer | Local | 보존 | 클라이언트 단위 |

외부에서 접근하는 트래픽에 Session Affinity를 적용하려면 `externalTrafficPolicy: Local`을 함께 설정해야 한다.

## 사용 사례

Session Affinity가 필요한 경우:

**인메모리 세션 저장**

세션을 Redis나 외부 저장소가 아닌 애플리케이션 메모리에 저장하는 경우. 이 경우 세션 데이터에 접근하려면 항상 같은 Pod로 요청이 가야 한다.

**WebSocket 연결**

WebSocket은 한 번 연결되면 지속적인 연결을 유지해야 한다. Session Affinity를 통해 WebSocket 핸드셰이크와 이후 통신이 같은 Pod에서 처리되도록 할 수 있다.

**파일 업로드 청크**

대용량 파일을 여러 청크로 나눠 업로드할 때, 모든 청크가 같은 Pod로 가야 파일 조합이 가능하다.

## 주의사항

Session Affinity를 사용할 때 알아야 할 제한 사항들이 있다.

**NAT 환경에서의 문제**

여러 클라이언트가 같은 NAT 게이트웨이를 통해 접근하면, 모든 요청이 같은 Pod로 몰린다. 이는 부하 분산 효과를 떨어뜨린다.

```
┌───────────┐
│ Client A  │──┐
└───────────┘  │    ┌─────────┐     ┌─────────────┐     ┌─────────┐
               ├───▶│   NAT   │────▶│   Service   │────▶│  Pod A  │ (모든 요청 집중)
┌───────────┐  │    │ Gateway │     └─────────────┘     └─────────┘
│ Client B  │──┘    └─────────┘
└───────────┘                                           ┌─────────┐
                                                        │  Pod B  │ (요청 없음)
                                                        └─────────┘
```

**Pod 재시작 시 세션 손실**

Pod가 재시작되거나 스케일 다운으로 삭제되면, 해당 Pod에 고정되어 있던 클라이언트의 세션이 손실된다.

**Headless Service 미지원**

ClusterIP가 None인 Headless Service에서는 Session Affinity가 동작하지 않는다. DNS 기반 서비스 디스커버리를 사용하기 때문이다.

**HTTP 헤더 기반 어피니티 미지원**

Kubernetes 네이티브 Service는 클라이언트 IP 기반 어피니티만 지원한다. 쿠키나 HTTP 헤더 기반 어피니티가 필요하면 Ingress Controller(NGINX, Traefik 등)나 Service Mesh를 사용해야 한다.

## Ingress에서의 Session Affinity

더 세밀한 Session Affinity가 필요하면 Ingress Controller를 활용할 수 있다.

### NGINX Ingress Controller

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/affinity-mode: "persistent"
    nginx.ingress.kubernetes.io/session-cookie-name: "SERVERID"
    nginx.ingress.kubernetes.io/session-cookie-expires: "172800"
    nginx.ingress.kubernetes.io/session-cookie-max-age: "172800"
spec:
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80
```

이 방식은 쿠키 기반 어피니티를 제공하므로 NAT 환경에서도 각 클라이언트를 개별적으로 식별할 수 있다.

## 정리

Session Affinity는:

- 동일 클라이언트의 요청을 항상 같은 Pod로 라우팅한다
- ClientIP 기반으로 동작하며, timeout을 설정할 수 있다
- 인메모리 세션, WebSocket 등 상태 유지가 필요한 경우에 유용하다

하지만 NAT 환경에서의 부하 집중, Pod 삭제 시 세션 손실 등의 제한이 있으므로, 가능하면 외부 세션 저장소(Redis 등)를 사용하여 stateless 아키텍처를 유지하는 것이 권장된다.

---
참고

- <https://kubernetes.io/docs/reference/networking/virtual-ips/#session-affinity>
- <https://kubernetes.io/docs/concepts/services-networking/service/>
- <https://kubernetes.io/docs/tutorials/services/source-ip/> - externalTrafficPolicy에 따른 Source IP 보존
- <https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/>
- <https://kubernetes.io/blog/2018/07/09/ipvs-based-in-cluster-load-balancing-deep-dive/> - IPVS 모드 상세
- <https://kubernetes.io/blog/2025/02/28/nftables-kube-proxy/> - nftables 모드
- <https://kubernetes.io/blog/2022/12/30/advancements-in-kubernetes-traffic-engineering/>
