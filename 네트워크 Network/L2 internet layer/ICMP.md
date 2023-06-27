# ICMP

- Internet Control Message Protocol (ICMP) is a network layer protocol used by network devices to diagnose network communication problems.

- Typically, ICMP protocols are used by network devices such as routers. 
  
- ICMP is primarily used to determine whether data reaches the intended target in a timely manner. Ping applications that use ICMP packets are used by network administrators to test network hardware devices such as computers, printers, and routers. Ping is typically used to verify that the device is functioning and to track the time it takes for messages to return from the source device to the destination and to return to the source.

- The main purpose of ICMP is **to report errors**. When the two devices are connected over the Internet, ICMP generates an error to share with the device it sends if the data does not reach its intended destination. For example, if a data packet is too large for a router, the router drops the packet and returns the ICMP message to the original source of the data.

- The secondary use of the ICMP protocol is **to perform network diagnostics**. Both commonly used terminal utilities traceRoute and ping operate using ICMP. The traceroute utility is used to display the routing path between two Internet devices, which is the actual physical path of the connected router that must pass before the request reaches the destination. The journey between one router and another is called a 'hop', and traceroute also reports the time required for each hop during the journey. This can be useful for determining the cause of network delays.-

---
reference
- https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol
- https://www.cloudflare.com/ko-kr/learning/ddos/glossary/internet-control-message-protocol-icmp/