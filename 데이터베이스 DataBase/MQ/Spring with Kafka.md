
Kafka를 설치하여 실행한 뒤([예시](https://github.com/rlaisqls/TIL/blob/984bd2b023d378b4d5879592fbd6115508613072/%EB%8D%B0%EC%9D%B4%ED%84%B0%EB%B2%A0%EC%9D%B4%EC%8A%A4%E2%80%85DataBase/MQ/Docker%EB%A1%9C%E2%80%85Kafka%E2%80%85%EC%8B%A4%ED%96%89.md)) Spring과 연동하여 애플리케이션을 만들어보자.

우선 server host와 port를 지정해주자.

```yml
spring:
  kafka:
    bootstrap-servers: localhost:29092
```

그리고 kafkaConfig를 만들어 Producer와 Comsumer의 bootstrapServer 정보, group, client ID, serializer와 desirializer를 설정해준다. 아래의 코드는 거의 최소 설정으로 구성한 것인데, 보안이나 timeout, partition 등의 설정은 원하는대로 추가해주면 된다.

```kotlin
@EnableKafka
@Configuration
class KafkaConfig {

    @Value("\${spring.kafka.bootstrap-servers}")
    lateinit var bootstrapServer: String

    @Bean
    fun <T> producerFactory(): ProducerFactory<String, Any> {
        val config = mapOf(
            ProducerConfig.BOOTSTRAP_SERVERS_CONFIG to this.bootstrapServer,
            ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG to StringSerializer::class.qualifiedName,
            ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG to JsonSerializer::class.qualifiedName
        )
        return DefaultKafkaProducerFactory(config)
    }

    @Bean
    fun <T> kafkaListenerContainerFactory(): ConcurrentKafkaListenerContainerFactory<String, Any> {
        val config = mapOf(
            ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG to this.bootstrapServer,
            ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG to StringDeserializer::class.qualifiedName,
            ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG to StringDeserializer::class.qualifiedName,
            ConsumerConfig.GROUP_ID_CONFIG to "test-group",
            ConsumerConfig.CLIENT_ID_CONFIG to "test-client"
        )
        val consumerFactory = DefaultKafkaConsumerFactory<String, Any>(config)

        val factory = ConcurrentKafkaListenerContainerFactory<String, Any>()
        factory.setMessageConverter(JsonMessageConverter())
        factory.consumerFactory = consumerFactory
        factory.setConcurrency(1)
        factory.containerProperties.ackMode = ContainerProperties.AckMode.MANUAL

        return factory
    }

    @Bean
    fun <T> kafkaTemplate(): KafkaTemplate<String, Any> {
        return KafkaTemplate(producerFactory<T>())
    }
}
```

큐에 데이터를 발행해줄 api를 하나 만들어준다. 실행한 서버의 이 url에 요청을 보내면 TestPayload 객체가 메세지로 변환되어 test 토픽에 쌓이게 될 것이다.

위의 config에서 `ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG`를 `JsonSerializer`로 설정해주었기 때문에 객체를 넣으면 Json 데이터로 변환되어 저장된다. Json이기 때문에 inner class가 있는 복잡한 객체도 바로 전달할 수 있다.

단, payload로 전송할 객체는 kafka에 저장될 형태로 역직렬화, 직렬화하는 과정이 필요하기 때문에 `Serializable`을 상속받거나 (kotlin에선) data class로 정의해줘야한다. 

> 여기서 사용할 test topic은, kafka에서 따로 생성해주어야한다. 하지만 원한다면 config 코드상에서 topic을 Bean으로 정의하는 방법도 있다. 

```kotlin
@RestController
class KafkaController(
    val kafkaTemplate: KafkaTemplate<String, Any>
) {

    @PostMapping("/kafka/send")
    fun sendKafkaMessage() {
        val message = MessageBuilder
            .withPayload(TestPayload())
            .setHeader(KafkaHeaders.TOPIC, "test")
            .build()
        this.kafkaTemplate.send(message)
    }

    data class TestPayload(
        val name: String = "hello",
        val age: Int = 18,
        val data: TestData = TestData()
    )

    data class TestData(
        val address: String = "earth",
        val phone: Int = 12345678
    )
}
```

test 토픽에 저장된 메시지들을 소비할 consumer 클래스이다. `@KafkaListener` 어노테이션을 달아주면 해당 topic의 메시지를 받아 처리한다. 

group은 config에서 설정한 groupId를 그대로 적은 것인데, 다중 group을 관리하는 것이 목적이 아니기 때문에 큰 의미는 없다.

```kotlin
@Component
class KafkaConsumer {

    @KafkaListener(topics = ["test"], groupId = "test-group")
    fun listener(@Payload request: KafkaController.TestPayload, ack: Acknowledgment) {
        println(request)
        ack.acknowledge()
    }
}
```

클래스 형태 그대로 잘 받아지는 것을 확인할 수 있다.

```log
2023-01-23T12:32:31.018+09:00  INFO 59221 --- [ad | producer-1] org.apache.kafka.clients.Metadata        : [Producer clientId=producer-1] Resetting the last seen epoch of partition test-0 to 0 since the associated topicId changed from null to _zuSLWdTRK2uv0vul3nAxw
TestPayload(name=hello, age=18, data=TestData(address=earth, phone=12345678))
```