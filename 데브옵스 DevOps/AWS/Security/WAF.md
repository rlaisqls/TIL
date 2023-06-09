# Web Application Firewall (WAF)

AWS WAF is a web application thet let you allow or block the HTTP(s) requesys that are bound for CloudFront, API Gateway, Application Load Balancers, EC2, and other Layer 7 entry points into you AWS Environment. AWS WAF gives you control over how traffic reaches your applications by enabling you to create security rules that block common attack patterns, such as SQL injection or cross-site scripting, and rules that filter out specific traffic patterns that you can define, WAF's default rule-set addresses issues like the OWASP top 10 security risks and is regularly updated whenever new vulnerabilities are discovered.

---

- As mentioned above WAF operates as a Layer 7 firewall. This grants it the ability to monitor grabular web-based confitions like URL query string parameters. This level of detail helps to detext both foul play and honest issues with the requests getting passed onto your AWS envirionment.

- With WAF, you can set confitions such as which IP addresses are allowed to make what kind of requests or access what kind of content.

- Bades off of these conditions, the corresponding endpoint will either allow the request by serving the requested content or return an HTTP 403 Forbidden status.

- At the simplest level, AWS WAF lets you choose one of the following behaviors:
    - **Allow all request except the ones that you specify**: This is useful when you want CloudFront or an Application Load Balancer to serve content for a public website, but you also want to block requests from attackers.
    - **Block all requests except the ones that you specify**: This is useful when you want to serve content for a restricted website whose users are readily identifiable by properties in web request, such as IP addresses that they use to brow to the website.
    - **Count the requests that match the properties that you specify**: When you want to allow or block requests based on new properties in web requests, tou first can configure AWS WAF to count the requests that match those properties withour allowing or blocking those requests. This lets you confirm that you didn't accidentally configure AWS WAF to block all the traffic to your website. When you're confident that you specified the correct properties, you can change the behavior to allow or block requests.

## WAF Protection Capabilities

- The different request characteristics that can be used to limit access: 
    - The IP address that a request originates from
    - The country that a request originates from
    - The values found in the request headers
    - Any strings that appear in the request (either specific strings or strings that match a regex pattern)
    - The length of the request
    - Any presence of SQL code (likely a SQL injection attempt)
    - Any presence of a script (likely a cross-site scripting attempt)

- You can also use NACLs to block malicious IP addresses, prevent SQL injections/XSS, and block requests from specific contries. However, it is good form to practice defense in depth.

- Denying or blocking malicious users at the WAF level has the the added advantage of protecting your AWS ecosystem at its outermost border.

