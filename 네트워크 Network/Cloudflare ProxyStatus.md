
Proxy status는 Cloudflare가 DNS의 레코드를 어떻게 관리하느냐에 대한 것이다.

만약 `A`, `AAAA`, 혹은 `CNAME` record에 Proxy status를 Proxied라고 설정하게 된다면, DNS 쿼리를 날렸을때 실제 IP가 아닌 Cloudflare Anycast IP를 먼저 거치게 한다.

이 과정에서 Cloudflare는 요청을 최적화하여 캐시하거나, DDos 공격으로부터 지켜준다.

요청이 오리진 서버에 도달하기 전에 Cloudflare를 통해 전송되기 때문에, 모든 요청의 헤더에는 Cloudflare의 IP 주소(차단되거나 속도가 제한될 수 있음)가 담기게 된다. 프록시된 레코드를 사용하는 경우 Cloudflare IP를 허용하도록 서버 구성을 조정해야 할 수 있다.

https://developers.cloudflare.com/dns/manage-dns-records/reference/proxied-dns-records/