# Network Troubleshooting

Troubleshooting network0related issues with Linux is a complex topic and could easily fill its own book. we will introduce some key troubleshooting tools and the basics of their use.

There is substantial overlap in the tools that we describe, so you may find learning about some tools (or tool features) redundant. Some are better suited to a given task than others (for example, multiple tools will catch TLS errors, but OpenSSL provides the richest debugging information).

Exact tool use may come down to preference, familiarity, and availability.


|Case|Tools|
|-|-|
|Checking connectivity|`traceroute`, `ping`, `telnet`, `netcat`|
|Port scanning|`nmap`|
|Checking DNS records|`dig`, commands mentioned in “Checking Connectivity”
|Checking HTTP/1|`cURL`, `telnet`, `netcat`|
|Checking HTTPS|`OpenSSL`, `cURL`|
|Checking listening programs|`netstat`|

Some networking tools that we describe likely won’t be preinstalled in your distro of choice, but all should be available through your distro’s package manager. We will sometimes use `# Truncated` in command output where we have omitted text to avoid examples becoming repetitive or overly long.

## Security Warning

Before we get into tooling details, we got to notice about some security warning. An attacker can utilize any tool listed here in order to explore and access additional systems. There are many strong opinions on this topic, but we consider it best practice to leave the fewest possible networking tools installed on a given machine.

An attacker may still be able to download tools themselves (e.g., by downloading a binary from the internet) or use the standard package manager (if they have sufficient permission). In most cases, you are simply introducing some additional friction prior to exploring and exploiting. However, in some cases you can reduce an attacker’s capabilities by not preinstalling networking tools.

Linux file permissions include something called the _setuid bit_ that is sometimes used by networking tools. If a file has the setuid bit set, executing said file causes the file to be executed as the user who owns the file, rather than the current user. You can observe this by looking for an `s` rather than an `x` in the permission readout of a file:

```bash
$ ls -la /etc/passwd
-rwsr-xr-x 1 root root 68208 May 28  2020 /usr/bin/passwd
```

This allows programs to expose limited, privileged capabilities (for example, passwd uses this ability to allow a user to update their password, without allowing arbitrary writes to the password file). A number of networking tools (ping, nmap, etc.) may use the setuid bit on some systems to send raw packets, sniff packets, etc.

If an attacker downloads their own copy of a tool and cannot gain root privileges, they will be able to do less with said tool than if it was installed by the system with the setuid bit set.

## ping

```bash
ping <address>
```

ping is a simple program that sends ICMP `ECHO_REQUEST` packets to networked devices. It is a common, simple way to test network connectivity from one host to another.

ICMP is a layer 4 protocol, like TCP and UDP. Kubernetes services support TCP and UDP, **but not ICMP**. **This means that pings to a Kubernetes service will always fail**. Instead, you will need to use telnet or a higher-level tool such as cURL to check connectivity to a service. <u>Individual pods may still be reachable by ping, depending on your network configuration.</u>

> Firewalls and routing software are aware of ICMP packets and can be configured to filter or route specific ICMP packets. It is common, but not guaranteed (or necessarily advisable), to have permissive rules for ICMP packets. Some network administrators, network software, or cloud providers will allow ICMP packets by default.

---

By default, ping will send packets forever, and must be manually stopped (e.g., with Ctrl-C). -c <count> will make ping perform a fixed number before shutting down. On shutdown, ping also prints a summary:

```bash
~ ping -c 2 k8s.io
PING k8s.io (34.107.204.206): 56 data bytes
64 bytes from 34.107.204.206: icmp_seq=0 ttl=51 time=9.934 ms
64 bytes from 34.107.204.206: icmp_seq=1 ttl=51 time=7.762 ms

--- k8s.io ping statistics ---
2 packets transmitted, 2 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 7.762/8.848/9.934/1.086 ms
```

