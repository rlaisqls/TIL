# Istio Configuration Profiles

- **default**: enables components according to the default settings of the IstioOperator API. This profile is recommended for production deployments and for primary clusters in a multicluster mesh. You can display the default settings by running the istioctl profile dump command.

- **demo**: configuration designed to showcase Istio functionality with modest resource requirements. It is suitable to run the Bookinfo application and associated tasks. This is the configuration that is installed with the quick start instructions.
    > This profile enables high levels of tracing and access logging so it is not suitable for performance tests.

- **minimal**: same as the default profile, but only the control plane components are installed. This allows you to configure the control plane and data plane components (e.g., gateways) using separate profiles.

- **remote**: used for configuring a remote cluster that is managed by an external control plane or by a control plane in a primary cluster of a multicluster mesh.

- **empty**: deploys nothing. This can be useful as a base profile for custom configuration.

- **preview**: the preview profile contains features that are experimental. This is intended to explore new features coming to Istio. Stability, security, and performance are not guaranteed - use at your own risk.

<img width="601" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/ea123270-a7c8-4555-93a2-3c2a2cdf7c88">

