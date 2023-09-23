# WAF & Firewall Manager & Shield Advanced

You can use AWS WAF, AWS Shield, and AWS Firewall Manager together to create a comprehensive security solution. 

- **AWS WAF**: A web application firewall that you can use to monitor web requests that your end users send to your applications and to control access to your content. 

- **AWS Shield**: It provides protection against distributed denial of service (DDoS) attacks for AWS resources, at the network and transport layers (layer 3 and 4) and the application layer (layer 7).

- **AWS Firewall Manager**: It provides management of protections like AWS WAF and Shield Advanced across accounts and resources, even as new resources are added.

## AWS WAF

[AWS WAF](https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html) is a web application firewall that lets you monitor the HTTP and HTTPS requests that are forwarded to your protected web application resources. You can protect the following resource types:

- Amazon CloudFront distribution
- Amazon API Gateway REST API
- Application Load Balancer
- AWS AppSync GraphQL API
- Amazon Cognito user pool
- AWS App Runner service
- AWS Verified Access instance

AWS WAF lets you control access to your content. Based on conditions that you specify, such as the IP addresses that requests originate from or the values of query strings, your protected resource responds to requests either with the requested content, with an HTTP 403 status code (Forbidden), or with a custom response.

At the simplest level, AWS WAF lets you choose one of the following behaviors:

- Allow all requests except the ones that you specify
- Block all requests except the ones that you specify
- Count requests that match your criteria
- Run CAPTCHA or challenge checks against requests that match your criteria

Using AWS WAF has several benefits:

- Additional protection against web attacks using criteria that you specify. You can define criteria using characteristics of web requests such as the following:
- `IP addresses` that requests originate from.
- `Country` that requests originate from.
- Values in request headers.
- Strings that appear in requests, either specific strings or strings that match regular expression (regex) patterns.
- `Length of requests`.
- Presence of SQL code that is likely to be malicious (known as `SQL injection`).
- Presence of a script that is likely to be malicious (known as `cross-site scripting`).
- Rules that can allow, block, or count web requests that meet the specified criteria. Alternatively, rules can block or count web requests that not only meet the specified criteria, but also exceed a specified number of requests in any 5-minute period.
- Rules that you can reuse for multiple web applications.
- Managed rule groups from AWS and AWS Marketplace sellers.
- Real-time metrics and sampled web requests.
- Automated administration using the AWS WAF API.

If you want granular control over the protections that you add to your resources, AWS WAF alone might be the right choice.

## AWS Shield

You can use AWS WAF web access control lists (web ACLs) to help minimize the effects of a Distributed Denial of Service (DDoS) attack. 

But, for **additional protection against DDoS attacks**, AWS also provides AWS Shield Standard and [AWS Shield Advanced](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-advanced-summary-capabilities.html). AWS Shield Standard is automatically included at no extra cost beyond what you already pay for AWS WAF and your other AWS services.

AWS Shield Advanced provides expanded DDoS attack protection for your Amazon EC2 instances, Elastic Load Balancing load balancers, CloudFront distributions, Route 53 hosted zones, and AWS Global Accelerator standard accelerators

AWS Shield Advanced incurs additional charges. Shield Advanced options and features include automatic application layer DDoS mitigation, advanced event visibility, and dedicated support from the Shield Response Team (SRT).

If you own high visibility websites or are otherwise prone to frequent DDoS attacks, consider purchasing the additional protections that Shield Advanced provides. More information is [here](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-advanced-summary-deciding.html)

> AWS Shield Advanced will give you DDoS protection overall, and you cannot set up rate-based rules in Shield. So if you want to define a rate-based rule, use AWS WAF.

## AWS Firewall Manager

AWS Firewall Manager **simplifies your administration and maintenance tasks across multiple accounts and resources** for a variety of protections, including `AWS WAF`, `AWS Shield Advanced`, `Amazon VPC security groups`, `AWS Network Firewall`, and `Amazon Route 53 Resolver DNS Firewall`.

With Firewall Manager, you set up your protections just once and the service automatically applies them across your accounts and resources, even as you add new accounts and resources.

---
reference
- https://docs.aws.amazon.com/waf/latest/developerguide/what-is-aws-waf.html