Common Options
|Option|Description|
|-|-|
|`-c <count>`|Sends the specified number of packets. Exits after the final packet is received or times out.|
|`-i <seconds>`|Sets the wait interval between sending packets. Defaults to 1 second. Extremely low values are not recommended, as ping can flood the network.|
|`-o`|Exit after receiving 1 packet. Equivalent to -c 1.|
|`-S <source address>`|Uses the specified source address for the packet.|
|`-W <milliseconds>`|Sets the wait interval to receive a packet. If ping receives the packet later than the wait time, it will still count toward the final summary.|

## traceroute

`traceroute` shows the network route taken from one host to another. This allows users to easily validate and debug the route taken (or where routing fails) from one machine to another.

`traceroute` sends packets with specific IP time-to-live values. When a host receives a packet and decrements the TTL to 0, it sends a `TIME_EXCEEDED` packet and discards the original packet. The `TIME_EXCEEDED` response packet contains the source address of the machine where the packet timed out. By starting with a TTL of 1 and raising the TTL by 1 for each packet, `traceroute` is able to get a response from each host along the route to the destination address.

traceroute displays hosts line by line, starting with the first external machine. Each line contains the hostname (if available), IP address, and response time:

```bash
$traceroute k8s.io
traceroute to k8s.io (34.107.204.206), 64 hops max, 52 byte packets
 1  router (10.0.0.1)  8.061 ms  2.273 ms  1.576 ms
 2  192.168.1.254 (192.168.1.254)  2.037 ms  1.856 ms  1.835 ms
 3  adsl-71-145-208-1.dsl.austtx.sbcglobal.net (71.145.208.1)
4.675 ms  7.179 ms  9.930 ms
 4  * * *
 5  12.122.149.186 (12.122.149.186)  20.272 ms  8.142 ms  8.046 ms
 6  sffca22crs.ip.att.net (12.122.3.70)  14.715 ms  8.257 ms  12.038 ms
 7  12.122.163.61 (12.122.163.61)  5.057 ms  4.963 ms  5.004 ms
 8  12.255.10.236 (12.255.10.236)  5.560 ms
    12.255.10.238 (12.255.10.238)  6.396 ms
    12.255.10.236 (12.255.10.236)  5.729 ms
 9  * * *
10  206.204.107.34.bc.googleusercontent.com (34.107.204.206)
64.473 ms  10.008 ms  9.321 ms
If traceroute receives no response from a given hop before timing out, it prints a *. Some hosts may refuse to send a TIME_EXCEEDED packet, or a firewall along the way may prevent successful delivery.
```

Common options


|Option|Syntax|Description|
|-|-|-|
|First TTL|`-f <TTL>`, `-M <TTL>`|Set the starting IP TTL (default value: 1). Setting the TTL to n will cause traceroute to not report the first n-1 hosts en route to the destination.|
|Max TTL|`-m <TTL>`|Set the maximum TTL, i.e., the maximum number of hosts that traceroute will attempt to route through.|
|Protocol|`-P <protocol>`|Send packets of the specified protocol (TCP, UDP, ICMP, and sometimes other options). UDP is default.|
|Source address|`-s <address>`|Specify the source IP address of outgoing packets.|
|Wait|`-w <seconds>`|Set the time to wait for a probe response.|

## dig
`dig` is a DNS lookup tool. You can use it to make DNS queries from the command line and display the results.

The general form of a `dig` command is `dig [options] <domain>`. By default, `dig` will display the CNAME, A, and AAAA records:

```bash
$ dig kubernetes.io

; <<>> DiG 9.10.6 <<>> kubernetes.io
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51818
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1452
;; QUESTION SECTION:
;kubernetes.io.			IN	A

;; ANSWER SECTION:
kubernetes.io.		960	IN	A	147.75.40.148

;; Query time: 12 msec
;; SERVER: 2600:1700:2800:7d4f:6238:e0ff:fe08:6a7b#53
(2600:1700:2800:7d4f:6238:e0ff:fe08:6a7b)
;; WHEN: Mon Jul 06 00:10:35 PDT 2020
;; MSG SIZE  rcvd: 71
```

To display a particular type of DNS record, run dig <domain> <type> (or dig -t <type> <domain>). This is overwhelmingly the main use case for dig:

