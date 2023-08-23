```bash
istioctl proxy-status
NAME                                                         CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                     VERSION
argocd-application-controller-0.argocd                       Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-977466b69-2kms7     1.18.2
argocd-applicationset-controller-54c487f976-x6ws6.argocd     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-977466b69-2kms7     1.18.2
argocd-dex-server-69f7b8cbdf-w5qsp.argocd                    Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-977466b69-2kms7     1.18.2
argocd-notifications-controller-69897d947c-nw6sb.argocd      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-977466b69-2kms7     1.18.2
argocd-redis-696774879d-m7pgq.argocd                         Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-977466b69-2kms7     1.18.2
argocd-repo-server-644547fc8f-s7s2m.argocd                   Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-977466b69-2kms7     1.18.2
argocd-server-5476765b6f-ltnpx.argocd                        Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-977466b69-2kms7     1.18.2
istio-ingress-6f9c5dd58d-vmxgc.istio-ingress                 Kubernetes     SYNCED     SYNCED     SYNCED     NOT SENT     NOT SENT     istiod-977466b69-2kms7     1.18.2
istio-ingressgateway-559fb9c9d9-5b9ft.istio-system           Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-977466b69-2kms7     1.18.2
```

```bash
istioctl proxy-config cluster -n istio-system istio-ingressgateway-559fb9c9d9-5b9ft
SERVICE FQDN                                                  PORT      SUBSET     DIRECTION     TYPE           DESTINATION RULE
BlackHoleCluster                                              -         -          -             STATIC
agent                                                         -         -          -             STATIC
argocd-applicationset-controller.argocd.svc.cluster.local     7000      -          outbound      EDS
argocd-dex-server.argocd.svc.cluster.local                    5556      -          outbound      EDS
argocd-dex-server.argocd.svc.cluster.local                    5557      -          outbound      EDS
argocd-redis.argocd.svc.cluster.local                         6379      -          outbound      EDS
argocd-repo-server.argocd.svc.cluster.local                   8081      -          outbound      EDS
argocd-server.argocd.svc.cluster.local                        80        -          outbound      EDS
argocd-server.argocd.svc.cluster.local                        443       -          outbound      EDS
cert-manager-webhook.cert-manager.svc.cluster.local           443       -          outbound      EDS
cert-manager.cert-manager.svc.cluster.local                   9402      -          outbound      EDS
istio-ingress.istio-ingress.svc.cluster.local                 80        -          outbound      EDS
istio-ingress.istio-ingress.svc.cluster.local                 443       -          outbound      EDS
istio-ingress.istio-ingress.svc.cluster.local                 15021     -          outbound      EDS
istio-ingressgateway.istio-system.svc.cluster.local           80        -          outbound      EDS
istio-ingressgateway.istio-system.svc.cluster.local           443       -          outbound      EDS
istio-ingressgateway.istio-system.svc.cluster.local           15021     -          outbound      EDS
istiod.istio-system.svc.cluster.local                         443       -          outbound      EDS
istiod.istio-system.svc.cluster.local                         15010     -          outbound      EDS
istiod.istio-system.svc.cluster.local                         15012     -          outbound      EDS
istiod.istio-system.svc.cluster.local                         15014     -          outbound      EDS
jaeger-collector.istio-system.svc.cluster.local               9411      -          outbound      EDS
```


```bash
istioctl proxy-config endpoints argocd-server-5476765b6f-ltnpx -n argocd
ENDPOINT                                                STATUS      OUTLIER CHECK     CLUSTER
10.0.133.123:443                                        HEALTHY     OK                outbound|443||kubernetes.default.svc.cluster.local
10.0.134.30:9090                                        HEALTHY     OK                outbound|9090||kiali.istio-system.svc.cluster.local
10.0.134.30:20001                                       HEALTHY     OK                outbound|20001||kiali.istio-system.svc.cluster.local
10.0.135.53:9402                                        HEALTHY     OK                outbound|9402||cert-manager.cert-manager.svc.cluster.local
10.0.136.33:80                                          HEALTHY     OK                outbound|80||istio-ingress.istio-ingress.svc.cluster.local
10.0.136.33:443                                         HEALTHY     OK                outbound|443||istio-ingress.istio-ingress.svc.cluster.local
10.0.136.33:15021                                       HEALTHY     OK                outbound|15021||istio-ingress.istio-ingress.svc.cluster.local
10.0.138.249:10250                                      HEALTHY     OK                outbound|443||cert-manager-webhook.cert-manager.svc.cluster.local
...
```


```bash
istioctl proxy-config bootstrap -n istio-system istio-ingressgateway-559fb9c9d9-5b9ft
{
    "bootstrap": {
        "node": {
            "id": "router~10.0.140.150~istio-ingressgateway-559fb9c9d9-5b9ft.istio-system~istio-system.svc.cluster.local",
            "cluster": "istio-ingressgateway.istio-system",
            "metadata": {
                    "ANNOTATIONS": {
                                "istio.io/rev": "default",
                                "kubernetes.io/config.seen": "2023-07-27T05:11:03.687464259Z",
                                "kubernetes.io/config.source": "api",
                                "prometheus.io/path": "/stats/prometheus",
                                "prometheus.io/port": "15020",
                                "prometheus.io/scrape": "true",
                                "sidecar.istio.io/inject": "false"
                            },
                    "CLUSTER_ID": "Kubernetes",
                    "ENVOY_PROMETHEUS_PORT": 15090,
                    "ENVOY_STATUS_PORT": 15021,
                    "INSTANCE_IPS": "10.0.140.150",
                    "ISTIO_PROXY_SHA": "3c27a1b0cf381ca854ccc3a2034e88c206928da2",
                    "ISTIO_VERSION": "1.18.2",
                    "LABELS": {
                                "app": "istio-ingressgateway",
                                "chart": "gateways",
                                "heritage": "Tiller",
                                "install.operator.istio.io/owning-resource": "unknown",
                                "istio": "ingressgateway",
                                "istio.io/rev": "default",
                                "operator.istio.io/component": "IngressGateways",
                                "release": "istio",
                                "service.istio.io/canonical-name": "istio-ingressgateway",
                                ...
```

```yaml
istioctl x internal-debug configz
```

```bash
istioctl proxy-config listeners istio-ingressgateway-5dbdb957bc-5n67b -n istio-system --port 8080 -o json
```