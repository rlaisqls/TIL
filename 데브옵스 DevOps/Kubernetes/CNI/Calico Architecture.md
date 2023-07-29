# Calico Architecture

<img width="1135" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/6a5978b9-9736-4673-99f9-9c0d5a565272">

## Calico components

### Calico API server

Main task: Lets you manage Calico resources directly with kubectl.

### Felix

Main task: P**rograms routes** and **ACLs**, and anything else **required on the host to provide desired connectivity for the endpoints on that host**. Runs on each machine that hosts endpoints. Runs as an agent daemon. Felix resource.

Depending on the specific orchestrator environment, Felix is responsible for:

- Interface Management
