
Applications deployed and managed using the GitOps philosophy are often made of many files. There’s Kubernetes manifests for Deployments, Services, Secrets, ConfigMaps, and many more which all go into a Git repository to be revision controlled. Argo CD, the engine behind the OpenShift GitOps Operator, then uses that Git repository as the source for the application. So, how do we define all that to Argo CD? Using the Application CRD.

An Argo CD Application is a representation of a collection of Kubernetes-native manifests (usually YAML), that makes up all the pieces of your application. An Application is a Custom Resource Definition (CRD), used to define an Application source type. The source type is a definition of which deployment tool is used (helm or git) and where those manifests are located. But there are some challenges with this.

In this description, I will go over how to use ApplicationSets and go over different implementations of them.

## App of Apps

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/d9116e72-1791-4739-b81f-598d50852eda)

Many users opted to solve this issue by creating an Argo CD Application that deploys other Argo CD Applications.

This method solved a lot of problems. It was a way for users to massively deploy applications in one shot — so instead of deploying hundreds of Argo CD Application objects, you just deploy one that deploys the rest for you.

And, it was also a way of logically grouping real world applications that are made up of YAML manifests and Helm charts using Argo CD. This method also gave a convenient “watcher” Application, that made sure all Applications were deployed and healthy. 

This was a precursor to ApplicationSets.

## ApplicationSets Overview

Argo CD ApplicationSets are took the idea of “App of Apps” and expanded it to be more flexible and deal with a wide range of use cases. The ArgoCD ApplicationSets runs as its own controller and supplements the functionality of the Argo CD Application CRD.

ApplicationSets provide the following functionality:

- Use a single manifest to target multiple Kubernetes clusters.
- Use a single manifest to deploy multiple Applications from a single, or multiple, git repos.
- Improve support for monolithic repository patterns (also known as a “monorepo”). This is where you have many applications and/or environments defined in a single repository.
- Within multi-tenant clusters, it improves the ability of teams within a cluster to deploy applications using Argo CD (without the need for privilege escalation).

ApplicationSets interact with Argo CD by creating, updating, managing, and deleting Argo CD Applications. The ApplicationSets job is to make sure that the Argo CD Application remains consistent with the declared ApplicationSet resource. ApplicationSets can be thought of as sort of an “Application factory”. It takes an ApplicationSet and outputs one or more Argo CD Applications.


# Generators

