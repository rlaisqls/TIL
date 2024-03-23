
> https://github.com/google/pprof?ref=pangyoalto.com

Profiling은 메모리 사용량, 함수별 CPU 점유 시간, tracing 등 어플리케이션을 동적으로 분석하는 것을 말한다. 서비스를 운영하는데 메모리 누수가 점점 쌓이거나 혹은 특정 로직 실행이 너무 오래걸릴 때 등 문제의 원인 파악을 용이하게 해준다.

pprof는 Go 어플리케이션 데이터를 profiling해 분석하는 도구이다. Callstack과 symbolization 정보가 담겨있는 프로토콜 버퍼를 분석한다. Go로 만든 어플리케이션은 pprof를 이용해 편리하게 profiling을 할 수 있다. 

### 분석할 수 있는 정보

분석할 수 있는 항목들은 다음과 같다.

- **allocs**: 메모리 할당을 샘플링한다.
- **block**: 동기화 메커니즘(synchronization primitives)에서 발생한 blocking을 trace한다.
- **cmdline**: 프로그램에서 발생한 command line 호출을 알 수 있다.
- **goroutine**: 모든 현재 고루틴들을 stack trace한다.
- **heap**: 메모리에 할당된 살아있는 오브젝트들을 샘플링한다.
- **mutex**: 충돌된 뮤텍스 홀더들의 stack trace를 할 수 있다.
- **profile**: CPU를 profile할 수 있다.
- **threadcreate**: 새로 만들어진 OS thread에 대한 stack trace를 한다.
- **trace**: 현재 프로그램 실행에 대한 trace이다.

### 실습

profiling을 하려면 어플리케이션의 main.go에서 `net/http/pprof`를 링크하고, 접속할 수 있는 포트를 하나 뚫어놓아야 한다.

```go
package main

import (
    "http"
    _ "net/http/pprof"
    ...
)

func main() {
    ...
    
    go func() {
     http.ListenAndServe("0.0.0.0:6060", nil)
    }()
    
    ...
}
```

`net/http/pprof`를 링크하면 init 함수에서 수집한 pprof를 템플릿에 담아 `/debug/pprof` 로 노출시킨다. Index 함수에서 사용하는 `pprof.Profile`은 runtime 패키지를 이용해 cpu 데이터, heap 사용량, 고루틴 개수 등을 수집한다.

```go
// net/http/pprof/pprof.go
func init() {
  http.HandleFunc("/debug/pprof/", Index)
  http.HandleFunc("/debug/pprof/cmdline", Cmdline)
  http.HandleFunc("/debug/pprof/profile", Profile)
  http.HandleFunc("/debug/pprof/symbol", Symbol)
  http.HandleFunc("/debug/pprof/trace", Trace)
}

// Index responds with the pprof-formatted profile named by the request.
// For example, "/debug/pprof/heap" serves the "heap" profile.
// Index responds to a request for "/debug/pprof/" with an HTML page
// listing the available profiles.
func Index(w http.ResponseWriter, r *http.Request) {
  if strings.HasPrefix(r.URL.Path, "/debug/pprof/") {
    name := strings.TrimPrefix(r.URL.Path, "/debug/pprof/")
    if name != "" {
      handler(name).ServeHTTP(w, r)
        return
      }
    }
    
    type profile struct {
      Name  string
      Href  string
      Desc  string
      Count int
    }
    
    var profiles []profile
    for _, p := range pprof.Profiles() {
      profiles = append(profiles, profile{
        Name:  p.Name(),
        Href:  p.Name() + "?debug=1",
        Desc:  profileDescriptions[p.Name()],
        Count: p.Count(),
      })
    }
    
    // Adding other profiles exposed from within this package
    for _, p := range []string{"cmdline", "profile", "trace"} {
      profiles = append(profiles, profile{
        Name: p,
        Href: p,
        Desc: profileDescriptions[p],
      })
    }
    
    sort.Slice(profiles, func(i, j int) bool {
      return profiles[i].Name < profiles[j].Name
    })
    
    if err := indexTmpl.Execute(w, profiles); err != nil {
      log.Print(err)
    }
}
```

