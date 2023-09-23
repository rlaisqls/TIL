# AWS Managed Microsoft AD

AWS offers [AWS Directory Service for Microsoft Active Directory](https://aws.amazon.com/directoryservice/), also known as AWS Managed Microsoft AD, to provide a highly available and resilient Active Directory service.

## Starting with Kerberos

Kerberos is a subject that, on the surface, is simple enough, but can quickly become much more complex. If you wish to look further into the topic, see [the Microsoft Kerberos documentation](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2003/cc772815(v=ws.10)?redirectedfrom=MSDN). In this post, I’m just going to give you an overview of how Kerberos authentication works across trusts.

<img width="620" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/cc1bd129-4ea6-412c-8c16-319f22e5f1ca">

- If you only remember one thing about Kerberos and trust, **it should be referrals**. Let’s look at the workflow in Figure, which shows a user from Domain A who is logged into a computer in Domain A and wants to access an Amazon FSx file share in Domain B. For simplicity’s sake, I’ll say there is a two-way trust between Domains A and B.

- The steps of the Kerberos authentication process over trusts are as follows:
  1. Kerberos authentication service request (KRB_AS_REQ): The client contacts the authentication service (AS) of the KDC (which is running on a domain controller) for Domain A, which the client is a member of, for a short-lived ticket called a Ticket-Granting Ticket (TGT). 
    The default lifetime of the TGT is 10 hours. For Windows clients this happens at logon, but Linux clients might need to run a kinit command.

  2. Kerberos authentication service response (KRB_AS_REP): The AS constructs the TGT and creates a session key that the client can use to encrypt communication with the ticket-granting service (TGS). 
    At the time that the client receives the TGT, the client has not been granted access to any resources, even to resources on the local computer.

  3. Kerberos ticket-granting service request (KRB_TGS_REQ): The user’s Kerberos client sends a KRB_TGS_REQ message to a local KDC in Domain A, specifying fsx@domainb as the target. 
    The Kerberos client compares the location with its own workstation’s domain. Because these values are different, the client sets a flag in the KDC Options field of the `KRB_TGS_REQ` message for `NAME_CANONICALIZE`, which indicates to the KDC that the server might be in another realm (domain).

  4. Kerberos ticket-granting service response (KRB_TGS_REP): The user’s local KDC (for Domain A) receives the KRB_TGS_REQ and sends back a TGT referral ticket for Domain B.
    The TGT is issued for the next intervening domain along the shortest path to Domain B. The TGT also has a referral flag set, so that the KDC will be informed that the KRB_TGS_REQ is coming from another realm. This flag also tells the KDC to fill in the Transited Realms field. The referral ticket is encrypted with the interdomain key that is decrypted by Domain B’s TGS.
    > Note: When a trust is established between domains or forests, an interdomain key based on the trust password becomes available for authenticating KDC functions and is used to encrypt and decrypt Kerberos tickets.

  5. Kerberos ticket-granting service request (KRB_TGS_REQ): The user’s Kerberos client sends a KRB_TGS_REQ along with the TGT it received from the Domain A KDC to a KDC in Domain B.

  6. Kerberos ticket-granting service response (KRB_TGS_REP): The TGS in Domain B examines the TGT and the authenticator. If these are acceptable, the TGS creates a service ticket. The client’s identity is taken from the TGT and copied to the service ticket. Then the ticket is sent to the client.
    For more details on the authenticator, see [How the Kerberos Version 5 Authentication Protocol Works](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2003/cc772815(v=ws.10)#the-authenticator).

  7. Application server service request (KRB_TGS_REQ): After the client has the service ticket, the client sends the ticket and a new authenticator to the target server, requesting access. The server will decrypt the ticket, validate the authenticator, and (for Windows services), create an access token for the user based on the SIDs in the ticket.

  8. Application server service response (KRB_TGS_REP): Optionally, the client might request that the target server verify its own identity. This is called <u>mutual authentication</u>. If mutual authentication is requested, the target server takes the client computer’s timestamp from the authenticator, encrypts it with the session key the TGS provided for client-target server messages, and sends it to the client.

## The basics of trust transitivity, direction, and types

Let’s start off by defining a trust. Active Directory trusts are **a relationship between domains**, which makes it possible for users in one domain to be authenticated by a domain controller in the other domain. Authenticated users, if given proper permissions, can access resources in the other domain.

Active Directory Domain Services supports four types of trusts: External (Domain), Forest, Realm, and Shortcut. Out of those four types of trusts, AWS Managed Microsoft AD supports the External (Domain) and Forest trust types. This post will focus on External (Domain) and Forest trust types for this post.

## Transitivity: What is it?

Before We dive into the types of trusts, it’s important to understand the concept of transitivity in trusts.

A trust that is transitive allows authentication to flow through other domains (Child and Trees) in the trusted forests or domains. In contrast, a non-transitive trust is a point-to-point trust that allows authentication to flow exclusively between the trusted domains.

<img width="352" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/84ed0011-3de5-4a5f-a1ba-026271709d23">

The example in above figure shows a Forest trust between `Example.com` and `Example.local`. The `Example.local` forest has a child domain named Child. With a transitive trust, users from the `Example.local` and Child.`Example.local` domain can be authenticated to resources in the Example.com domain.

If figure has an External trust, only users from `Example.local` can be authenticated to resources in the `Example.com` domain. Users from Child.`Example.local` cannot traverse the trust to access resources in the `Example.com` domain.

## Trust direction

- **Two-way trusts are bidirectional trusts that allow authentication referrals from either side of the trust to give users access resources in either domain or forest.**
  If you look in the Active Directory Domains and Trusts area of the Microsoft Management Console (MMC), which provides consoles to manage the hardware, software, and network components of Microsoft Windows operating system, you can see both an incoming and an outgoing trust for the trusted domain.

- **One-way trusts are a single-direction trust that allows authentication referrals from one side of the trust only**. A one-way trust is either outgoing or incoming, but not both (that would be a two-way trust).
  An outgoing trust allows users from the trusted domain (`Example.com`) to authenticate in this domain (`Example.local`).
  An incoming trust allows users from this domain (`Example.local`) to authenticate in the trusted domain (`Example.com`).

<img width="322" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/1ffb4e0e-1203-45fb-9ce8-9a1d3e5b4148">
https://www.musinsa.com/app/goods/1752735?loc%253Dgoods_rank
Let’s use a diagram to further explain this concept. Figure 3 shows a one-way trust between `Example.com` and `Example.local`. This an outgoing trust from `Example.com` and an incoming trust on `Example.local`. Users from `Example.local` can authenticate and, if given proper permissions, access resources in Example.com. Users from Example.com cannot access or authenticate to resources in `Example.local`.

> A two-way trust is required for AWS Enterprise Apps such as Amazon Chime, Amazon Connect, Amazon QuickSight, AWS IAM Identity Center (successor to AWS Single Sign-On), Amazon WorkDocs, Amazon WorkMail, Amazon WorkSpaces, and the AWS Management Console. AWS Managed Microsoft AD must be able to query the users and groups in your self-managed AD.
> Amazon EC2, Amazon RDS, and Amazon FSx will work with either a one-way or two-way trust.

## Trust types
In this section of the post, I’ll examine the various types of Active Directory trusts and their capabilities.

### External trusts

This trust type is used to **share resources between two domains**. These can be individual domains within or external to a forest. Think of this as a point-to-point trust between two domains. See [Understanding When to Create an External Trust](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-r2-and-2008/cc732859(v=ws.10)) for more details on this trust type.

- Transitivity: Non-transitive
- Direction: One-way or two-way
- Authentication types: NTLM Only* (Kerberos is possible with caveats; see the Microsoft Windows Server documentation for details)
- AWS Managed Microsoft AD support: Yes

### Forest trusts

This trust type is used to share resources between two forests. This is the preferred trust model, because it works fully with Kerberos without any caveats. See Understanding When to Create a Forest Trust for more details.

- Transitivity: Transitive
- Direction: One-way or two-way
- Authentication types: Kerberos and NTLM
- AWS Managed Microsoft AD support: Yes

### Realm trusts

This trust type is used to form a trust relationship between a non-Windows Kerberos realm and an Active Directory domain. See Understanding When to Create a Realm Trust for more details.

- Transitivity: Non-transitive or transitive
- Direction: One-way or two-way
- Authentication types: Kerberos Only
- AWS Managed Microsoft AD support: No

### Shortcut trusts

This trust type is used to shorten the authentication path between domains within complex forests. See Understanding When to Create a Shortcut Trust for more details.

- Transitivity: Transitive
- Direction: One-way or two-way
- Authentication types: Kerberos and NTLM
- AWS Managed Microsoft AD support: No

---
reference
- https://aws.amazon.com/es/blogs/security/everything-you-wanted-to-know-about-trusts-with-aws-managed-microsoft-ad/