```bash
$ dig kubernetes.io TXT

; <<>> DiG 9.10.6 <<>> -t TXT kubernetes.io
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 16443
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;kubernetes.io.			IN	TXT

;; ANSWER SECTION:
kubernetes.io.		3599	IN	TXT
"v=spf1 include:_spf.google.com ~all"
kubernetes.io.		3599	IN	TXT
"google-site-verification=oPORCoq9XU6CmaR7G_bV00CLmEz-wLGOL7SXpeEuTt8"

;; Query time: 49 msec
;; SERVER: 2600:1700:2800:7d4f:6238:e0ff:fe08:6a7b#53
(2600:1700:2800:7d4f:6238:e0ff:fe08:6a7b)
;; WHEN: Sat Aug 08 18:11:48 PDT 2020
;; MSG SIZE  rcvd: 171
```
Common options
|Option|Syntax|Description|
|IPv4|`-4`|Use IPv4 only.|
|IPv6|`-6`|Use IPv6 only.|
|Address|`-b <address>[#<port>]`|Specify the address to make a DNS query to. Port can optionally be included, preceded by #.|
|Port|`-p <port>`|Specify the port to query, in case DNS is exposed on a nonstandard port. The default is 53, the DNS standard.|
|Domain|`-q <domain>`|The domain name to query. The domain name is usually specified as a positional argument.|
|Record Type|`-t <type>`|The DNS record type to query. The record type can alternatively be specified as a positional argument.|

## telnet

`telnet` is both a network protocol and a tool for using said protocol. `telnet` was once used for remote login, in a manner similar to SSH. SSH has become dominant due to having better security, but `telnet` is still extremely useful for debugging servers that use a text-based protocol. For example, with `telnet`, you can connect to an HTTP/1 server and manually make requests against it.

The basic syntax of `telnet` is `telnet <address> <port>`. This establishes a connection and provides an interactive command-line interface. Pressing Enter twice will send a command, which easily allows multiline commands to be written. Press Ctrl-J to exit the session:

```bash
$ telnet kubernetes.io
Trying 147.75.40.148...
Connected to kubernetes.io.
Escape character is '^]'.
> HEAD / HTTP/1.1
> Host: kubernetes.io
>
HTTP/1.1 301 Moved Permanently
Cache-Control: public, max-age=0, must-revalidate
Content-Length: 0
Content-Type: text/plain
Date: Thu, 30 Jul 2020 01:23:53 GMT
Location: https://kubernetes.io/
Age: 2
Connection: keep-alive
Server: Netlify
X-NF-Request-ID: a48579f7-a045-4f13-af1a-eeaa69a81b2f-23395499
```

To make full use of `telnet`, you will need to understand how the application protocol that you are using works. `telnet` is a classic tool to debug servers running HTTP, HTTPS, POP3, IMAP, and so on.

## nmap
`nmap` is a port scanner, which allows you to explore and examine services on your network.

The general syntax of `nmap` is `nmap [options] <target>`, where target is a domain, IP address, or IP CIDR. nmap’s default options will give a fast and brief summary of open ports on a host:

```bash
$ nmap 1.2.3.4
Starting Nmap 7.80 ( https://nmap.org ) at 2020-07-29 20:14 PDT
Nmap scan report for my-host (1.2.3.4)
Host is up (0.011s latency).
Not shown: 997 closed ports
PORT     STATE SERVICE
22/tcp   open  ssh
3000/tcp open  ppp
5432/tcp open  postgresql

Nmap done: 1 IP address (1 host up) scanned in 0.45 seconds
```

In the previous example, nmap detects three open ports and guesses which service is running on each port.

> Because nmap can quickly show you which services are accessible from a remote machine, it can be a quick and easy way to spot services that should not be exposed. nmap is a favorite tool for attackers for this reason.

`nmap` has a dizzying number of options, which change the scan behavior and level of detail provided. As with other commands, we will summarize some key options, but we highly recommend reading `nmap`’s help/man pages.

**common options**

