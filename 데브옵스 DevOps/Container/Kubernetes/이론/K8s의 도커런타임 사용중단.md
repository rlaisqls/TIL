# ⚓ K8s의 도커 런타임 사용중단

![image](https://user-images.githubusercontent.com/81006587/201903310-cec614e1-d458-40be-afc3-9df77529e4d5.png)

Source : https://kubernetes.io/blog/2020/12/02/dont-panic-kubernetes-and-docker/

쿠버네티스는 버전 v1.20 이후 Docker를 컨테이너 런타임으로서 사용하지 않겠다고 알렸다.(`2020.12.02`)

GKE 및 EKS 등의 관리 Kubernetes 서비스를 사용하는 경우 오퍼레이터에서 지원되는 버전의 런타임을 사용하는 것을 확인하고 쿠버네티스 릴리스에서 도커 지원이 만료되기 전에 변경 해야한다.

자세한 내용은 아래와 같다.

> Deprecation<br/>Docker support in the kubelet is now deprecated and will be removed in a future release. The kubelet uses a module called “dockershim” which implements CRI support for Docker and it has seen maintenance issues in the Kubernetes community. We encourage you to evaluate moving to a container runtime that is a full-fledged implementation of CRI (v1alpha1 or v1 compliant) as they become available. (#94624, @dims) [SIG Node]

쿠버네티스는 컨테이너 런타임과 통신 할 때 CRI라는 표준 인터페이스 API를 사용하지만 Docker는 이를 지원하지 않는다.

이런 이유로 쿠버네티스는 “dockershim”라는 브리지용 서비스로 Docker API와 CRI의 변환을 해주었으나, 이것이 deprecation 되면서 앞으로 마이너 릴리스 된 후에 도커가 삭제될 예정이다. 라는 뜻의 글이다.

## 쿠버네티스는 왜 도커 지원을 중단했을까?

가장 큰 이유는 도커는 CRI(Container Runtime Interface) 와 호환성이 없다는 것이다. (CRI와 컨타이너 런타임에 대한 내용은 <a href="https://github.com/rlaisqls/TIL/blob/main/%EB%8D%B0%EB%B8%8C%EC%98%B5%EC%8A%A4%20DevOps/%EC%BB%A8%ED%85%8C%EC%9D%B4%EB%84%88%20%EB%9F%B0%ED%83%80%EC%9E%84.md">여기</a>에서 더 알아볼 수 있다.)

Docker는 Kubernetes에 통합되도록 설계되어 있지 않기 때문에 많은 문제가 있다.

쿠버네티스에서 도커를 사용하기 위해 필요한 Dockershim 은 유지 보수 비용이 높다는 지적이 있었고, 도커는 쿠버네티스에서는 사용하지 않는 많은 기능들이 포함되어 있어 자원의 오버 헤드가 높다는 문제로 런타임으로써의 지원을 중단한 것이다.

## 도커를 사용하던 사용자에게 어떤 영향을 미치는 걸까?

개발용으로 Docker 를 사용하는 것은 쿠버네티스 클러스터의 런타임과는 아무 상관이 없다.

또한 OCI 표준을 준수하는 이미지는 도구에 관계없이 쿠버네티스에서 동일하게 사용할 수 있다. containerd와 CRI-O는 기존 도커 이미지와 호환성이 뛰어나다.

이것이 바로 컨테이너 표준이 만들어진 이유이다.

---

정리하자면, K8s 내부에서 도커라는 컨테이너 런타임을 사용하지 않겠다는 것이다. 

개발과정에서 도커를 사용하고, 도커에서 이미지를 빌드하는 것은 괜찮다. (OCI 표준을 지키고 있기 때문)
