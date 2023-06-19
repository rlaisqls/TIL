# Route53

Amazon Route 53 is a highly available and scalable Domain Name System(DNS) service. You can use Route 53 to perform three main functions in any combination: domain registration, DNS routing, and health checking.

---

- DNS is used to map human-readable domain names into an internet protocol address similarly to how phone books map company names with phone numbers.

- When you buy a domain name, every DNS address starts with an SOA(Start of Authority) record. The SOA record stores information about the name of the server that kicked off the the transfer of ownership, the administrator who will now use the domain, the current metadata available, and the default number of seconds or TTL.

- NS records, or Name Server records, are used by the Top Level Domain hosts(`.org`, `.com`, `.uk`, etc.) to direct traffic to the Content servers. The Content DNS servers contain the authoritative DNS records.

- Browsers talk to the Top Level Domains whenever they are queried and encounter domain name that they do not recognize.
    1. Browsers will ask for the authoritative DNS records associated with the domain.
    2. Because the Top Level Domain contains NS records, the TLD can in turn query the Name Servers for their own SOA
    3. Within the SOA, there will be the requested informaion.
    4. Once this information is collected, it will then be  returned all the way back to the original browser asking for it.
    In summary: Browser -> TLD -> NS -> SOA -> DNS record. The pipeline reverses when the correct DNS record is found

- Autoritative name servers store DNS record information, usually a DNS hosting provider or domain register like GoDaddy that offers both DNS registration and hosting.

- There are multitude of DNS records for Route53. Here are some of the more common ones:
    - **A records:** These are the fundamental type of DNS record. The `A` in A records stands for `address`. These records are used by a computer to directly pair a domain name to an IP address. IPv4 and IPv6 are both supported with `AAAA` referring to the IPv6 version.
        A: URL -> IPv4<br>AAAA: IRL -> IPv6
    - **CName records:** Also referred to as the Canonical Name. These records are used to resolve one domain name to another domain name. For example, the domain of the mobile version of a website may be a CName from the domain of the browser bersion of that same website rather than a separate IP address. This would allow mobile users who visit the site and to receive the mobile version.
        CNAME: URL -> URL
    - **Alias records:** These records are used to map your domains to AWS resources such ad load balancers, CDN endpoints, and S3 buckets. Alias records function similarly to CNames in the sense that you map don domain to another.
        The key differnce though is that by pointing your Alias record at a service rather than domain name, you have the abiliry to freely change your domain names if needed and not have to worry about what records might be mapped to it. Alias records give tou dynamic functionality.
        One other major difference between CNames and Alias records is that a CName cannot be used for the naked domain name (the apex record in your entire DNS configuration / the primary record to be used). CNames must always be secondary records that can map to another secondary record or the apex record. The primary must always be of type Alias or A Record in order to work.
        Alias: URL -> AWS Resource
    - PTR records: These records are the opposite of an A record PTR records map an IP to a domain and they are used in reverse DNS lookups as a way to obbtain the domain name of an IP address.
        PTR: IPv4 -> URL

- Due to the dynamix nature of Alias records, they are often recommended for most usecases and should be used when it is possible to.

- TTL is the length that a DNS record is cached on either the resolcing servers or the userd own cache so that a fresher mapping of IP to domain can be retrieved. Time to live is measured in seconds and the lower the TTL the faster DNS changes propagate across the internet. Most providers, for example, have a TTL that lasts 48 hours.
  
-  Route53 health checks can be used for any AWS endpoint that can be accessed via the Internet. This makes it an ideal option for monitoring the health of your AWS endpoints.

## Route53 Routing Policies

- When you create a record, you choose a routing policy, which determins how Amazon Reoute 53 responsd to DBS queries. The routing policies available are:
    - Simple Routing
    - Weighted Routing
    - Latency-based Routing
    - Failover Routing
    - Geolocation Routing
    - Geo-proximity Routing
    - Multivalue Answer Routing

- **Simple Routing** is used when you just need a single record in your DNS with either one or more IP addresses behind the record in case you want to balance load. If you specify multiple values in a Simple Routing polivy, Route53 returns a random IP from the options available.

- **Weighted Routing** is used when you want to split your traffic based on assigned weights. For example, if you want 80% of your traffic to go to one AZ and the rest to goto another, use Weighted Routing. This policy is very useful for testing feature changes and due to the traffic splitting characteristics, it can double as a means to perform blue-grean deployments. When creating Whighted Routing, you need to specify a new record for each IP address. You cannot group the various IPs under one record like with Simpele Routing.

- **Latency-base Routing**, as the name implies, is based on setting up routing based on what would be the lowest latency for a given user. To use latency-based routing, you must create a latency resource record set in the same region as the corresponding EC2 or ELB resource receiving the traffix. When Route53 receives a query for your site, it selects the record set that gives the user the quickest speed. When creating Latency-based Routing, you need to specify a end record for each IP.

- **Failover Routing** is used when you want to configure an active-passive failover set up. Route53 will monitor the health of your primary so that it can failover when needed. You can also manually set up health checks to monitor all endpoints if you want more detailed ruls.

- **Geolocation Routing** lets you choose where traffic will be sent based on the geographic location of your users.

- **Geo-proximity Routing** lets you choose where traffic will be sent based on the geographic location of your users and your resources. You can choose to route more or less traffic based on a specified weight which is referred to as a bias. This bias either expands or shrinks the availability of a geographic region which makes it easy to shift traffic from resources in one location to resources in another.
    To use this routing method, you must enable Route53 traffic flow. If you want to control global traffic, use Geo-proximity routing. If you want traffic to stay in a local region, use Geolocation routing.

- **Multivalue Routing** is pretty much the same as Simple Routing, but Multivalue Routing allows you to put health checks on each record set. This ensures then that only a healthy IP will be randomly returned rather than any IP.