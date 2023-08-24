# gateway log debug 하는 법

Debugging Istio Envoy filters can be challenging but there are several techniques and tools that can help you troubleshoot issues. Here's a step-by-step guide to debug Istio Envoy filters:

### 1. Enable Debug Logs:
By default, Istio's Envoy sidecar logs only contain essential information. To get more detailed logs, you can enable debug logging by changing the log level. To do this, you'll need to modify the istio-sidecar-injector ConfigMap. Add the following entry to the config section:

```yaml
data:
  log_level: "debug"
```

Then, restart the sidecar injection webhook and update your deployments to take effect.

### 2. Check Sidecar Logs:

After enabling debug logs, check the logs of the Envoy sidecar for the relevant service. You can use kubectl logs to view the sidecar logs. For example:

```bash
kubectl logs <pod_name> -c istio-proxy -n <namespace>
```

This will give you detailed logs of the Envoy proxy, including the execution of your custom Envoy filters.

Istio Proxy Dashboard: Istio provides a dashboard to monitor the Envoy proxy. You can access it by port-forwarding to the Istio proxy pod and then navigating to http://localhost:15000/ in your browser. The dashboard provides detailed information about the proxy configuration, listeners, filters, etc.

```bash
kubectl port-forward <istio-proxy-pod> -n <namespace> 15000:15000
```

Envoy Admin Interface: Envoy itself provides an admin interface that you can use to inspect the configuration and behavior of the proxy. By default, the admin interface is disabled, but you can enable it in the EnvoyFilter's config section:

```yaml
configPatches:
  - applyTo: NETWORK_FILTER
    match:
      context: SIDECAR_INBOUND
      listener:
        filterChain:
          filter:
            name: "envoy.http_connection_manager"
    patch:
      operation: MERGE
      value:
        config:
          admin:
            access_log_path: "/dev/null" # Disable access logs (optional)
            address:
              socket_address:
                address: 0.0.0.0
                port_value: 8001
```

After applying the EnvoyFilter, you can port-forward to the Envoy admin interface:

```bash
kubectl port-forward <istio-proxy-pod> -n <namespace> 8001:8001
```

Then, you can access the admin interface by navigating to http://localhost:8001/ in your browser.

### 3. Istio Proxy Logs in Debug Mode:

If you want to get even more detailed logs from the Istio proxy, you can set the log level to debug by modifying the Istio proxy pod directly:

```bash
kubectl edit pod <istio-proxy-pod> -n <namespace>
```

Find the line that starts with args and append `--log_output_level` default:debug to enable debug logging. Save and exit the editor. The Istio proxy will now produce more verbose logs.

### 4. Check the EnvoyFilter Configuration:

Double-check your EnvoyFilter configuration for any mistakes or typos. Incorrectly defined filters can cause issues, so make sure you review your configuration carefully.

### 5. Use istioctl to Analyze the Configuration:

Istio provides the istioctl command-line tool, which can be used to analyze and debug your Istio configuration. Use istioctl analyze to check for any issues in your configuration:

```bash
istioctl analyze
```

This command will check for potential problems in your configuration, including EnvoyFilter related issues.

Remember, debugging Envoy filters can be complex, so having a good understanding of the Istio documentation and Envoy's documentation will be beneficial. Additionally, you can use various debugging tools, such as Wireshark or tcpdump, to capture and analyze network traffic between services if necessary.

---

```bash
kubectl port-forward deployment/istio-ingressgateway -n istio-system 15000
curl -X POST "localhost:15000/logging?wasm=debug"
curl -X POST "localhost:15090/logging?filter=debug"
curl -X POST "localhost:15000/logging?main=debug"
curl -X POST "localhost:15000/logging?config=debug"
curl -X POST "localhost:15000/logging?client=debug"
kubectl logs -l app=istio-ingressgateway -n istio-system
```

curl -X POST "localhost:150090/logging?wasm=warning"
curl -X POST "localhost:15000/logging?filter=warning"
curl -X POST "localhost:15000/logging?main=warning"
curl -X POST "localhost:15000/logging?config=warning"
curl -X POST "localhost:15000/logging?client=warning"