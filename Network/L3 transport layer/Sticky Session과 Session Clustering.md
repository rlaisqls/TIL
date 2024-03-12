
Load balancing이란 대용량 트래픽을 장애 없이 처리하기 위해 여러 대의 서버에 적절히 트래픽을 분배하는 것이다. 이러한 서비스에서는 세션 관리에 문제가 생길 수 있다.

예를 들어, 로그인 정보를 한 서버의 세션에 저장했는데 다음 요청을 다른 서버에 보내는 경우에 로그인 정보가 사라지는 문제가 생긴다. 이러한 문제를 해결하기 위해 특정 클라이언트의 요청을 처음 처리한 서버로만 보내는 것을 **Sticky Session**이라 말한다.

일반적으로 특정 서버로 요청 처리를 고정시키는 방법은 Cookie를 사용하거나 클라이언트의 IP tracking 하는 방식이 있다. AWS ELB는 cookie를 사용하여 Http Response에 cookie를 이용해서 해당 클라이언트가 가야하는 EC2 instance의 정보를 저장해두고, 그걸 활용하여 특정 EC2로 요청을 고정한다.

Sticky Session의 단점은 이러한 것들이 있다.
- 로드밸런싱이 잘 동작하지 않을 수 있다
- 특정 서버만 과부하가 올 수 있다.
- 특정 서버 Fail시 해당 서버에 붙어 있는 세션들이 소실될 수 있다.

## Session Clustering

LB에서 세션문제를 해결하기 위한 다른 방법으론 Session Clustering이 있다. Session Clustering은 여러 서버의 세션을 묵어서 하나의 클러스터로 관리하는 것이다. 

하나의 서버에서 fail이 발생하면 해당 WAS가 들고 있던 세션은 다른 WAS로 이동되어 그 WAS가 해당 세션을 관리하게 된다. 

하지만 이 방식은 scale out 관점에서 새로운 서버가 하나 뜰 때마다 기존에 존재하던 WAS에 새로운 서버의 IP/Port를 입력해서 클러스터링 해줘야 하는 단점이 있다.

그렇기 때문에 Session server를 Redis로 따로 두고 관리하는 방식도 있다. Redis Session 서버의 중요성이 올라가고, 해당 세션 서버가 죽는 순간 모든 세션이 사라지기 때문에 이 Redis 서버의 다중화도 고려해보아야 한다.

---
참고
- https://aws.amazon.com/ko/blogs/aws/new-elastic-load-balancing-feature-sticky-sessions/