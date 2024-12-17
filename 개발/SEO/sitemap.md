### `sitemap.xml`

- 사이트맵은 사이트의 페이지, 동영상, 기타 파일들의 관계에 대한 정보를 제공하는 파일이다.
- 검색엔진 크롤러는 자동으로 홈페이지에서 시작하는 링크를 따라가 페이지를 탐색하는데, 홈페이지에서 모든 페이지를 접근할 수 없거나 페이지 갯수가 많은 경우(약 500개 이상) `sitemap.xml` 파일을 설정해놓으면 크롤러가 사이트를 더 효율적으로 크롤링할 수 있다.
- 사이트에 리치 미디어 콘텐츠(동영상, 이미지)가 많거나 Google 뉴스에 표시되어야 하는 경우 sitemap 파일로 추가 정보를 제공하는 것이 좋다.

- 크롤러에서 인식할 수 있는 사이트맵 형식은 여러가지가 있다.

    | 사이트맵 형식 | 장점 | 단점 |
    |--------------|------|------|
    | XML 사이트맵 | - URL에 대한 가장 많은 정보 제공 가능<br>- 대부분의 CMS에서 자동 생성 또는 플러그인 제공 | - 작업이 번거로울 수 있음<br>- 대규모 사이트나 빈번히 URL이 변경되는 사이트에서 매핑 유지가 복잡할 수 있음 |
    | RSS, mRSS, Atom 1.0 | - 대부분의 RSS CMS가 자동으로 피드를 생성하도록 할 수 있음<br>- Google에 동영상 정보 제공 가능 | - HTML 및 색인 가능한 텍스트 콘텐츠 외 비디오만 정보 제공<br>- 작업이 번거로울 수 있음 |
    | 텍스트 사이트맵 | - 대규모 사이트에서 생성 및 유지 관리가 간단함 | - 지원 형태가 HTML 및 색인 가능한 텍스트 콘텐츠로만 제한됨 (동영상, 뉴스 등은 지원 X) |

- XML 사이트맵 예시

    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    <url>
        <loc>http://www.example.com/</loc>
        <lastmod>2005-01-01</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.8</priority>
    </url>
    </urlset>
    ```

### hreflang 태그

- 하나의 페이지에 (다른 언어로 된) 또 다른 버전의 페이지가 존재함을 알려주기 위한 태그이다.
- HTML head나, sitemap에 정의할 수 있다.
  - 그러나 페이지 코드 내 hreflang 태그는 HTML의 크기를 늘려 로드 속도에 영향을 줄 수 있기에 hreflang을 XML Sitemap에 적용하는 것이 더 나을 수 있다는 의견이 있다.

- HTML로 hreflang 태그를 정의하는 예시

    ```html
    <link rel=”alternate” hreflang=”es” href=”https://example.com/es” />
    ```

- sitemap에 정의하는 예시

    ```xml
    <url>
        <loc>https://example.com</loc>
        <xhtml:link rel="alternate" hreflang="en" 
        href="https://example.com" />
        <xhtml:link rel="alternate" hreflang="es" 
        href="https://example.com/es/" />
        <xhtml:link rel="alternate" hreflang="pt" 
        href="https://example.com/pt/" />
    </url>
    <url>
        <loc>https://example.com/es/</loc>
        <xhtml:link rel="alternate" hreflang="en" 
        href="https://example.com" />
        <xhtml:link rel="alternate" hreflang="es" 
        href="https://example.com/es/" />
        <xhtml:link rel="alternate" hreflang="pt" 
        href="https://example.com/pt/" />
    </url>
    ```

        -

### `robots.txt`

- 검색엔진이 웹 사이트에 접근할때 가장 먼저 조회하는 곳
- 검색엔진 크롤러에게 특정 페이지 정보 수집을 제한/허용할 수 있다. (User-agent별 설정도 가능)
- 이탈률(Bounce Rate)이 높은 페이지, 또는 검색되면 안되는 페이지를 제외시켜 SEO를 관리할 수 있다.

- `robots.txt` 예시

    ```txt
    User-agent: Googlebot
    Disallow: /nogooglebot/

    User-agent: *
    Allow: /

    Sitemap: https://www.example.com/sitemap.xml
    ```

---
참고

- <https://www.sitemaps.org>
- <https://support.google.com/webmasters/thread/117866290/hreflang-sitemap-vs-hreflang-tag-which-one-is-better?hl=en>
- <https://developers.google.com/search/docs/crawling-indexing/sitemaps/overview>
- <https://developers.google.com/search/docs/crawling-indexing/robots/create-robots-txt>
- <https://fourward.co.kr/blog/what-is-robots-txt-and-sitemap-xml>
