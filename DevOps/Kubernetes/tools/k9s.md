```sh
# Use default kubeconfig
$ k9s

# Use non-default kubeconfig
$ k9s --kubeconfig /path/to/kubeconfig

# Use non-default context
$ k9s --context fooctx

# Readonly
$ k9s --readonly

# Check info (locations for configuration, logs, screen dumps)
$ k9s info
```

### List Resources

- List a specific resource:

        :<resource>: list Resources, e.g. :pod to list all pods.
        :<resource> <namespace>: list Resources in a given namespace.

- List all available resources / apis:

        :aliases or Ctrl-a: list all available aliases and resources.
        :crd: list all CRDs.
        :apiservices: list all API Services

- Filter

        /<filter>: regex filter.
        /!<filter>: inverse regex filter.
        /-l <label>: filter by labels.
        /-f <filter>: fuzzy match.

### Choose namespace

    - Type :namespace, select the desired namespace by up or down key, press Enter to select.

### Choose context

    :ctx: list ctx, then select from the list.
    :ctx <context>: swtich to the specified context.

### Show Decrypted Secrets

- Type `:secrets` to list the secrets, then

    x to decrypt the secret.
    Esc to leave the decrypted display.

### Key mapping

- move up and down without moving your right hand:
    - `j`: down.
    - `k`: up.
    - `h`: left
    - `l`: right
- `SPACE`: select multiple lines (e.g. then Ctrl-d to delete)
- `y`: yaml.
- `d`: describe.
- `v`: view.
- `e`: edit.
- `l`: logs.
- `w`: wrap.
- `r`: auto-refresh.
- `s`:
    - Deployment screen: scale the number of replicas.
    - Pod or Containers screen: shell
- `x`: decode a Secret.
- `f`: fullscreen. Tip: enter fullscreen mode before copying, to avoid | in copied text.
- `Ctrl-d`: delete.
- `Ctrl-k`: kill (no confirmation).
- `Ctrl-w`: toggle wide columns. (Equivalent to kubectl ... -o wide)
- `Ctrl-z`: toggle error state
- `Ctrl-e`: hide header.
- `Ctrl-s`: save output (e.g. the YAML) to disk.
- `Ctrl-l`: rollback.

### Sort

- `Shift-c`: sorts by CPU.
- `Shift-m`: sorts by MEMORY.
- `Shift-s`: sorts by STATUS.
- `Shift-p`: sorts by namespace.
- `Shift-n`: sorts by name.
- `Shift-o`: sorts by node.
- `Shift-i`: sorts by IP address.
- `Shift-a`: sorts by container age.
- `Shift-t`: sorts by number of restarts.
- `Shift-r`: sorts by pod readiness.

### Helm

    - :helm: show helm releases.
    - :helm NAMESPACE: show releases in a specific namespace.

### User

- There's no "user" object but in k9s you can see all the users by `:users`

### View

XRay View
- `:xray RESOURCE`, e.g. :xray deploy.

Pulse View

- `:pulse`: displays general information about the Kubernetes cluster.

Popeye View

- `:popeye or pop`: checks all resources for conformity with the correctness criteria and displays the resulting "rating" with explanations. https://popeyecli.io

### Show Disk Files

  - `:dir /path`

E.g. :dir /tmp will show your /tmp folder on local disk. One common use case: Ctrl-s to save a yaml, then find it in :dir /tmp/k9s-screens-root, find the file, press e to edit and a to apply.
Quit

  - `Esc`: Bails out of view/command/filter mode.
  - `:q or Ctrl-c`: quit k9s.

### Meaning of the Header

Most of the headers are easy to understand; some of the special ones:

  - `%CPU/R`: Percentage of requested CPU
  - `%CPU/L`: Percentage of limited CPU
  - `%MEM/R`: Percentage of requested memory
  - `%MEM/L`: Percentage of limited memory
  - `CPU/A`: allocatable CPU

Pods:

  - pf: PortForward

Containers:

  - PROBES(L:R): Liveness and Readiness probes

### Resource usage

Check CPU and MEM usage on the top left cornor of the screen;

Check usage in Node and Pod page;

This is equivalent to:

```
$ kubectl top nodes
$ kubectl top pods

$ kubectl top node <node_name>
```

### Customize

  - `$HOME/.k9s/views.yml`: customize the column view for resource lists.
  - `$HOME/.k9s/plugin.yml`: manage plugins.
  - `$XDG_CONFIG_HOME/k9s/config.yml`: k9s config.
  - `$XDG_CONFIG_HOME/k9s/alias.yml`: define your own alias.
  - `$XDG_CONFIG_HOME/k9s/hotkey.yml`: define your own hotkeys.
  - `$XDG_CONFIG_HOME/k9s/plugin.yml`: manage plugins.

### How to change log setting

Change `~/.config/k9s/config.yml`:

```
logger:
  tail: 500
  buffer: 5000
  sinceSeconds: -1
```

How to monitor what's going on:

  - :event (or :ev): see the stream of events.
  - :pod: see the list of pods Shift-a to sort by age.
  - :job: see the list of jobs, ordered by time by default.

### Benchmark

k9s includes a basic HTTP load generator.

To enable it, you have to configure port forwarding in the pod. Select the pod and press SHIFT + f, go to the port-forward menu (using the pf alias).

After selecting the port and hitting CTRL + b, the benchmark would start. Its results are saved in /tmp for subsequent analysis.

To change the configuration of the benchmark, create the `$HOME/.k9s/bench-<my_context>.yml` file (unique for each cluster).

### Plugins

https://github.com/derailed/k9s/tree/master/plugins

---
### Reference
- https://k9scli.io
- https://github.com/derailed/k9s

