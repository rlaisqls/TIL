<img src="https://github.com/rlaisqls/TIL/assets/81006587/dbef4d66-8107-48e8-8767-5a65c7f8a637" height=300px>

Fine-grained는 사전적으로 "결이 고운", "미세한"이라는 의미를 가지고, Coarse-grained는 "결이 거친", "조잡한"의 의미를 가진다. Grain은 곡식 혹은 낱알을 뜻하는데, 알갱이가 거칠고 큼직큼직헌지, 곱고 세밀한지에 따라서 Coarse와 Fine으로 나누어 표현한다고 이해할 수 있다.

# Fine-Grained
- 하나의 작업을 작은 단위의 프로세스로 나눈 뒤, 다수의 호출을 통해, 작업 결과를 생성해내는 방식
- 예를 들어, `Do`라는 동작이 있다면 해당 함수를 `First_Do()`, `Second_Do()`로 나누어 작업 결과를 생성해냄
- 다양한 **"Flexible System"** 상에서 유용하게 쓰일 수 있음

# Coarse-Grained
- 하나의 작업을 큰 단위의 프로세스로 나눈 뒤, "Single Call" 을 통해, 작업 결과를 생성해내는 방식
- 예를 들어, `Do` 라는 동작이 있다면 단순히, `Do()`를 호출해 작업 결과를 생성해내는 방식
- **"Distributed System"** 상에서 유용하게 쓰일 수 있음

---
참고 
- https://coderanch.com/t/99845/engineering/Coarse-grained-fine-grained-objects