|Option|Syntax|Description|
|-|-|-|
|Additional detection|`-A`|Enable OS detection, version detection, and more.|
|Decrease verbosity|`-d`|Decrease the command verbosity. Using multiple d’s (e.g., -dd) increases the effect.|
|Increase verbosity|`-v`|Increase the command verbosity. Using multiple v’s (e.g., -vv) increases the effect.|

## netstat
netstat can display a wide range of information about a machine’s network stack and connections:

```bash
$ netstat
Active internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0    164 my-host:ssh             laptop:50113            ESTABLISHED
tcp        0      0 my-host:50051           example-host:48760      ESTABLISHED
tcp6       0      0 2600:1700:2800:7d:54310 2600:1901:0:bae2::https TIME_WAIT
udp6       0      0 localhost:38125         localhost:38125         ESTABLISHED
Active UNIX domain sockets (w/o servers)
Proto RefCnt Flags   Type    State  I-Node  Path
unix  13     [ ]     DGRAM          8451    /run/systemd/journal/dev-log
unix  2      [ ]     DGRAM          8463    /run/systemd/journal/syslog
[Cut for brevity]
```

Invoking netstat with no additional arguments will display all connected sockets on the machine. In our example, we see three TCP sockets, one UDP socket, and a multitude of UNIX sockets. The output includes the address (IP address and port) on both sides of a connection.

We can use the `-a` flag to show all connections or `-l` to show only listening connections:

```bash
$ netstat -a
Active internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address      State
tcp        0      0 0.0.0.0:ssh             0.0.0.0:*            LISTEN
tcp        0      0 0.0.0.0:postgresql      0.0.0.0:*            LISTEN
tcp        0    172 my-host:ssh             laptop:50113         ESTABLISHED
[Content cut]
```

A common use of netstat is to check which process is listening on a specific port. To do that, we run `sudo netstat -lp - l` for “listening” and p for “program.” sudo may be necessary for netstat to view all program information. The output for `-l` shows which address a service is listening on (e.g., `0.0.0.0` or `127.0.0.1`).

We can use simple tools like grep to get a clear output from netstat when we are looking for a specific result:

```bash
$ sudo netstat -lp | grep 3000
tcp6     0    0 [::]:3000       [::]:*       LISTEN     613/grafana-server
```

**common options**

|Option|Syntax|Description|
|-|-|-|
|Show all sockets|`netstat -a`|Shows all sockets, not only open connections.|
|Show statistics|`netstat -s`|Shows networking statistics. By default, netstat shows stats from all protocols.|
|Show listening sockets|`netstat -l`|Shows sockets that are listening. This is an easy way to find running services.|
|TCP|`netstat -t`|The `-t` flag shows only TCP data. It can be used with other flags, e.g., `-lt` (show sockets listening with TCP).|
|UDP|`netstat -u`|The `-u` flag shows only UDP data. It can be used with other flags, e.g., `-lu` (show sockets listening with UDP).|

## netcat

netcat is a multipurpose tool for making connections, sending data, or listening on a socket. It can be helpful as a way to “manually” run a server or client to inspect what happens in greater detail. netcat is arguably similar to telnet in this regard, though netcat is capable of many more things.

> nc is an alias for netcat on most systems.

netcat can connect to a server when invoked as netcat <address> <port>. netcat has an interactive stdin, which allows you to manually type data or pipe data to netcat. It’s very telnet-esque so far:

```bash
$ echo -e "GET / HTTP/1.1\nHost: localhost\n" > cmd
$ nc localhost 80 < cmd
HTTP/1.1 302 Found
Cache-Control: no-cache
Content-Type: text/html; charset=utf-8
[Content cut]
```

## Openssl

The OpenSSL technology powers a substantial chunk of the world’s HTTPS connections. Most heavy lifting with OpenSSL is done with language bindings, but it also has a CLI for operational tasks and debugging. openssl can do things such as creating keys and certificates, signing certificates, and, most relevant to us, testing TLS/SSL connections. Many other tools, including ones outlined in this chapter, can test TLS/SSL connections. However, openssl stands out for its feature-richness and level of detail.