위에서 6060 포트로 서버를 뚫었기 때문에, `localhost:6060/debug/pprof`로 접속하면 pprof가 수집한 데이터들을 볼 수 있다.

<img width="437" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/81e4d8f8-3d1b-4ac7-815b-d72b7436638d">

`localhost:6060/debug/pprof`로 위와 같은 페이지를 볼 수 있다. 하이퍼링크를 눌러보면 수집한 데이터를 확인할 수 있다. `/debug/pprof/heap?seconds=30`과 같이 몇 초 동안 profiling 할지도 지정하여 조회할 수 있다.

### go tool

이렇게 분석할 수도 있지만 좀 더 편하게 보기 위하여 go에서 지원하는 go tool을 사용할 수도 있습니다. go tool을 shell에 치시면 다음과 같은 도구들 목록이 나온다.

```bash
$ go tool
addr2line
...
pprof
test2json
trace
vet
```

go tool pprof를 이용해 서버에서 profile 파일을 받아와 분석해보자.

- **goroutine 분석**
  
    ```bash
    $ go tool pprof http://0.0.0.0:6060/debug/pprof/goroutine
    Fetching profile over HTTP from http://0.0.0.0:6060/debug/pprof/goroutine
    Saved profile in /home1/user/pprof/pprof.application.goroutine.001.pb.gz
    ...
    (pprof) top 10
    ```
- **heap alloc 분석**

    ```
    $ go tool pprof http://0.0.0.0:6060/debug/pprof/heap
    Fetching profile over HTTP from http://0.0.0.0:6060/debug/pprof/heap
    Saved profile in /home1/irteam/pprof/pprof.application.alloc_objects.alloc_space.inuse_objects.inuse_space.001.pb.gz
    ...
    (pprof)
    ```

interactive 모드로 들어가면 커맨드를 사용해 더 상세히 분석을 할 수도 있다. 


### graphviz 시각화

graphviz라는 툴을 사용하면 pprof로 시각화 자료를 만들 수 있다. 다음 커맨드를 통해 graphviz를 설치해보자.

```bash
$ sudo yum install graphviz
```

go tool pprof를 이용해 시각화하는 방법은 아래와 같다.

```bash
$ go tool pprof -http [address:port] [Profile File]
$ go tool pprof -http [address:port] [Profile HTTP Endpoint]
```


아래 명령어를 사용하면 생성된 profile 시각화 자료를 0.0.0.0:8080으로 볼 수 있디.
```bash
go tool pprof -http 0.0.0.0:8080 http://0.0.0.0:6060/debug/pprof/heap
```

- **결과 예시**
  
    <img width="437" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/6aa8fc33-c54a-4c7d-891f-bd8048d7c4ab">


위 예시는 heap을 통해 함수별 메모리를 본 것이지만 함수별 걸린 시간을 측정할 수도 있다.

### trace

go tool에서 trace라는 profiling 도구 또한 사용할 수 있다. trace는 고루틴, Heap의 사용이나 각 프로세스가 어떤 일을 했는지 time series로 볼 수 있게 도와준다. trace도 pprof와 마찬가지로 profile 프로토콜 버퍼를 받아와야 한다.

```bash
 go tool trace -http 0.0.0.0:8080 http://0.0.0.0:6060/debug/pprof/trace?seconds=30
```

완료된 후 포트로 들어가면 다음과 같은 분석 화면을 볼 수 있다.

<img width="437" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/dfed79d1-e9d6-4858-9190-6213684bf3f7">

---
참고
- https://github.com/DataDog/go-profiler-notes/blob/main/guide/README.md?ref=pangyoalto.com
- https://ssup2.github.io/programming/Golang_Profiling/?ref=pangyoalto.com
- https://pkg.go.dev/net/http/pprof?ref=pangyoalto.com