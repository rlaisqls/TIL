웹 바이탈(Web Vitals)은 웹페이지 유저들의 사용 경험을 측정하는 구글의 표준화된 웹 성능 측정 기준이다. 사이트의 전반적인 로딩 속도, 상호작용, 웹페이지의 시각적 안정성, 보안 문제 등 여러 요소를 포함하고 있으며, 웹 사이트가 검색 엔진 결과에 표시되는 위치에 영향을 미친다.

검색 엔진에서 최적화하고 전체적으로 유저에게 좋은 환경을 제공하려면 코어 웹 바이탈을 개선해야한다.

<img style="width: 443px;" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/0757d8ec-5622-4922-af07-41ee8f56da14"/>

성능 지표 중 주요항목으로는 6가지가 있다.

- **FCP** (First Contentful Paint) : 첫번째 텍스트 또는 이미지가 표시되는 시간
- **TTI** (Time to Interactive) : 사용자 인터렉션이 가능해질 때까지 걸리는 시간
- **SI** (Speed Index) : 페이지 속도. 얼마나 빨리 표시되는지
- **TBT** (Total Blocking Time) : FCP ~ Time to interactive 사이에서 메인 스레드를 블로킹하는 작업 시간
- **LCP** (Largest Contentful Paint) : 가장 큰 텍스트 또는 이미지가 표시되는 시간
- **CLS** (Comulative Layout Shift) : 누적 레이아웃 이동. 뷰포트 안에 보이는 요소의 이동을 측정. 사용자가 예상치 못한 레이아웃 이동을 경험하는 빈도를 수량화해서 보여준다.

## Core Web Vitals

그리고 별도로 중요한 3가지 지표는 Core Web Vitals로 소개하고 있다. 각 핵심 지표에 대해 상세하게 알아보자.

<img style="width: 518px;"  alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/3fb94ab4-c3aa-4af0-806c-1d6772e4782d"/>

## LCP (Largest Contentful Paint)

<img style="width: 418px;" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/991a0a8b-146c-4ddd-9cfc-09c38083a81d">

LCP는 첫 페이지에서 내에서 가장 큰 요소(큰 텍스트 블록, 이미지 또는 비디오)를 표시하는 데 걸리는 시간을 측정한다. 표시 영역 내에서 사용자에게 보이는 요소일수록 중요하게 고려된다.

측정되는 요소는 아래와 같은 것들이 있다.

- `<img>` 요소
- `<svg>` 요소 내의 `<image>` 요소
- `<video>` 요소 (포스터 이미지 로드 시간 또는 동영상의 첫 프레임 프레젠테이션 시간 사용 중 더 빠른 시간 적용)
- `url()` 함수를 사용하여 로드된 배경 이미지가 있는 요소(CSS 그라데이션과 반대)
- 텍스트 노드 또는 다른 인라인 수준 텍스트 요소 하위 요소를 포함하는 블록 수준 요소.

중요한 정보가 없는 요소(불투명도가 0이거나 전체 영역을 덮는 배경)는 LCP 계산에서 제외된다.

구글에 따르면 웹페이지 로드 후 처음 2.5초 이내에 LCP가 발생하는 것이 이상적으로 판단된다. 2.5초~4초 미만은 개선이 필요하며, 그 이상의 시간이 소요되는 것은 성능이 좋지 않다고 간주할 수 있다.

## FID (First Input Delay)

<img style="width: 418px;" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/9189919e-c4b9-4581-8112-29668353afaa">

FID는 사용자가 웹페이지와 상호작용을 시도하는 첫 번째 순간부터 웹페이지가 응답하는 시간을 측정한다. 즉, 브라우저에서 다음 액션이 발생되는 시간까지의 길이를 측정한 지표이며, 밀리세컨드(ms)로 측정한다. 

잘못된 FID의 주요 원인은 과중한 JavaScript 실행이다. JavaScript가 웹페이지에서 파싱, 컴파일, 실행되는 방식을 최적화하면 FID가 줄어든다.

좋은 사용자 경험을 제공하기 위해 사이트는 첫 번째 입력 지연이 100ms 이하가 되도록 해야한다. 100ms에서 300ms 사이는 개선이 필요하며, 그 이상은 성능이 좋지 않은 것이다.

## CLS (Cumulative Layout Shift)

<img style="width: 418px;" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/f1fcb2f2-afc8-45f4-a79b-e8b4744c25c7">

CLS는 페이지 요소가 화면에서 얼마나 자주 이동하는지 측정한다. 뷰포트에서 이동한 콘텐츠의 양과 영향을 받은 요소가 이동한 거리로 점수를 계산한다.

레이아웃 이동이 발생하는 원인은 아래와 같은 것들이 있다.

- 크기가 지정되지 않은 이미지, 광고, 삽입 및 iframe
- 동적으로 삽입된 콘텐츠
- FOIT / FOUT을 유발하는 웹 글꼴
- DOM을 업데이트하기 전에 네트워크 응답을 기다리는 작업

> CLS를 개선하는 자세한 방법은 아래 링크에서 자세히 알 수 있다.<br/>
> https://web.dev/articles/optimize-cls?hl=ko#images-without-dimensions

## 측정 방법

Core Web Vitals 측정을 위해 아래와 같은 툴을 사용할 수 있다.

- [Chrome UX 보고서(CrUX)](https://developer.chrome.com/docs/crux/):
  - Chrome 사용자가 보고한 필드 데이터로 실제 사용자가 웹 사이트를 어떻게 경험하는지에 대한 데이터를 제공한다.

- [Google Lighthouse](https://developer.chrome.com/docs/lighthouse/overview/):
  - 코어 웹 바이탈에 대한 실험실 지표를 제공하는 무료 도구이다. 성능, SEO, 접근성 등을 개선하기 위한 실행 가능한 통찰력을 제공한다. 
  - 다른 설정 없이 Chrome 개발자 도구에서 쉽게 확인할 수 있다.

- [Google PageSpeed ​​Insights](https://pagespeed.web.dev/):
  - CrUX와 Lighthouse에 각각 있는 CWV 및 기타 웹 바이탈에 대한 현장 및 실험실 데이터를 함께 제공한다. 사용자는 PageSpeed ​​Insights를 사용하여 웹 사이트 소유 여부에 관계없이 웹 사이트의 성능을 확인할 수 있다.

---
참고
- https://growfusely.com/blog/core-web-vitals-lcp-fid-cls/
- https://seo.tbwakorea.com/blog/core-web-vitals/
- https://web.dev/articles/vitals?hl=ko