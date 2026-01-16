
Argo CD allows us to integrate more config management tools using config management plugins. Most prominent inbuilt tools are helm and kustomize.

We have to option, when it comes to create our own Config Management Plugin (CMP):

> Add the plugin config to the main Argo CD ConfigMap. Our repo-server container will then run the plugin's commands.

There are two ways to install a Config Management Plugin:

- sidecar plugin
  - This is a good option for a more complex plugin that would clutter the Argo CD ConfigMap. A copy of the repository is sent to the sidecar container as a tarball and processed individually per application.

- ConfigMap plugin (this method is deprecated and will be removed in a future version)
  - The repo-server container will run your plugin's commands.

## Sidecar plugin
An operator can configure a plugin tool via a sidecar to repo-server. The following changes are required to configure a new plugin:

#### Write the plugin configuration file
Plugins will be configured via a ConfigManagementPlugin manifest located inside the plugin container.

```yml
apiVersion: argoproj.io/v1alpha1
kind: ConfigManagementPlugin
metadata:
  # The name of the plugin must be unique within a given Argo CD instance.
  name: my-plugin
spec:
  version: v1.0
  # The init command runs in the Application source directory at the beginning of each manifest generation. The init
  # command can output anything. A non-zero status code will fail manifest generation.
  init:
    # Init always happens immediately before generate, but its output is not treated as manifests.
    # This is a good place to, for example, download chart dependencies.
    command: [sh]
    args: [-c, 'echo "Initializing..."']
  # The generate command runs in the Application source directory each time manifests are generated. Standard output
  # must be ONLY valid YAML manifests. A non-zero exit code will fail manifest generation.
  # Error output will be sent to the UI, so avoid printing sensitive information (such as secrets).
  generate:
    command: [sh, -c]
    args:
      - |
        echo "{\"kind\": \"ConfigMap\", \"apiVersion\": \"v1\", \"metadata\": { \"name\": \"$ARGOCD_APP_NAME\", \"namespace\": \"$ARGOCD_APP_NAMESPACE\", \"annotations\": {\"Foo\": \"$ARGOCD_ENV_FOO\", \"KubeVersion\": \"$KUBE_VERSION\", \"KubeApiVersion\": \"$KUBE_API_VERSIONS\",\"Bar\": \"baz\"}}}"
  # The discovery config is applied to a repository. If every configured discovery tool matches, then the plugin may be
  # used to generate manifests for Applications using the repository. If the discovery config is omitted then the plugin 
  # will not match any application but can still be invoked explicitly by specifying the plugin name in the app spec. 
  # Only one of fileName, find.glob, or find.command should be specified. If multiple are specified then only the 
  # first (in that order) is evaluated.
  discover:
    # fileName is a glob pattern (https://pkg.go.dev/path/filepath#Glob) that is applied to the Application's source 
    # directory. If there is a match, this plugin may be used for the Application.
    fileName: "./subdir/s*.yaml"
    find:
      # This does the same thing as fileName, but it supports double-start (nested directory) glob patterns.
      glob: "**/Chart.yaml"
      # The find command runs in the repository's root directory. To match, it must exit with status code 0 _and_ 
      # produce non-empty output to standard out.
      command: [sh, -c, find . -name env.yaml]
  # The parameters config describes what parameters the UI should display for an Application. It is up to the user to
  # actually set parameters in the Application manifest (in spec.source.plugin.parameters). The announcements _only_
  # inform the "Parameters" tab in the App Details page of the UI.
  parameters:
    # Static parameter announcements are sent to the UI for _all_ Applications handled by this plugin.
    # Think of the `string`, `array`, and `map` values set here as "defaults". It is up to the plugin author to make 
    # sure that these default values actually reflect the plugin's behavior if the user doesn't explicitly set different
    # values for those parameters.
    static:
      - name: string-param
        title: Description of the string param
        tooltip: Tooltip shown when the user hovers the
        # If this field is set, the UI will indicate to the user that they must set the value.
        required: false
        # itemType tells the UI how to present the parameter's value (or, for arrays and maps, values). Default is
        # "string". Examples of other types which may be supported in the future are "boolean" or "number".
        # Even if the itemType is not "string", the parameter value from the Application spec will be sent to the plugin
        # as a string. It's up to the plugin to do the appropriate conversion.
        itemType: ""
        # collectionType describes what type of value this parameter accepts (string, array, or map) and allows the UI
        # to present a form to match that type. Default is "string". This field must be present for non-string types.
        # It will not be inferred from the presence of an `array` or `map` field.
        collectionType: ""
        # This field communicates the parameter's default value to the UI. Setting this field is optional.
        string: default-string-value
      # All the fields above besides "string" apply to both the array and map type parameter announcements.
      - name: array-param
        # This field communicates the parameter's default value to the UI. Setting this field is optional.
        array: [default, items]
        collectionType: array
      - name: map-param
        # This field communicates the parameter's default value to the UI. Setting this field is optional.
        map:
          some: value
        collectionType: map
    # Dynamic parameter announcements are announcements specific to an Application handled by this plugin. For example,
    # the values for a Helm chart's values.yaml file could be sent as parameter announcements.
    dynamic:
      # The command is run in an Application's source directory. Standard output must be JSON matching the schema of the
      # static parameter announcements list.
      command: [echo, '[{"name": "example-param", "string": "default-string-value"}]']

    # If set to then the plugin receives repository files with original file mode. Dangerous since the repository
    # might have executable files. Set to true only if you trust the CMP plugin authors.
    preserveFileMode: false
```

