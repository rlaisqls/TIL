
kubernetes node에 쉽게 접속할 수 있도록 하는 kubectl 플러그인이다. 워커노드, 인그레스노드에 접근이 가능하고 root 권한으로 실행이 가능하다. 

### krew 설치하기

node-shell는 krew를 통해 설치할 수 있다.

```bash
# krew 설치하기
$ brew install krew

# krew에 kvaps 추가
$ kubectl krew index add kvaps https://github.com/kvaps/krew-index
```

### node-shell 설치하기

```bash
# node-shell을 설치한다.
$ kubectl krew install kvaps/node-shell
```

### export 추가하기

```bash
# vi 편집기 사용하여 ~/.zshrc or ~/.bash_profile열기 
$ vi ~/.zshrc

# ~/.zshrc or  ~/.bash_profile 하단에 해당 내용 추가하기
$ export PATH="${PATH}:${HOME}/.krew/bin"

# 변경내용 적용하기
$ source ~/.zshrc
$ source ~/.bash_profile
```

### node-shell 접속 확인하기

```bash
# node 확인
$ k get node

# node-shell 을 이용해 접속하기 
$ kubectl node-shell {접속할 node 이름}
```

---
참고
- https://github.com/kvaps/kubectl-node-shell