Commands usually take the form openssl [sub-command] [arguments] [options]. openssl has a vast number of subcommands (for example, openssl rand allows you to generate pseudo random data). The list subcommand allows you to list capabilities, with some search options (e.g., openssl list `--commands` for commands). To learn more about individual sub commands, you can check openssl <subcommand> --help or its man page (man openssl-<subcommand> or just man <subcommand>).

`openssl s_client -connect` will connect to a server and display detailed information about the server’s certificate. Here is the default invocation:

```bash
openssl s_client -connect k8s.io:443
CONNECTED(00000003)
depth=2 O = Digital Signature Trust Co., CN = DST Root CA X3
verify return:1
depth=1 C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
verify return:1
depth=0 CN = k8s.io
verify return:1
---
Certificate chain
0 s:CN = k8s.io
i:C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
1 s:C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
i:O = Digital Signature Trust Co., CN = DST Root CA X3
---
Server certificate
-----BEGIN CERTIFICATE-----
[Content cut]
-----END CERTIFICATE-----
subject=CN = k8s.io

issuer=C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3

---
No client certificate CA names sent
Peer signing digest: SHA256
Peer signature type: RSA-PSS
Server Temp Key: X25519, 253 bits
---
SSL handshake has read 3915 bytes and written 378 bytes
Verification: OK
---
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Server public key is 2048 bit
Secure Renegotiation IS NOT supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 0 (ok)
---
```

If you are using a self-signed CA, you can use -CAfile <path> to use that CA. This will allow you to establish and verify connections against a self-signed certificate.

## cURL
cURL is a data transfer tool that supports multiple protocols, notably HTTP and HTTPS.

> wget is a similar tool to the command curl. Some distros or administrators may install it instead of curl.

cURL commands are of the form curl [options] <URL>. cURL prints the URL’s contents and sometimes cURL-specific messages to stdout. The default behavior is to make an HTTP GET request:

```bash
$ curl example.org
<!doctype html>
<html>
<head>
    <title>Example Domain</title>
# Truncated
```

By default, cURL does not follow redirects, such as HTTP 301s or protocol upgrades. The -L flag (or --location) will enable redirect following:

```bash
$ curl kubernetes.io
Redirecting to https://kubernetes.io

$ curl -L kubernetes.io
<!doctype html><html lang=en class=no-js><head>
# Truncated
```

Use the -X option to perform a specific HTTP verb; e.g., use curl -X 
```bash
DELETE foo/bar to make a DELETE request.
```
You can supply data (for a POST, PUT, etc.) in a few ways:

```bash
URL encoded: -d "key1=value1&key2=value2"
JSON: -d '{"key1":"value1", "key2":"value2"}'
```

As a file in either format: `-d @data.txt`

The -H option adds an explicit header, although basic headers such as Content-Type are added automatically:

```bash
-H "Content-Type: application/x-www-form-urlencoded"
```

Here are some examples:

```bash
$ curl -d "key1=value1" -X PUT localhost:8080

$ curl -H "X-App-Auth: xyz" -d "key1=value1&key2=value2"
-X POST https://localhost:8080/demo
TIP
cURL can be of some help when debugging TLS issues, but more specialized tools such as openssl may be more helpful.

cURL can help diagnose TLS issues. Just like a reputable browser, cURL validates the certificate chain returned by HTTP sites and checks against the host’s CA certs:

$ curl https://expired-tls-site
curl: (60) SSL certificate problem: certificate has expired
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

Like many programs, cURL has a verbose flag, -v, which will print more information about the request and response. This is extremely valuable when debugging a layer 7 protocol such as HTTP:

```bash
$ curl https://expired-tls-site -v
*   Trying 1.2.3.4...
* TCP_NODELAY set
* Connected to expired-tls-site (1.2.3.4) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (OUT), TLS alert, certificate expired (557):
* SSL certificate problem: certificate has expired
* Closing connection 0
curl: (60) SSL certificate problem: certificate has expired

More details here: https://curl.haxx.se/docs/sslcerts.html
# Truncated
```

cURL has many additional features that we have not covered, such as the ability to use timeouts, custom CA certs, custom DNS, and so on.






