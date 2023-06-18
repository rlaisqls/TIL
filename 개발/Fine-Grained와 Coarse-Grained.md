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
