# ACME(Automated Certificate Management Environment)

ACME is a protocol that makes it possible to automate the issuance and renewal of certificates, all withour human interaction.

The Internet Sercurity Research Group(ISRG) initially designed the ACME protocol for its own certificate service, [Let's Encrypt](https://letsencrypt.org/), a free and open certificate authority (CA) that provides domain validated (DV) certificates at no charge. Today various other CAs, PKI vendors, and browsers support ACME to support different types of certificates.

### How does the protocol work?

By leveragin ACME, organitations can streamline and automate otherwise time-consuming processes, such as CSR goneration, domain ownership verification, certificate issuance, and installation.

ACME is primatly used to obtain DV certificates. This is because DV certificates donot require advanced verification. Only the existence the domain is validatessd, which requires no thman intervention.

The protocol can also be used to obtain higher-value certifications, such as organization validated (OV) and extended validation (EV), but these cases require additional support mechanisms alongside the ACME agent.

The objective of ther ACME protocol is to set up an HTTPS server and automate the provisioning of trusted certificates and eliminate any error-prone manual transactions. To use the protocol, an ACME client and ECME server are needed, which communicate with JSON messages over a secure HTTPS connection.

- The client runs on any server or device that requires a trusted SSL/TLS certificate. It is used to request certificate management actions, such a s issuance or revocation.
- The server runs at a Certificate Authority (CA), like Let's Encrypt, and respond to the requests of authorized clients.

There are many different ACME client implementations available for the protocol. It is designed to allow businesses to choose the CA they want, as long as the CA supports ACME.

Let's Encrypt recomments using the certbot client, because it's easy to use, it works on many OS, and it has helpful documentation.

### Setting up an ACME client

Once you've selected a client, the next step is to install it on the domain/server where the certificates need to be deployed. ACME clients can tun in alost any programming language and environment, and the setup process consistes of just 5 straightforward steps to complete:

1. The client prompts to enter the domain to be managed.
2. The client offers a list of Certificate Authorities (CA) supporting the protocol.
3. The client contacts the selected CA and generates an authorization key pair.
4. The CA issues DNS or HTTPS challenges for the client to demonstrate control over their domain(s).
5. The CA sends a nonce – a randomly generated number – for the agent to sign with its private key to demonstrate ownership of the key pair.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/f919f6b5-08fa-4a0b-8ba9-5dce34ca0bfb)

### Using ACME to deploy and manage certificates

Issuing and renewing certificates using the ACME protocol is simple. The client simply sends certificate management requests and signs them with the authorized key pair.

**Issuance/renewal:** a web server with the ACME agent installed generates a CSR, sends it to the CA, and the CA issues it. The process for issuance and renewal works similarly:

1. The agent sends to the CA a Certificate Signing Request (CSR) requesting the issuance of a certificate for the authorized domain with a specified public key.
2. The CSR is signed with the corresponding private key and the authorized key for the domain.
3. When the CA receives the request, it verifies both signatures, issues a certificate for the authorized domain with the public key from the CSR, and returns it to the agent.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/e592874d-fdad-43ec-8d7c-0c0a6e2684dc)

**Revocation:** to revoke a certificate, the agent signs the revocation request with the authorized key pair for the domain, and the CA validates the request. The CA then publishes the revocation information through CRLs or OCSP to prevent the acceptance of the revoked certificate.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/0da73283-e653-4db3-a346-3facd687329b)

### Solving Challenges

In order for the ACME CA server to verity that a client owns the domains, a certificate is being requested for, the client must complete "challenges". This is to ensure clients are unable to request certificates for domains they do not own and as a result, fraudulently impersonate another's site. As detailed in the [RFC8555](https://tools.ietf.org/html/rfc8555), cert-manager offers two challenge validations - HTTP01 and DNS01 challenges.

**HTTP01** challenges are completed by presenting a computed key, that sould be present at a HTTP URL endpoint and is routable over the internet. This URL will use the domain name requested for the certificate. Once the ACME server is able to get this key from this URL over the internet, the ACME server can validate you are the owner of this domain. When a HTTP01 challenge is created, cert-manager will automatically configure your cluster ingress to route traffic for this URL to a small web server that presents this key.

- Advantages:
    - Automate easily without additional knowledge of domain configuration.
    - Hosting providers can issue certificates for the CNAME domain.
    - Works with commercial web servers.
- Disadvantages:
    - When an ISP blocks port 80 it doesn't work (rarely happens on some home ISPs).
    - Let's Encrypt cannot use this task to issue wildcard certificates.
    - If you have multiple Web servers, you must ensure that files are available on all servers.

**DNS01** challenges are complated by providing a computed key that is present at a DNS TXT record. Onve this TXT record has been propagated across the internet, the ACME server cna successfully retrive this key via a DNS lookup and can validate that the client owns the domain for the requested certificate. With the correct permissions, cert-manager will automatically present this TXT record for your given DNS provider.

- Advantages:
    - You can use this way to issue a certificate that contains the wildcard domain name.
    - It works well with multiple web servers.
- Disadvantages:
    - Maintaining API credentials on a web server is risky.
    - The DNS provider might not provide the API.
    - The DNS API may not provide information about propagation time.

---
reference
- https://datatracker.ietf.org/doc/html/rfc8555
- https://www.keyfactor.com/blog/what-is-acme-protocol-and-how-does-it-work/
- https://en.wikipedia.org/wiki/Automatic_Certificate_Management_Environment