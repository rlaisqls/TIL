
- GTM은 ‘코드추적을 용이하게 해주는 도구이자 태그 관리 툴’이다.
- 기존에는 Google Analytics(GA), 페이스북 픽셀 등과 같은 트래킹 툴을 각각 설정해야 했다. 하지만 GTM은 트래킹을 위한 코드의 삽입, 수정, 삭제 모두를 효율적으로 관리할 수 있게 해준다.
- GTM 코드만 삽입하면, 새로운 마케팅 툴을 여러 개 추가하더라도 추가적인 코드작업 없이 손쉽게 설치 할 수 있다.

## 핵심 용어

<img width="471" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/66772700-03d5-4615-9c97-94093404fe32">

### **태그**
- 데이터를 어디로 전달할 지를 정의한다.
- 데이터를 추적해 활용하는 트레이싱 툴을 등록하면 된다.

<img width="360" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/a28cfeac-13f0-4d08-9348-55d5f17307e9">


### **트리거**

- 어떤 경우에 실행할 지를 정의한다. 트리거 조건을 충족했을 경우 데이터가 전송된다.
- 트리거 유형은 사용자의 창 로드, 클릭, 스크롤 등이 될 수 있다.

<img width="736" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/60423552-404e-4a3d-bd8f-a91397acd0ab">

### **변수**

- 어떤 데이터, 값을 전달할 지를 정의한다.
- 태그 실행시마다 변경되는 값을 관리하는 데 사용된다.

<img width="436" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/320189e8-a412-442d-bb29-3c8d34832f0a">

## 효과

1. 다양한 툴 삽입가능
  - GTM은 우선 한 번 웹사이트에 심어 놓으면 개발자의 도움 없이도 다양한 툴을 테스트해볼 수 있다.
2. 다양한 데이터를 간단하게 사용
   - GA에서 수집할 수 있는 데이터 외에 다른 데이터들이 궁금해질 때 GTM을 통해 간단히 수집할 수 있다.
3. 손쉽게 반복적인 TEST 가능
   - GTM에서는 버전 관리 기능을 통해 새로운 데이터를 수집하거나 설치한 툴을 여러 번 테스트해볼 수 있고, 결과가 마음에 들지 않으면 이전으로 되돌릴 수도 있다. 즉, 원하는 정보를 얻기 위해 다양한 실험을 반복해볼 수 있다.

## 데이터 레이어

- 웹사이트에서 GTM 컨테이너로 정보를 전달할 때 사용되는 자바스크립트 개체를 데이터 레이어라고 부른다.
- 홈페이지와 GTM 간의 데이터 송수신을 위한 매개체라고 할 수 있다.

```js
// 초기화
window.dataLayer = window.dataLayer || [];

// 데이터 추가
window.dataLayer.push({
	event: "이벤트명",
 	변수명1: "값1",
	변수명2: "값2",
	변수명3: "값3"
});
```

GTM에서는 데이터 레이어를 아래와 같은 절차로 처리한다.

1. GTM 컨테이너가 로드됨.
2. 데이터레이어 푸시 메시지 중 처음 수신한 메시지를 가장 먼저 처리함.
3. 수신한 메시지에 이벤트가 있을 경우 해당 이벤트를 트리거로 하는 모든 태그를 실행함.
4. 메시지 처리 및 태그 실행이 완료되면 다음 수신한 메시지를 한 번에 하나씩 처리함. (선입선출)

---
참고
- https://marketingplatform.google.com/intl/ko/about/tag-manager/
- https://support.google.com/tagmanager/answer/6164391?hl=ko
- https://developers.google.com/tag-platform/tag-manager/datalayer