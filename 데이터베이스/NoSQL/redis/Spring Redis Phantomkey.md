
**spring**에서 @RedisHash로 refreshToken 등을 저장하면, 일반 키와 `phantom`키가 함께 저장되는 것을 볼 수 있다.

![image](https://user-images.githubusercontent.com/81006587/197697420-7e8f520a-c468-4566-9d9f-67844d6a0f6d.png)

여기서 Phantom Key는 영속성 설정을 위한 복사본으로, 원본 복사본이 만료되고 5분 후에 만료되도록 설정된다.

Spring에서 영속성 설정을 위해서 임의적으로 생성되는 것이다. 원래 해시가 만료되면 Spring Data Redis는 팬텀 해시를 로드하여 보조 인덱스에서 참조 제거 등의 정리를 수행한다.

자세한 것은 <a href="https://docs.spring.io/spring-data/redis/docs/current/reference/html/#redis.repositories.expirations">Spring Redis</a>의 공식문서에서 확인할 수 있다.

> When the expiration is set to a positive value the according EXPIRE command is executed. Additionally to persisting the original, a phantom copy is persisted in Redis and set to expire 5 minutes after the original one. This is done to enable the Repository support to publish RedisKeyExpiredEvent holding the expired value via Springs ApplicationEventPublisher whenever a key expires even though the original values have already been gone. Expiry events will be received on all connected applications using Spring Data Redis repositories.
