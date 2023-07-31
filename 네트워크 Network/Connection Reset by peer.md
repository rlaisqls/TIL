# Connection Reset by peer

Connection Reset by peer means the remote side is terminating the session. This error is generated when the OS receives notification of TCP Reset (RST) from the remote peer.

Connection reset by peer means the TCP stream was abnormally closed from the other end. A TP RST received and the connection is noe clodes, This occurs when **a packet is sent from our end of the connection but the other end does not recognize the connection**; it will send back a packet with the RST bit set is order to forcibly close the connection.

“Connection reset by peer” is the TCP/IP equivalent of slamming the phone back on the hook. It’s more polite than merely not replying, leaving one hanging. But it’s not the FIN-ACK expected of the truly polite TCP/IP.

## Understanding RST TCP Flag

RST is used to abort connections. It is very useful to troubleshoot a network connection problem.

RST (Reset the connection) Indicates that the connection is being aborted. For active connections, a node sends a TCP segment with the RST flag in response to a TCP segment received on the connection that is incorrect, causing the connection to fail.

The sending of an RST segment for an active connection forcibly terminates the connection, causing data stored in send and receive buffers or in transit to be lost. For TCP connections being established, a node sends an RST segment in response to a connection establishment request to deny the connection attempt. The sender will get Connection Reset by peer error.