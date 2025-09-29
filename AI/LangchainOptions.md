Langchain의 Chain은 여러 LLM 호출이나 다른 유틸리티들을 연결하여 복잡한 작업을 수행할 수 있게 해주는 핵심 구성 요소이다.

## Chain 실행 옵션

- **early_stopping_method**: Chain이 중간에 중단될 때 사용할 전략을 설정하는 옵션이다.
  - `"generate"`: 현재까지 생성된 결과를 반환한다.
  - `"force"`: 강제로 중단하고 빈 결과를 반환한다.
  
  ```python
  from langchain.chains import LLMChain
  
  chain = LLMChain(...)
  result = chain.run(
      input="질문",
      early_stopping_method="generate"
  )
  ```
  
  - `"generate"` 방식은 부분적인 결과라도 활용할 수 있어 유용하다.
  - `"force"` 방식은 완전한 결과가 필요할 때 사용한다.
  - 기본값은 체인 유형에 따라 달라진다.

- **max_tokens**: 생성할 최대 토큰 수를 제한하는 옵션이다.
  
  ```python
  result = chain.run(
      input="질문",
      max_tokens=500
  )
  ```

- **temperature**: 응답의 무작위성을 조절하는 옵션이다.
  
  ```python
  result = chain.run(
      input="재밌는 얘기 해줘",
      temperature=0.8
  )
  ```
  
  - 0에 가까울수록 일관되고 예측 가능한 결과를 생성한다.
  - 1에 가까울수록 창의적이고 다양한 결과를 생성한다.
  - 사실적 정보가 필요할 때는 낮은 값(0.1-0.3)을 사용한다.
  - 창작 작업에는 높은 값(0.7-0.9)을 사용한다.

- **stop_sequences**: 특정 문자열이 나타나면 생성을 중단하는 옵션이다.
  
  ```python
  result = chain.run(
      input="질문",
      stop_sequences=["END", "완료", "\n\n"]
  )
  ```
  
  - `max_tokens`와 `stop_sequences`는 함께 사용할 때 먼저 도달하는 조건으로 중단된다.
  - 원하지 않는 내용이 생성되는 것을 방지할 수 있다.
  - 여러 개의 중단 시퀀스를 동시에 설정할 수 있다.
  - 형식화된 출력을 만들 때 유용하다.

- **streaming**: 실시간으로 결과를 스트리밍할지 설정하는 옵션이다.
  
  ```python
  def handle_stream(token):
      print(token, end="", flush=True)
  
  result = chain.run(
      input="긴 설명을 해줘",
      streaming=True,
      callbacks=[handle_stream]
  )
  ```

- **memory**: 대화 기록이나 컨텍스트를 유지하는 옵션이다.
  
  ```python
  from langchain.memory import ConversationBufferMemory
  
  memory = ConversationBufferMemory()
  result = chain.run(
      input="질문",
      memory=memory
  )
  ```

- **callbacks**: 실행 중 특정 이벤트에 대한 콜백을 설정하는 옵션이다.
  
  ```python
  from langchain.callbacks import StdOutCallbackHandler
  
  callbacks = [StdOutCallbackHandler()]
  result = chain.run(
      input="질문",
      callbacks=callbacks
  )
  ```

- **return_only_outputs**: 입력 정보를 제외하고 출력만 반환할지 설정하는 옵션이다.
  
  ```python
  result = chain.run(
      input="질문",
      return_only_outputs=True
  )
  ```

## 예시

```python
from langchain.chains import LLMChain
from langchain.llms import OpenAI
from langchain.prompts import PromptTemplate

template = "다음 주제에 대해 설명해줘: {topic}"
prompt = PromptTemplate(template=template, input_variables=["topic"])
llm = OpenAI()

chain = LLMChain(llm=llm, prompt=prompt)

result = chain.run(
    topic="인공지능",
    max_tokens=300,
    temperature=0.7,
    early_stopping_method="generate"
)

from langchain.memory import ConversationBufferMemory
from langchain.callbacks import StdOutCallbackHandler

memory = ConversationBufferMemory()
callbacks = [StdOutCallbackHandler()]

result = chain.run(
    topic="머신러닝",
    max_tokens=500,
    temperature=0.5,
    stop_sequences=["---", "결론"],
    memory=memory,
    callbacks=callbacks,
    return_only_outputs=True,
    streaming=True
)
```

---
참고

- <https://python.langchain.com/docs/modules/chains/>
- <https://api.python.langchain.com/en/latest/chains/langchain.chains.base.Chain.html>
- <https://docs.langchain.com/docs/components/chains/>
