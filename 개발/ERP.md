
ERP(Enterprise Resource Planning)는 회사의 회계, 인사, 구매, 재고, 생산, 영업 등의 업무를 하나의 시스템으로 통합 관리하는 소프트웨어이다. 부서마다 따로 쓰던 시스템을 하나의 DB로 묶어서 데이터가 실시간으로 공유되게 한 것이다.

## MRP에서 ERP까지

ERP는 제조업의 자재 관리에서 출발했다.

- **MRP (1960년대)**: Material Requirements Planning. Orlicky 교수가 고안했다. "무엇이, 얼마나, 언제 필요한가"를 계산해서 자재 조달 계획을 세우는 시스템이다. BOM(자재 명세서)과 생산 일정을 기반으로 필요한 자재 수량과 시기를 산출한다.
- **MRP II (1980년대)**: Manufacturing Resource Planning. MRP가 자재만 다뤘다면, MRP II는 생산능력, 인력, 설비 같은 제조 자원 전체로 범위를 넓혔다. 판매, 재고, 구매, 생산 모듈이 재무/회계와 결합되기 시작한 시점이다.
- **ERP (1990년대)**: MRP II가 제조 이외의 영역(인사, 영업, 경영관리 등)까지 확장되면서 ERP라는 이름이 붙었다. Gartner가 1990년에 처음 사용한 용어이다.

최신 ERP에도 MRP의 원칙은 그대로 남아있다. 결국 핵심은 '필요한 자원을 필요한 시점에 확보한다'는 것이다.

## 주요 모듈

ERP는 보통 아래와 같은 모듈로 나뉜다.

- **재무/회계(FI)**: 전표, 재무제표, 결산, 세금
- **인사(HR)**: 급여, 근태, 채용
- **영업/유통(SD)**: 주문, 출하, 청구
- **구매/자재(MM)**: 발주, 입고, 재고, 공급업체
- **생산(PP)**: 생산 계획, 작업 지시, BOM
- **그룹웨어**: 전자결재, 사내 메일, 게시판

중소기업용 ERP는 그룹웨어와 메일 서버까지 ERP에 포함되어 있는 경우가 많다. 그래서 ERP를 교체하면 메일 서버, SMTP 설정, 네트워크 구성 같은 인프라가 같이 바뀔 수 있다.

## 아키텍처

ERP의 내부 구조는 크게 두 가지로 나뉜다.

- **모놀리식(Monolithic)**: 모든 모듈이 하나의 플랫폼에 통합되어 있다. 모듈 간 데이터 정합성은 좋지만 특정 모듈만 교체하거나 확장하기 어렵다. 전통적인 SAP ECC, 더존 iCUBE 등이 이 방식이다.
- **모듈식(Modular)**: 각 기능(재무, 물류, 인사 등)이 독립된 모듈로 분리되어 있다. 필요한 모듈만 골라서 도입할 수 있고, 모듈별로 업데이트가 가능하다. 클라우드 ERP들이 대부분 이 방식을 쓴다.

기술적으로는 보통 3-tier 구조를 따른다.

- **Presentation Layer**: 사용자가 접근하는 UI. 웹 브라우저나 전용 클라이언트
- **Application Layer**: 비즈니스 로직 처리. 주문이 들어오면 재고 차감하고 전표 생성하는 등의 처리가 여기서 일어난다
- **Data Layer**: DB. 모든 모듈이 하나의 DB를 공유하는 것이 ERP의 핵심이다

## 대표 예시

- **SAP ERP**: 글로벌 대기업에서 가장 많이 씀. 모듈이 방대하고 커스터마이징 가능하지만 도입 비용이 높다
- **Oracle ERP Cloud**: 클라우드 기반. 재무와 SCM에 강점
- **더존(Douzone)**: 국내 중소기업에서 가장 많이 쓴다. iCUBE, 위하고(WEHAGO) 등
- **영림원 K-System**: 국내 중견기업 시장에서 점유율이 높다
- **Microsoft Dynamics 365**: Office, Teams 등 MS 생태계와 연동이 강점

전통적으로 ERP는 회사 자체 서버에 설치(온프레미스)했지만, 최근에는 더존 위하고, SAP S/4HANA Cloud처럼 SaaS 형태의 클라우드 ERP도 많아지고 있다.

## 연동

외부 서비스에서 ERP와 연동해야 하는 경우 아래 내용을 주의해야할 수 있다.

- **메일**: ERP에 내장된 메일 서버를 쓰는 회사가 많아서, ERP 교체 시 SMTP 서버 주소나 포트, 인증 방식이 바뀔 수 있다. 외부에서 보낸 메일의 수신 응답 처리에 문제가 생기기도 한다
- **API**: 최신 ERP는 REST API를 제공하지만 레거시는 DB 직접 연결이나 파일 교환(CSV, EDI) 방식인 경우도 있다
- **SSO**: ERP 계정과 외부 서비스를 SSO로 연동했다면, ERP 변경이 인증 체계에 영향을 줄 수 있다

---
참고

- <https://www.sap.com/korea/products/erp/what-is-erp.html>
- <https://www.oracle.com/kr/erp/what-is-erp/>
- <https://www.sap.com/korea/products/erp/what-is-mrp.html>
- <https://ko.wikipedia.org/wiki/전사적_자원_관리>
- <https://www.microsoft.com/ko-kr/dynamics-365/resources/what-is-erp>
- <https://korea-erp.com/what-is-erp/>
