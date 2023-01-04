# 🧸 Mock과 Spy

Mockito 등의 라이브러리를 쓰다보면, Mock과 Spy를 사용하게 될 것이다. 둘 다 클래스의 **가상 객체**를 만들어서 메소드와 필드를 모의 실험하기 위해 쓰인다는 공통점이 있다.

그렇다면 차이점은 무엇일까?

## 비교

간단히 말하자면, Mock은 완벽한 가짜 객체를 만드는데 반해, Spy는 기본적으로 기존에 구현되어있는 동작을 따르지만 일부 메소드만 stub 한다.

Mock 객체의 함수를 호출했을때 그 함수에 stub된 동작이 없으면 코드나 라이브러리에 따라 문제가 생길 수 있다. strict 하게 규칙이 설정된 라이브러리(`ex. mockk`)의 경우에는 호출 즉시 예외가 던져질 수 있고, null이나 기본값 (`int = 0, String = ""...`)이 반환되도록 되어있을 수도 있다.(`ex. mockito`)

하지만 Spy는 그렇지 않다. 내부에 구현된 메소드가 있다면 그것의 코드를 그대로 실행한다. 실제로 그 클래스의 객체가 존재하는 것과 똑같지만, 일부 메서드의 동작만 바꿔주는게 가능한 것이다.

> stub이란, 해당 메소드(또는 필드)를 호출했을 때 반환해야 하는 값을 미리 지정하는 것을 뜻한다.<br>https://martinfowler.com/bliki/TestDouble.html

---

아래는 mockito를 사용해 **mock과 spy를 비교**해보는 코드이다.

```java
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.runners.MockitoJUnitRunner;
 
import java.util.ArrayList;
import java.util.List;
 
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.when;
 
@RunWith(MockitoJUnitRunner.class)
public class MockSpy {
 
    @Mock
    private List<String> mockList;
 
    @Spy
    private List<String> spyList = new ArrayList();
 
    //Mock : add와 get은 stub되지 않은 동작이기 때문에 아무것도 하지 않고, 반환값으론 null을 return한다.
    @Test
    public void testMockList() {
        mockList.add("test");
        assertNull(mockList.get(0));
    }
 

    //Spy : add와 get은 stub되지 않은 동작이기 때문에 기존 List의 메서드 동작을 똑같이 수행한다.
    @Test
    public void testSpyList() {
        spyList.add("test");
        assertEquals("test", spyList.get(0));
    }
 
    //Mock : get(100)을 호출하면 "Mock 100"을 반환하도록 설정해주었기 때문에,
    //       파라미터로 100이 들어왔을때 그 값을 반환한다.
    @Test
    public void testMockWithStub() {
        String expected = "Mock 100";
        when(mockList.get(100)).thenReturn(expected);
 
        assertEquals(expected, mockList.get(100));
    }
 
    //Spy : get(100)을 호출하면 "Mock 100"을 반환하도록 설정해주었기 때문에,
    //      파라미터로 100이 들어왔을때 기존 List의 메서드 실행결과가 아닌 그 값을 반환한다.
    @Test
    public void testSpyWithStub() {

        String expected = "Spy 100";
        doReturn(expected).when(spyList).get(100);
 
        assertEquals(expected, spyList.get(100));
    }
}
```

---

mockk에서는 mock 메서드 호출에 대한 설정이 `strict`하기 때문에 어떤 메소드를 호출하고 싶다면 stub을 꼭 만들어주거나 별도의 설정을 해줘야한다.

mockk는 Unit을 반환하는, 즉 return 값이 없는 메서드에 대해서도 stub을 필요로 하기 때문에 아래와 같은 상황에서도 예외가 던져진다.

```kotlin
 @Service
class DeleteUserUseCase(
    private val documentRepository: DocumentRepository
) {

    fun execute(documentId: UUID) {

        val document = documentRepository.findByIdOrNull(documentId)?: throw DocumentNotFoundException

        documentRepository.delete(document) //void delete(T entity);
    }
}
```

그렇기 때문에 이런 상황에서는 아래와 같이 설정해주거나

```kotlin
    every { documentRepository.delete(document) } returns Unit
    justRun { documentRepository.delete(document) }
```

`relaxUnitFun` 설정을 `true`로 해줘서, 반환값이 없는 메소드는 stub 없이도 실행할 수 있도록 해줘야한다.

반환값 없는 메서드가 아니더라도, 엄격하게 Exception을 던지지 않도록 하는 `relaxed` 설정도 있다.

```kotlin
inline fun <reified T : Any> mockk(
    name: String? = null,
    relaxed: Boolean = false,
    vararg moreInterfaces: KClass<*>,
    relaxUnitFun: Boolean = false,
    block: T.() -> Unit = {}
): T = MockK.useImpl {
    MockKDsl.internalMockk(
        name,
        relaxed,
        *moreInterfaces,
        relaxUnitFun = relaxUnitFun,
        block = block
    )
}
```

relaxed 설정을 하면

Unit 메서드 : Unit
반환값 있는 메서드
- 반환값이 nullable Type(`?`) : null
- 반환겂이 not nullable : 임의의 값

이런식으로 반환하는 것 같다.

```kotlin
    protected open fun defaultAnswer(invocation: Invocation): Any? {
        return stdObjectFunctions(invocation.self, invocation.method, invocation.args) {
            if (shouldRelax(invocation)) { //Relax 
                if (invocation.method.returnsUnit) return Unit
                return gatewayAccess.anyValueGenerator().anyValue(
                    invocation.method.returnType,
                    invocation.method.returnTypeNullable
                ) {
                    childMockK(invocation.allEqMatcher(), invocation.method.returnType)
                }
            } else {
                throw MockKException("no answer found for: ${gatewayAccess.safeToString.exec { invocation.toString() }}")
            }
        }
    }

    private fun shouldRelax(invocation: Invocation) = when {
        relaxed -> true
        relaxUnitFun &&
                invocation.method.returnsUnit -> true
        else -> false
    }
```

```
open class AnyValueGenerator {
    open fun anyValue(cls: KClass<*>, isNullable: Boolean, orInstantiateVia: () -> Any?): Any? {
        return when (cls) {
            Boolean::class -> false
            Byte::class -> 0.toByte()
            Short::class -> 0.toShort()
            Char::class -> 0.toChar()
            Int::class -> 0
            Long::class -> 0L
            Float::class -> 0.0F
            Double::class -> 0.0
            String::class -> ""
            ...
        }
    }
}
```