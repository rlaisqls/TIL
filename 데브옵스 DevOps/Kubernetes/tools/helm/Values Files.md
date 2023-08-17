# Values Files

Values is One of the built-in objects. This object provides access to values passed into the chart. Its contents come from multiple sources:

- The `values.yaml` file in the chart
- If this is a subchart, the `values.yaml` file of a parent chart
- A values file if passed into helm install or helm upgrade with the -f flag (`helm install -f myvals.yaml ./mychart`)
- Individual parameters passed with `--set` (such as `helm install --set foo=bar ./mychart`)


The list above is in order of specificity: `values.yaml` is the default, which can be overridden by a parent chart's `values.yaml`, which can in turn be overridden by a user-supplied values file, which can in turn be overridden by `--set` parameters.

Values files are plain YAML files. Let's edit `mychart/values.yaml` and then edit our ConfigMap template.

Removing the defaults in `values.yaml`, we'll set just one parameter:

```yml
favoriteDrink: coffee
```

Now we can use this inside of a template:

```yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  drink: {{ .Values.favoriteDrink }}
```

Notice on the last line we access favoriteDrink as an attribute of `Values: {{ .Values.favoriteDrink }}`.

Let's see how this renders.

```yml
$ helm install geared-marsupi ./mychart --dry-run --debug
install.go:158: [debug] Original chart version: ""
install.go:175: [debug] CHART PATH: /home/bagratte/src/playground/mychart

NAME: geared-marsupi
LAST DEPLOYED: Wed Feb 19 23:21:13 2020
NAMESPACE: default
STATUS: pending-install
REVISION: 1
TEST SUITE: None
USER-SUPPLIED VALUES:
{}

COMPUTED VALUES:
favoriteDrink: coffee

HOOKS:
MANIFEST:
---
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: geared-marsupi-configmap
data:
  myvalue: "Hello World"
  drink: coffee
```

Because favoriteDrink is set in the default values.yaml file to coffee, that's the value displayed in the template. We can easily override that by adding a `--set` flag in our call to helm install:

```yml
$ helm install solid-vulture ./mychart --dry-run --debug --set favoriteDrink=slurm
install.go:158: [debug] Original chart version: ""
install.go:175: [debug] CHART PATH: /home/bagratte/src/playground/mychart

NAME: solid-vulture
LAST DEPLOYED: Wed Feb 19 23:25:54 2020
NAMESPACE: default
STATUS: pending-install
REVISION: 1
TEST SUITE: None
USER-SUPPLIED VALUES:
favoriteDrink: slurm

COMPUTED VALUES:
favoriteDrink: slurm

HOOKS:
MANIFEST:
---
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: solid-vulture-configmap
data:
  myvalue: "Hello World"
  drink: slurm
```

Since `--set` has a higher precedence than the default values.yaml file, our template generates drink: slurm.

Values files can contain more structured content, too. For example, we could create a favorite section in our values.yaml file, and then add several keys there:

```yml
favorite:
  drink: coffee
  food: pizza
```
Now we would have to modify the template slightly:

```yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  drink: {{ .Values.favorite.drink }}
  food: {{ .Values.favorite.food }}
```

While structuring data this way is possible, the recommendation is that you keep your values trees shallow, favoring flatness. When we look at assigning values to subcharts, we'll see how values are named using a tree structure.

