
A dry run (or practice run) is a software testing process used to make sure that a system works correctly and will not result in severe failure.

Istio has a experimental annotation `istio.io/dry-run` to dry-run the policy without actually enforcing it.

The dry-run annotation allows you to better understand the effect of an authorization policy before applying it to the production traffic. This helps to reduce the risk of breaking the production traffic caused by an incorrect authorization policy.

### Before you begin

Before you begin this task, do the following:

- Deploy Zipkin for checking dry-run tracing results. Follow the Zipkin task to install Zipkin in the cluster.

- Deploy Prometheus for checking dry-run metric results. Follow the Prometheus task to install the Prometheus in the cluster.

- Deploy test workloads:

This task uses two workloads, `httpbin` and `sleep`, both deployed in namespace foo. Both workloads run with an Envoy proxy sidecar. Create the foo namespace and deploy the workloads with the following command:

```bash
$ kubectl create ns foo
$ kubectl label ns foo istio-injection=enabled
$ kubectl apply -f samples/httpbin/httpbin.yaml -n foo
$ kubectl apply -f samples/sleep/sleep.yaml -n foo
```

- Enable proxy debug level log for checking dry-run logging results:

```bash
$ istioctl proxy-config log deploy/httpbin.foo --level "rbac:debug" | grep rbac
rbac: debug
```

- Verify that `sleep` can access `httpbin` with the following command:

```bash
$ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
```

If you don’t see the expected output as you follow the task, retry after a few seconds. Caching and propagation overhead can cause some delay.

## Create dry-run policy

1. Create an authorization policy with dry-run annotation `"istio.io/dry-run": "true"` with the following command:

```bash
$ kubectl apply -n foo -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-path-headers
  annotations:
    "istio.io/dry-run": "true"
spec:
  selector:
    matchLabels:
      app: httpbin
  action: DENY
  rules:
  - to:
    - operation:
        paths: ["/headers"]
EOF
```

You can also use the following command to quickly change an existing authorization policy to dry-run mode:

```bash
$ kubectl annotate --overwrite authorizationpolicies deny-path-headers -n foo istio.io/dry-run='true'
```

2. Verify a request to path `/headers` is allowed because the policy is created in dry-run mode, run the following command to send 20 requests from `sleep` to `httpbin`, the request includes the header `X-B3-Sampled: 1` to always trigger the Zipkin tracing:

```bash
$ for i in {1..20}; do kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/headers -H "X-B3-Sampled: 1" -s -o /dev/null -w "%{http_code}\n"; done
200
200
200
...
```

### Check dry-run result in proxy log

The dry-run results can be found in the proxy debug log in the format of `shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]`. Run the following command to check the log:

```bash
$ kubectl logs "$(kubectl -n foo -l app=httpbin get pods -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo | grep "shadow denied"
2021-11-19T20:20:48.733099Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
2021-11-19T20:21:45.502199Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
2021-11-19T20:22:33.065348Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
...
```

Also see the [troubleshooting guide](https://istio.io/latest/docs/ops/common-problems/security-issues/#ensure-proxies-enforce-policies-correctly) for more details of the logging.

### Check dry-run result in metric using Prometheus

1. Open the Prometheus dashboard with the following command:

```bash
$ istioctl dashboard prometheus
```

2. In the Prometheus dashboard, search for the following metric:

```bash
envoy_http_inbound_0_0_0_0_80_rbac{authz_dry_run_action="deny",authz_dry_run_result="denied"}
```

3. Verify the queried metric result as follows:

```bash
envoy_http_inbound_0_0_0_0_80_rbac{app="httpbin",authz_dry_run_action="deny",authz_dry_run_result="denied",instance="10.44.1.11:15020",istio_io_rev="default",job="kubernetes-pods",kubernetes_namespace="foo",kubernetes_pod_name="httpbin-74fb669cc6-95qm8",pod_template_hash="74fb669cc6",security_istio_io_tlsMode="istio",service_istio_io_canonical_name="httpbin",service_istio_io_canonical_revision="v1",version="v1"}  20
```

4. The queried metric has value `20` (you might find a different value depending on how many requests you have sent. It’s expected as long as the value is greater than 0). This means the dry-run policy applied to the `httpbin` workload on port `80` matched one request. The policy would reject the request once if it was not in dry-run mode.

5. The following is a screenshot of the Prometheus dashboard:

![image](https://github.com/rlaisqls/TIL/assets/81006587/0656005b-de64-4648-973c-ed530c623251)

### Check dry-run result in tracing using Zipkin

1. Open the Zipkin dashboard with the following command:

```bash
$ istioctl dashboard zipkin
```

2. Find the trace result for the request from `sleep` to `httpbin`. Try to send some more requests if you do see the trace result due to the delay in the Zipkin.

3. In the trace result, you should find the following custom tags indicating the request is rejected by the dry-run policy deny-path-headers in the namespace foo:

```bash
istio.authorization.dry_run.deny_policy.name: ns[foo]-policy[deny-path-headers]-rule[0]
istio.authorization.dry_run.deny_policy.result: denied
```

4. The following is a screenshot of the Zipkin dashboard:

![image](https://github.com/rlaisqls/TIL/assets/81006587/98334483-1629-4590-bfaa-d38591ad4d4c)

## Summary

The Proxy debug log, Prometheus metric and Zipkin trace results indicate that the dry-run policy will reject the request. You can further change the policy if the dry-run result is not expected.

It’s recommended to keep the dry-run policy for some additional time so that it can be tested with more production traffic.

When you are confident about the dry-run result, you can disable the dry-run mode so that the policy will start to actually reject requests. This can be achieved by either of the following approaches:

- Remove the dry-run annotation completely; or
- Change the value of the dry-run annotation to `false`.

## Limitations

The dry-run annotation is currently in experimental stage and has the following limitations:

- The dry-run annotation currently only supports ALLOW and DENY policies;

- There will be two separate dry-run results (i.e. log, metric and tracing tag) for ALLOW and DENY policies due to the fact that the ALLOW and DENY policies are enforced separately in the proxy. You should take all the two dry-run results into consideration because a request could be allowed by an ALLOW policy but still rejected by another DENY policy;

- The dry-run results in the proxy log, metric and tracing are for manual troubleshooting purposes and should not be used as an API because it may change anytime without prior notice.

## Clean up

1. Remove the namespace foo from your configuration:

```bash
$ kubectl delete namespace foo
```

2. Remove Prometheus and Zipkin if no longer needed.

