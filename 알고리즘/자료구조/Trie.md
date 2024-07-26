
트라이는 문자열을 저장하고 효율적으로 검색하기 위한 트리 기반의 자료조이다. 트라이는 루트 노드부터 시작하고, 각 노드는 문자를 나타낸다. 그리고 문자열은 루트에서 리프 노드까지의 경로로 표현된다.

트라이 자료구조를 사용하면 문자열을 매우 빠르게 검색할 수 있다. 특히 접두사 검색에 효율적이다. (O(m) 시간, m은 문자열 길이). 큰 메모리가 필요하다는 단점이 있다.

접두사를 바탕으로 한 자동 완성이나, 문자열 매칭을 위해 사용할 수 있다.

### 구현

- 트라이의 한 노드를 구성하는 객체는 자손 노드를 가리키는 포인터 목록과, 문자열의 끝인지를 나타내는 bool 변수로 구성된다. 자손 노드 포인터를 저장하기 위해 맵이나 벡터를 사용할 수 있다.

```c
struct Trie {
	map<char, Trie*> ch; // 맵을 이용하는 경우
   	//vector<pair<char, Trie*>> ch; 벡터를 이용하는 경우
	bool end; 
}
```

- 문자열을 트라이에 넣어주는 함수에선 이미 트라이에 다음 문자에 해당하는 노드가 있는 경우 해당 노드를 따라가고, 없는 경우 새로 노드를 만들어서 따라가는 식으로 구현한다.
    
    그리고 문자열의 끝에 도착한 경우에는 끝을 나타내는 boolean 변수를 true로 설정한다.
     
    ```c
    void insert(const char* s) {
        if (!*s) {
            this->end = true;
            return;
        }
        int now = *s - 'A';
        if (!ch[now]) ch[now] = new Trie;
        ch[now]->insert(s + 1);
    }
    ```

- 트라이에 찾고자 하는 문자열이 있는지를 탐색하는 함수이다. 만약 다음 문자로 가는 노드가 현재 노드의 자손으로 존재하지 않는다면, 탐색에 실패한 경우이다.
  
    계속 탐색하다가 문자열의 끝에 도착했을 때 해당 노드의 bool 변수가 참이라면, 탐색에 성공한 것이다.

    ```c
    bool find(const char* s) {
        if (!*s) {
            if (end) return true;
            return false;
        }
        int now = *s - 'A';
        if (!ch[now]) return false;
        return ch[now]->find(s + 1);
    }
    ```

- 트라이 문제를 [백준](https://www.acmicpc.net/problemset?sort=ac_desc&algo=79)에서 풀어볼 수 있다.

---
참고
- https://www.digitalocean.com/community/tutorials/trie-data-structure-in-c-plus-plus
- https://www.geeksforgeeks.org/trie-insert-and-search/
- https://eun-jeong.tistory.com/29