# Istio And Envoy

With Istio, the Envoy proxies are deployed collocated with all application instances participating in the service mesh, thus forming the service mesh data plane. Since Envoy is the such a critival component in the data plane and in the overall service-mesh architecture. So knowledge of envoy give a better understanding of Istio and how to debug or troubleshoot your deployments.

## What is envoy?

Envoy was developed at Lyft to solve some of the difficult application networking problems that **crop up when building distributed systems.** It was contributes as an open souce project in September 2016, and a year later (September 2017) it joined the Cloud Native Computing Foundation (CNCF). Envoy is written in C++ in an effort to increase performance and, more importantly, to make it more stable and deterministic at higher load echelons.

Envoy was created following two critical principles:

> The network should be transparent to applications. When network and application problems do occur it should be easy to determine the source of the problem.

Envoy is a proxy, is an intermediary component in a network architecture that is positioned in the middle of the communication between a client and a server. Being in the middle enables it to provide additional featuers like security, privacy, and policy.

<img width="585" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/95aaff2c-017c-4ddf-b2c1-3023999df3f5">

## Envoy’s core features

