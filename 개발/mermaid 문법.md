# mermaid
mermaid로 그릴 수 있는 다이어그램은 아래와 같은 것들이 있다.

- 플로우 차트 (Flowchart)
- 시퀀스 다이어그램 (Sequence Diagram)
- 간트 차트 (Gantt Chart)
- 클래스 다이어그램 (Class Diagram)
- User Journey Diagram
- Git graph
- Entity Relationship Diagram

## 플로우 차트(Flowcharts)

모든 플로우 차트는 각 상태를 나타내는 Node와 Node를 방향이 있는 선 또는 방향이 없는 선으로 이어주는 간선(Edge)으로 구성된다. 우리는 mermaid를 통해 다양한 화살표, 간선 타입 그리고 서브 그래프를 사용하고, 플로우차트를 간단하게 그려낼 수 있다.

```java
flowchart LR
    A[구매] --> B;
    B[유저, 파라미터, \n 어뷰징 검증] --> C;
    C{client가 안드로이드} -->|Yes| E;
    C -->|No| G;
    E[안드로이드 Proxy 처리] --> G;
    G[DB 저장] --> I;
    I[응답 반환];
```

## 플로우차트 선언

mermaid에서는 항상 그리고자 하는 다이어그램 종류를 위레 명시해주어야 한다.

그리고 플로우차트일 경우에는 `flowchart`를 적고, 그려질 방향을 선언해준다. 아래 코드는 플로우차트를 그리고 그 방향은 왼쪽에서 오른쪽으로 향한다는 선언이다.

```java
flowchart LR
```

선언할 수 있는 방향은 아래와 같다.

- TB(= TD) : 위에서 아래로
- BT : 아래에서 위로
- RL : 오른쪽에서 왼쪽으로
- LR : 왼쪽에서 오른쪽으로

## 노드(Node) 선언

아래 코드는 플로우차트에 노드를 하나 선언한 것이다. id는 해당 노드를 가리키는 값이며 [] 사이에 있는 값은 해당 노드에 표시될 값이다. 해당 값이 없으면 id가 노출된다.

```java
flowchart LR
    id[구매]
```

```java
flowchart LR
    구매
```

위의 코드를 작성하게되면 아래와 같은 노드하나가 그려진다.

노드는 다양한 형태로 선언할 수 있다.

```java
flowchart LR
    id[(Database)]

flowchart LR
    id{조건}
```

## 간선(Edge) 선언

노드와 노드를 이어주는 간선을 선언해보자. 간선은 기본적으로 -->를 통해서 선언할 수 있다. 이렇게 선언하면 그래프로써 화살표가 있는 간선이 그려지게 된다. 아래 코드는 Service라는 이름을가진 A 노드에서 Database라는 이름을 가지고 있는 B 노드로의 화살표 간선이 생기는 플로우차트이다. 그리고 B와 C 사이에는 방향이 없는 간선을 하나 두었다.

```java
flowchart LR
    A[Service]
    B[(Database_1)]
    C[(Database_2)]
    A --> B --- C
```

간선을 다른 형태로 표시할 수도 있다.

### 점선 화살표

```java
flowchart LR
    C -.-> id2{box}
```

### 간선에 텍스트 추가

```java
flowchart LR
    A-->|의존|B
```

그리고 한 노드에서 여러개의 노드와 연결하는 것도 가능하다. 아래는 A 노드를 B와 C에 연결하는 방법이다.

```java
flowchart LR
    A[Service]
    B[(Database_1)]
    C[(Database_2)]
    A-->B
    A-->C
```

더 자세하고 다양한 사용법은 공식 문서를 참고하자.

- https://mermaid.js.org/syntax/flowchart.html#links-between-nodes
- https://mermaid.js.org/syntax/classDiagram.html
- https://mermaid.js.org/syntax/entityRelationshipDiagram.html