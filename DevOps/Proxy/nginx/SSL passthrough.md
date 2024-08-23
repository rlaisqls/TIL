> <https://github.com/NginxProxyManager/nginx-proxy-manager/issues/853>

- Only way to have ssl passthrough is by using a stream host.

- And Nginx can't run a stream on the same port as other proxies. It's one stream per port, and a port with a stream attached can't have any other proxies attached.

- We can work around this by routing all HTTPS traffic through this single stream, which in turn forwards it either to the ssl passthrough server or back to nginx itself on a different port, which can now handle all normal proxies. As you can imagine this will come with a performance penalty of all other proxies being proxied twice, and it might become a bottleneck.

- If you want to distinguish destinations based on domains in one stream, you can use the method below.

    ```
    map $ssl_preread_server_name $name {
        backend.example.com     backend;
        backend2.example.com    backend2;
        default                 npm;
    }

    upstream backend {
        server 192.168.0.1:443;
    }

    upstream backend2 {
        server 192.168.0.3:443;
    }

    upstream npm {
        server localhost:443;
    }

    server {
        listen      12346;
        proxy_pass  $name;
        ssl_preread on;
    }
    ```

- For some reason, the [server_name](http://nginx.org/en/docs/stream/ngx_stream_core_module.html#server_name) of the stream module seems to not work in some cases.

----
reference

- <https://github.com/NginxProxyManager/nginx-proxy-manager/issues/853>
- <http://nginx.org/en/docs/stream/ngx_stream_core_module.html>
- <https://serversforhackers.com/c/tcp-load-balancing-with-nginx-ssl-pass-thru>