> While the ConfigManagementPlugin looks like a Kubernetes object, it is not actually a custom resource. It only follows kubernetes-style spec conventions.

The `generate` command must print a valid YAML stream to stdout. Both `init` and `generate` commands are executed inside the application source directory.

The `discover.fileName` is used as glob pattern to determine whether an application repository is supported by the plugin or not.

```yml
  discover:
    find:
      command: [sh, -c, find . -name env.yaml]
```

If `discover.fileName` is not provided, the `discover.find.command` is executed in order to determine whether an application repository is supported by the plugin or not.

The `find` command should return a non-error exit code and produce output to stdout when the application source type is supported.

#### Place the plugin configuration file in the sidecar

Argo CD expects the plugin configuration file to be located at `/home/argocd/cmp-server/config/plugin.yaml` in the sidecar.

If you use a custom image for the sidecar, you can add the file directly to that image.

```dockerfile
WORKDIR /home/argocd/cmp-server/config/
COPY plugin.yaml ./
```

If you use a stock image for the sidecar or would rather maintain the plugin configuration in a ConfigMap, just nest the plugin config file in a ConfigMap under the `plugin.yaml` key and mount the ConfigMap in the sidecar (see next section).

```yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-plugin-config
data:
  plugin.yaml: |
    apiVersion: argoproj.io/v1alpha1
    kind: ConfigManagementPlugin
    metadata:
      name: my-plugin
    spec:
      version: v1.0
      init:
        command: [sh, -c, 'echo "Initializing..."']
      generate:
        command: [sh, -c, 'echo "{\"kind\": \"ConfigMap\", \"apiVersion\": \"v1\", \"metadata\": { \"name\": \"$ARGOCD_APP_NAME\", \"namespace\": \"$ARGOCD_APP_NAMESPACE\", \"annotations\": {\"Foo\": \"$ARGOCD_ENV_FOO\", \"KubeVersion\": \"$KUBE_VERSION\", \"KubeApiVersion\": \"$KUBE_API_VERSIONS\",\"Bar\": \"baz\"}}}"']
      discover:
        fileName: "./subdir/s*.yaml"
```

#### Register the plugin sidecar

To install a plugin, patch argocd-repo-server to run the plugin container as a sidecar, with argocd-cmp-server as its entrypoint. You can use either off-the-shelf or custom-built plugin image as sidecar image. For example:

