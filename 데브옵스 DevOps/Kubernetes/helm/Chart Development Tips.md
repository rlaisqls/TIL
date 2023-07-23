# Chart Development Tips

## Template Functions

Helm uses Go templates for templating your resource files. While Go ships several built-in functions, we have added many others.

First, we added all of the functions in the Sprig library, except env and expandenv, for security reasons.

We also added two special template functions: include and required. The include function allows you to bring in another template, and then pass the results to other template functions.

For example, this template snippet includes a template called mytpl, then lowercases the result, then wraps that in double quotes.

```yml
value: {{ include "mytpl" . | lower | quote }}
```

The required function allows you to declare a particular values entry as required for template rendering. If the value is empty, the template rendering will fail with a user submitted error message.

The following example of the required function declares an entry for .Values.who is required, and will print an error message when that entry is missing:

```yml
value: {{ required "A valid .Values.who entry required!" .Values.who }}
```

## include Function

Go provides a way of including one template in another using a built-in `template` directive. However, the built-in function cannot be used in Go template pipelines.

To make it possible to include a template, and then perform an operation on that template's output, Helm has a special `include` function:

```yml
{{ include "toYaml" $value | indent 2 }}
```

The above includes a template called `toYaml`, passes it `$value`, and then passes the output of that template to the `indent` function.

Because YAML ascribes significance to indentation levels and whitespace, this is one great way to include snippets of code, but handle indentation in a relevant context.

## required function

Go provides a way for setting template options to control behavior when a map is indexed with a key that's not present in the map. This is typically set with `template.Options("missingkey=option")`, where `option` can be `default`, `zero`, or `error`. While setting this option to error will stop execution with an error, this would apply to every missing key in the map. There may be situations where a chart developer wants to enforce this behavior for select values in the `values.yaml` file.

The required function gives developers the ability to declare a value entry as required for template rendering. If the entry is empty in `values.yaml`, the template will not render and will return an error message supplied by the developer.

For example:

```yml
{{ required "A valid foo is required!" .Values.foo }}
```

The above will render the template when `.Values.foo` is defined, but will fail to render and exit when `.Values.foo` is undefined.

## tpl Function

The tpl function allows developers to evaluate strings as templates inside a template. This is useful to pass a template string as a value to a chart or render external configuration files. Syntax: {{ tpl TEMPLATE_STRING VALUES }}

Examples:

```yml
# values
template: "{{ .Values.name }}"
name: "Tom"

# template
{{ tpl .Values.template . }}

# output
Tom
```

Rendering an external configuration file:

```yml
# external configuration file conf/app.conf
firstName={{ .Values.firstName }}
lastName={{ .Values.lastName }}

# values
firstName: Peter
lastName: Parker

# template
{{ tpl (.Files.Get "conf/app.conf") . }}

# output
firstName=Peter
lastName=Parker
```

### Creating Image Pull Secrets

Image pull secrets are essentially a combination of registry, username, and password. You may need them in an application you are deploying, but to create them requires running `base64` a couple of times. We can write a helper template to compose the Docker configuration file for use as the Secret's payload. Here is an example:

First, assume that the credentials are defined in the `values.yaml` file like so:

```yml
imageCredentials:
  registry: quay.io
  username: someone
  password: sillyness
  email: someone@host.com
```

We then define our helper template as follows:

```yml
{{- define "imagePullSecret" }}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}
```

Finally, we use the helper template in a larger template to create the Secret manifest:

```yml
apiVersion: v1
kind: Secret
metadata:
  name: myregistrykey
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: {{ template "imagePullSecret" . }}
```

## Tell Helm Not To Uninstall a Resource
Sometimes there are resources that should not be uninstalled when Helm runs a helm uninstall. Chart developers can add an annotation to a resource to prevent it from being uninstalled.

```yml
kind: Secret
metadata:
  annotations:
    "helm.sh/resource-policy": keep
[...]
```

(Quotation marks are required)

The annotation `"helm.sh/resource-policy": keep` instructs Helm to skip deleting this resource when a helm operation (such as helm uninstall, helm upgrade or helm rollback) would result in its deletion. However, this resource becomes orphaned. Helm will no longer manage it in any way. This can lead to problems if using helm install `--replace` on a release that has already been uninstalled, but has kept resources.

## Using `"Partials"` and Template Includes

Sometimes you want to create some reusable parts in your chart, whether they're blocks or template partials. And often, it's cleaner to keep these in their own files.

In the `templates/` directory, any file that begins with an underscore(`_`) is not expected to output a Kubernetes manifest file. So by convention, helper templates and partials are placed in a `_helpers.tpl` file.

## YAML is a Superset of JSON

According to the YAML specification, YAML is a superset of JSON. That means that any valid JSON structure ought to be valid in YAML.

This has an advantage: Sometimes template developers may find it easier to express a datastructure with a JSON-like syntax rather than deal with YAML's whitespace sensitivity.

As a best practice, templates should follow a YAML-like syntax unless the JSON syntax substantially reduces the risk of a formatting issue.

## Install or Upgrade a Release with One Command

Helm provides a way to perform an install-or-upgrade as a single command. Use helm `upgrade` with the `--install` command. This will cause Helm to see if the release is already installed. If not, it will run an install. If it is, then the existing release will be upgraded.

```yml
$ helm upgrade --install <release name> --values <values file> <chart directory>
```