The ApplicationSet [controller](https://argocd-applicationset.readthedocs.io/en/stable/#introduction) is made up of “generators”. These “generators” instruct the ApplicationSet how to generate Applications by the provided repo or repos, and it also instructs where to deploy the Application. There are 3 “generators” that I will be exploring are:

- List Generator
- Cluster Generator
- Git Generator

Each “generator” tackles different scenarios and use cases. Every “generator” gives you the same end result: Deployed Argo CD Applications that are loosely coupled together for easy management. What you use would depend on a lot of factors like the number of clusters managed, git repo layout, and environmental differences.

## List Generator

The `List Generator`, generates Argo CD Application manifests based on a fixed list. This is the most straightforward, as it just passes the key/value you specify in the elements section into the template section of the ApplicatonSet manifest. See the following example:

```yml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: bgd
  namespace: openshift-gitops
spec:
  generators:
  - list:
      elements:
      - cluster: cluster1
        url: https://api.cluster1.chx.osecloud.com:6443
     - cluster: cluster2
        url: https://api.cluster2.chx.osecloud.com:6443
      - cluster: cluster3
        url: https://api.cluster3.chx.osecloud.com:6443
  template:
    metadata:
      name: '{{cluster}}-bgd'
    spec:
      project: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
      source:
        repoURL: https://github.com/christianh814/gitops-examples
        targetRevision: master
        path: applicationsets/list-generator/overlays/{{cluster}}
      destination:
        server: '{{url}}'
        namespace: bgd
```

Here each iteration of `{{cluster}}` and `{{url}}` will be replaced by the elements above. This will produce 3 Applications.

<img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/c2802c8a-e848-4132-9ffb-4ebd8b2fdfc3" height=300px>

These clusters must already be defined within Argo CD, in order to generate applications for these values. The ApplicationSet controller does not create clusters.

You can see that my ApplicationSet deployed an Application to each cluster defined. You can use any combination of list elements in your config. It doesn’t have to be clusters or overlays. Since this is just a simple key/value pair generator, you can mix and match as you see fit.

### Cluster Generator

Argo CD stores information about the clusters it manages in a Secret. You can list your clusters by looking at the list of your secrets in the openshift-gitops namespace.

```bash
$ oc get secrets -n openshift-gitops -l argocd.argoproj.io/secret-type=cluster
NAME                                           TYPE DATA   AGE
cluster-api.cluster1.chx.osecloud.com-74873278 Opaque   3  23m
cluster-api.cluster2.chx.osecloud.com-2320437559   Opaque   3  23m
cluster-api.cluster3.chx.osecloud.com-2066075908   Opaque   3  23m
```

When you use the argocd CLI to list these clusters, the controller reads the secret to glean the information it needs.

```bash
$ argocd cluster list
SERVER                                  NAME    VERSION  STATUS  MESSAGE
https://api.cluster1.chx.osecloud.com:6443  cluster1 1.20 Successful  
https://api.cluster2.chx.osecloud.com:6443  cluster2 1.20 Successful  
https://api.cluster3.chx.osecloud.com:6443  cluster3 1.20 Successful
```

The same is true for the ApplicationSet controller. It uses those same Secrets to generate parameters that will be used in the template section of the manifest. Furthermore, you can use label selectors to target specific configurations to specific clusters. You can then just label the corresponding secret. Here’s an example:

```bash
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: bgd
  namespace: openshift-gitops
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          bgd: dev
  template:
    metadata:
      name: '{{name}}-bgd'
    spec:
      project: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
      source:
        repoURL: https://github.com/christianh814/gitops-examples
        targetRevision: master
        path: applicationsets/cluster-generator/overlays/dev/
      destination:
        server: '{{server}}'
        namespace: bgd
```

Here, under `.spec.generators.clusters` you can see that I set the selector as bgd=dev. Any cluster matching this label will have the Application deployed to it. The `{{name}}` and `{{server}}` resources get populated by the corresponding name and server fields in the secret.

Initially, when I apply this, I won’t see anything.

<img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/4e16da60-0983-4541-91be-4cb432744655" height=300px>


If I take a look at the controller logs, you see that it shows that it generated 0 applications.

```bash
$ oc logs -l app.kubernetes.io/name=argocd-applicationset-controller | grep generated
time="2021-04-01T01:25:31Z" level=info msg="generated 0 applications" generator="&{0xc000745b80 0xc000118000 0xc000afa000 openshift-gitops 0xc0009bd810 0xc000bb01e0}"
```

This is because we used the label `bgd=dev`` to indicate which cluster we want to deploy this Application. Let’s take a look at the secrets.

```bash
$ oc get secrets  -l bgd=dev -n openshift-gitops
```

No resources found in openshift-gitops namespace.

Let’s label cluster1, and then verify it, to deploy this Application to that cluster.

```bash
$ oc label secret cluster-api.cluster1.chx.osecloud.com-74873278 bgd=dev -n openshift-gitops
secret/cluster-api.cluster1.chx.osecloud.com-74873278 labeled

$ oc get secrets  -l bgd=dev -n openshift-gitops
NAME                                         TYPE DATA   AGE
cluster-api.cluster1.chx.osecloud.com-74873278   Opaque   3  131m
```

Taking a look at the UI, I should see the Application deployed.

<img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/13a1f945-2cff-431a-8dce-66e0ee5518e5" height=300px>

Now to deploy this Application to another cluster, you can just label the secret of the cluster you want to deploy to.

```bash
$ oc label secret cluster-api.cluster3.chx.osecloud.com-2066075908 bgd=dev -n openshift-gitops
secret/cluster-api.cluster3.chx.osecloud.com-2066075908 labeled
$ oc get secrets  -l bgd=dev -n openshift-gitops
NAME                                           TYPE DATA   AGE
cluster-api.cluster1.chx.osecloud.com-74873278 Opaque   3  135m
cluster-api.cluster3.chx.osecloud.com-2066075908   Opaque   3  135m
```

Now I have my Application deployed to both cluster1 and cluster3, and all I had to do was label the corresponding secret.

<img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/f93b6486-6b9b-4495-833b-191bc4c114c4" height=300px>

If you want to target all your clusters, you just need to set .spec.generators.clusters to an empty object {}. Example snippet below.

```bash
spec:
  generators:
  - clusters: {}
```

This will target all clusters that Argo CD has managed, including the cluster that Argo CD is running on, which is called the “in cluster”. Note that there are issues with this method and “in clusters”. Please see the following GitHub issue for more information.

## Git Generator

The Git Generator takes how your Git repository is organized to determine how your application gets deployed.The Git Generator has two sub-generators: Directory and File.

### Directory Generator

The Git Directory Generator generates the parameters used based on your directory structure in your git repository. The ApplicationSet controller will create Applications based on the manifests stored in a particular directory in your repository. Here is an example ApplicationSet manifest.

```yml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: pricelist
  namespace: openshift-gitops
spec:
  generators:
  - git:
      repoURL: https://github.com/christianh814/gitops-examples
      revision: master
      directories:
      - path: applicationsets/git-dir-generator/apps/*
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
      source:
        repoURL: https://github.com/christianh814/gitops-examples
        targetRevision: master
        path: '{{path}}'
      destination:
        server: https://api.cluster1.chx.osecloud.com:6443
        namespace: pricelist
```

This ApplicationSet deploys an Application that is made up of Helm charts and YAML working together. To understand how this works, it’s good to take a look at the tree view of my directory structure.

```bash
$ tree applicationsets/git-dir-generator/apps
applicationsets/git-dir-generator/apps
├── pricelist-config
│   ├── kustomization.yaml
│   ├── pricelist-config-ns.yaml
│   └── pricelist-config-rb.yaml
├── pricelist-db
│   ├── Chart.yaml
│   └── values.yaml
└── pricelist-frontend
    ├── kustomization.yaml
    ├── pricelist-deploy.yaml
    ├── pricelist-job.yaml
    ├── pricelist-route.yaml
    └── pricelist-svc.yaml
3 directories, 10 files
```

The name of the application is generated based on the name of the directory, denoted as `{{path.basename}}`` in the config, which is pricelist-config, pricelist-db, and pricelist-frontend.

The path to each application denoted as `{{path}}` will be based on what is defined under `.spec.generators.git.directories.path`` in the config. Once I apply this configuration, it will show 3 Applications in the UI.

Now, when you add a directory with Helm charts or bare YAML manifests it will automatically be added when you push to the tracked git repo.

<img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/ab0100ac-5604-4f2c-a3cb-4fc6a5c501dc" height=300px>

### File Generator

This generator is also based on what is stored in your git repository but instead of directory structure, it will read a configuration file. This file can be called whatever you want, but it must be in JSON format. Take a look at my directory structure.

```bash
$ tree applicationsets/git-generator/applicationsets/git-generator/
├── appset-bgd.yaml
├── base
│   ├── bgd-deployment.yaml
│   ├── bgd-namespace.yaml
│   ├── bgd-route.yaml
│   ├── bgd-svc.yaml
│   └── kustomization.yaml
├── cluster-config
│   ├── cluster1
│   │   └── config.json
│   ├── cluster2
│   │   └── config.json
│   └── cluster3
│       └── config.json
└── overlays
    ├── cluster1
    │   ├── bgd-deployment.yaml
    │   └── kustomization.yaml
    ├── cluster2
    │   ├── bgd-deployment.yaml
    │   └── kustomization.yaml
    └── cluster3
        ├── bgd-deployment.yaml
        └── kustomization.yaml
```

**Take note that this structure includes a cluster-config directory**. In this directory there is a `config.json` file that contains information about how to deploy the application by providing the information needed to pass to the template in the ApplicationSets manifest.

You can configure the `config.json` file as you like, as long as it’s valid JSON. Here is my example for cluster 1.

```bash
{
  "cluster": {
    "name": "cluster1",
    "server": "https://api.cluster1.chx.osecloud.com:6443",
    "overlay": "cluster1"
  }
}
```
Based on this configuration, I can build the ApplicationSet YAML.

```yml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: bgd
  namespace: openshift-gitops
spec:
  generators:
  - git:
      repoURL: https://github.com/christianh814/gitops-examples
      revision: master
      files:
      - path: "applicationsets/git-generator/cluster-config/**/config.json"
  template:
    metadata:
      name: '{{cluster.name}}-bgd'
    spec:
      project: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
      source:
        repoURL: https://github.com/christianh814/gitops-examples
        targetRevision: master
        path: applicationsets/git-generator/overlays/{{cluster.overlay}}
      destination:
        server: '{{cluster.server}}'
        namespace: bgd
```

This configuration takes the configuration files you’ve stored, which is denoted under `.spec.generators.git.files.path` section, and reads the configuration files to use as parameters for the template section.

<img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/ab0100ac-5604-4f2c-a3cb-4fc6a5c501dc" height=300px>

Using the configuration file instructs the controller how to deploy the application, as you can see from the screenshot. This is the most flexible of all, since it’s based on what you put in the JSON configuration.

Currently, only JSON is the supported format. You can track the progress of supporting YAML based configurations following [this GitHub Issue](https://github.com/argoproj-labs/applicationset/issues/106)

---
reference
- https://argocd-applicationset.readthedocs.io/en/stable/
- https://cloud.redhat.com/blog/getting-started-with-applicationsets
- https://blog.argoproj.io/getting-started-with-applicationsets-9c961611bcf0
- https://www.padok.fr/en/blog/introduction-argocd-applicationset