```yml
containers:
- name: my-plugin
  command: [/var/run/argocd/argocd-cmp-server] # Entrypoint should be Argo CD lightweight CMP server i.e. argocd-cmp-server
  image: busybox # This can be off-the-shelf or custom-built image
  securityContext:
    runAsNonRoot: true
    runAsUser: 999
  volumeMounts:
    - mountPath: /var/run/argocd
      name: var-files
    - mountPath: /home/argocd/cmp-server/plugins
      name: plugins
    # Remove this volumeMount if you've chosen to bake the config file into the sidecar image.
    - mountPath: /home/argocd/cmp-server/config/plugin.yaml
      subPath: plugin.yaml
      name: my-plugin-config
    # Starting with v2.4, do NOT mount the same tmp volume as the repo-server container. The filesystem separation helps 
    # mitigate path traversal attacks.
    - mountPath: /tmp
      name: cmp-tmp
volumes:
- configMap:
    name: my-plugin-config
  name: my-plugin-config
- emptyDir: {}
  name: cmp-tmp
```

## ConfigMap plugin

> ConfigMap plugins are deprecated and will no longer be supported in 2.7.

The following changes are required to configure a new plugin:

1. Make sure required binaries are available in argocd-repo-server pod. The binaries can be added via volume mounts or using a custom image (see custom_tools for examples of both).
2. Register a new plugin in argocd-cm ConfigMap:

```yml
data:
  configManagementPlugins: |
    - name: pluginName
      init:                          # Optional command to initialize application source directory
        command: ["sample command"]
        args: ["sample args"]
      generate:                      # Command to generate manifests YAML
        command: ["sample command"]
        args: ["sample args"]
      lockRepo: true                 # Defaults to false. See below.
```

The generate command must print a valid YAML or JSON stream to stdout. Both init and generate commands are executed inside the application source directory or in path when specified for the app.

Create an Application which uses your new CMP.

## Migrating from argocd-cm plugins

Installing plugins by modifying the argocd-cm ConfigMap is deprecated as of v2.4. Support will be completely removed in a future release.

To converting the ConfigMap entry into a config file, First, copy the plugin's configuration into its own YAML file. Take for example the following ConfigMap entry:

```yml
data:
  configManagementPlugins: |
    - name: pluginName
      init:                          # Optional command to initialize application source directory
        command: ["sample command"]
        args: ["sample args"]
      generate:                      # Command to generate manifests YAML
        command: ["sample command"]
        args: ["sample args"]
      lockRepo: true                 # Defaults to false. See below.
```

The `pluginName` item would be converted to a config file like this:

```yml
apiVersion: argoproj.io/v1alpha1
kind: ConfigManagementPlugin
metadata:
  name: pluginName
spec:
  init:                          # Optional command to initialize application source directory
    command: ["sample command"]
    args: ["sample args"]
  generate:                      # Command to generate manifests YAML
    command: ["sample command"]
    args: ["sample args"]
```

> The lockRepo key is not relevant for sidecar plugins, because sidecar plugins do not share a single source repo directory when generating manifests.

## Debugging a CMP

If you are actively developing a sidecar-installed CMP, keep a few things in mind:

1. If you are mounting plugin.yaml from a ConfigMap, you will have to restart the repo-server Pod so the plugin will pick up the changes.
2. If you have baked plugin.yaml into your image, you will have to build, push, and force a re-pull of that image on the repo-server Pod so the plugin will pick up the changes. If you are using `:latest`, the Pod will always pull the new image. If you're using a different, static tag, set `imagePullPolicy: Always` on the CMP's sidecar container.
3. CMP errors are cached by the repo-server in Redis. Restarting the repo-server Pod will not clear the cache. Always do a "Hard Refresh" when actively developing a CMP so you have the latest output.

---
referece
- https://blog.ediri.io/how-to-create-an-argo-cd-plugin
- https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/