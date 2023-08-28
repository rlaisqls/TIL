# Dex

Dex is an identity service that uses OpenID Connect to drive authentication for other apps.

Dex acts as a portal to other identity providers through "connectors." This lets dex defer authentication to LDAP servers, SAML providers, or established identity providers like GitHub, Google, and Active Directory. Clients write their authentication logic once to talk to dex, then dex handles the protocols for a given backend.

## ID Tokens

ID Tokens are an OAuth2 extension introduced by OpenID Connect and dex's primary feature. ID Tokens are JSON Web Tokens (JWTs) signed by dex and returned as part of the OAuth2 response that attest to the end user's identity. An example JWT might look like:

```yaml
eyJhbGciOiJSUzI1NiIsImtpZCI6IjlkNDQ3NDFmNzczYjkzOGNmNjVkZDMyNjY4NWI4NjE4MGMzMjRkOTkifQ.eyJpc3MiOiJodHRwOi8vMTI3LjAuMC4xOjU1NTYvZGV4Iiwic3ViIjoiQ2djeU16UXlOelE1RWdabmFYUm9kV0kiLCJhdWQiOiJleGFtcGxlLWFwcCIsImV4cCI6MTQ5Mjg4MjA0MiwiaWF0IjoxNDkyNzk1NjQyLCJhdF9oYXNoIjoiYmk5NmdPWFpTaHZsV1l0YWw5RXFpdyIsImVtYWlsIjoiZXJpYy5jaGlhbmdAY29yZW9zLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJncm91cHMiOlsiYWRtaW5zIiwiZGV2ZWxvcGVycyJdLCJuYW1lIjoiRXJpYyBDaGlhbmcifQ.OhROPq_0eP-zsQRjg87KZ4wGkjiQGnTi5QuG877AdJDb3R2ZCOk2Vkf5SdP8cPyb3VMqL32G4hLDayniiv8f1_ZXAde0sKrayfQ10XAXFgZl_P1yilkLdknxn6nbhDRVllpWcB12ki9vmAxklAr0B1C4kr5nI3-BZLrFcUR5sQbxwJj4oW1OuG6jJCNGHXGNTBTNEaM28eD-9nhfBeuBTzzO7BKwPsojjj4C9ogU4JQhGvm_l4yfVi0boSx8c0FX3JsiB0yLa1ZdJVWVl9m90XmbWRSD85pNDQHcWZP9hR6CMgbvGkZsgjG32qeRwUL_eNkNowSBNWLrGNPoON1gMg
```

ID Tokens contains standard claims assert which client app logged the user in, when the token expires, and the identity of the user.

```json
{
  "iss": "http://127.0.0.1:5556/dex",
  "sub": "CgcyMzQyNzQ5EgZnaXRodWI",
  "aud": "example-app",
  "exp": 1492882042,
  "iat": 1492795642,
  "at_hash": "bi96gOXZShvlWYtal9Eqiw",
  "email": "jane.doe@coreos.com",
  "email_verified": true,
  "groups": [
    "admins",
    "developers"
  ],
  "name": "Jane Doe"
}
```
Because these tokens are signed by dex and contain standard-based claims other services can consume them as service-to-service credentials. Systems that can already consume OpenID Connect ID Tokens issued by dex include:

- Kubernetes
- AWS STS

For details on how to request or validate an ID Token, see ["Writing apps that use dex"](https://dexidp.io/docs/using-dex/).

## Kubernetes and Dex
Dex runs natively on top of any Kubernetes cluster using Custom Resource Definitions and can drive API server authentication through the OpenID Connect plugin. Clients, such as the `[kubernetes-dashboard](https://github.com/kubernetes/dashboard)` and `kubectl`, can act on behalf of users who can login to the cluster through any identity provider dex supports.

- More docs for running dex as a Kubernetes authenticator can be found here.
- You can find more about companies and projects, which uses dex, here.

## Connectors

When a user logs in through dex, the user's identity is usually stored in another user-management system: a LDAP directory, a GitHub org, etc. Dex acts as a shim between a client app and the upstream identity provider. The client only needs to understand OpenID Connect to query dex, while dex implements an array of protocols for querying other user-management systems.

![image](https://github.com/rlaisqls/TIL/assets/81006587/fc23e33b-616b-4ecc-a0d7-5ae658da23ca)

A "connector" is a strategy used by dex for authenticating a user against another identity provider. Dex implements connectors that target specific platforms such as GitHub, LinkedIn, and Microsoft as well as established protocols like LDAP and SAML.

Depending on the connectors limitations in protocols can prevent dex from issuing refresh tokens or returning group membership claims. For example, because SAML doesn't provide a non-interactive way to refresh assertions, if a user logs in through the SAML connector dex won't issue a refresh token to its client. Refresh token support is required for clients that require offline access, such as `kubectl`.

oidc-proxy