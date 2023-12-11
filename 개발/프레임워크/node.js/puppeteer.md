# puppeteer

Puppeteer는 Headless Chrome 혹은 Chromium 를 제어하도록 도와주는 라이브러리이다.

Puppeteer는 Node 6 이상 에서 동작하며, Chrome 혹은 Chromium의 DevTools 프로토콜을 통해 각 Chrome 혹은 Chromium의 API를 제어한다.

## Headless Browser

Headless Browser는 일반적으로 사용자가 사용하는 GUI 에서 동작하는 것이 아닌 CLI(Command Line interface) 에서 작동하는 브라우저이다. 백그라운드에서 동작하며, 일반적인 브라우저와 같이 웹페이지에 접속하여 HTML, CSS로 DOM Tree와 CSSOM Tree를 만들고, JS 엔진을 구동한다.

유일한 차이점은 만든 화면을 사용자에게 보여주지 않는다는 점이다.

일반 브라우저와 큰 차이가 없기 때문에 보여주는 화면이 없이도, 화면 테스트나 스크린샷을 찍는것 등 다양한 기능 동작이 가능하며, 사용자가 실제 사용하는 환경과 비슷하게 테스트가 가능하다.

puppeteer 에서는 Chrome 혹은 Chromium의 렌더링 엔진을 사용하여, Headless Browser 환경을 구성하였다. Chrome의 렌더링 엔진이 지원하는 최신 스펙의 HTML, CSS, JS 등 렌더링 엔진이 만들 수 있는 모든 화면을 만들어 낼 수 있다. 또한 여러 ifream 이나 popup 으로 이루어진, 복잡한 화면을 제어하는 것이 가능하며, 최근 ES6로 작성된 SPA 화면들도 렌더링 및 제어가 가능하다.

## 구조

Puppeteer API는 계층적이다.

- puppeteer는 하나의 Browser 를 갖는다.
- 하나의 Browser는 여러 BrowserContext 를 가질 수 있다.
- 하나의 BrowserContext 여러 Page 를 가질 수 있고, Serviceworker 와 Session 을 가질 수 있다.
- 하나의 Page는 여러 Frame 을가질 수 있다.
- 하나의 Frame은 여러 Context 를 가질 수 있다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/04151a62-c124-4d03-87e6-a5422a01b1ab)

## BrowserContext

puppeteer로 Browser가 시작되면 default BrowserContext가 생성된다. 이 default BrowserContext는 Browser의 생명주기와 같다.

Browser는 여러 개의 BrowserContext를 가질 수 있고 `Browser.createIncognitoBrowserContext()` 으로 시크릿 브라우저 컨텍스트를 만들 수 있다.

`window.open` 호출로 생성된 팝업은 이전 페이지의 BrowserContext에 속한다.

`Browser.newPage()`로 생성된 페이지는 default BrowserContext에 포함된다.

## 예시

아래는 example 페이지에 접속하여 스크린 샷을 찍는 예제이다.

```js
// https://developers.google.com/web/tools/puppeteer/get-started
(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto('https://example.com');
  await page.screenshot({path: 'example.png'});
  await browser.close();
})();
```

대부분의 메소드들은 `Promise` 를 반환한다.

`puppeteer.launch()` 메서드를 통해 browser를 생성할 수 있다. 이때, 옵션을 전달하여 브라우저를 제어할 수 있다.

- **headless:** 기본값은 true 이고, false로 설정하면, 브라우저가 실제로 실행된다.
- **defaultViewport:** 기본값은 800x600 이고, 화면이 노출될 사이즈를 지정할 수 있다.
- **devtools:** 기본값은 false 이고, true 로 설정하면, 브라우저에 Devtools 가 열린다.

이 외에도 많은 옵션이 제공된다.

생성된 browser로 `browser.newPage()` 메서드를 통해 page 를 생성할 수 있고 생성된 page로 실제 페이지를 조작 및 제어 할 수 있다.

`page.goto` 메서드로 페이지를 이동할 수 있다.

## pdf 

링크에서 페이지를 읽어와 pdf buffer를 반환하는 예제이다.
```js
const puppeteer = require('puppeteer');

(async () => {

  // Create a browser instance
  const browser = await puppeteer.launch();

  // Create a new page
  const page = await browser.newPage();

  // Website URL to export as pdf
  const website_url = 'https://host'; 

  // Open URL in current page
  await page.goto(website_url, { waitUntil: 'networkidle0' }); 

  //To reflect CSS used for screens instead of print
  await page.emulateMediaType('screen');

// Downlaod the PDF
  const pdf = await page.pdf({
    path: 'result.pdf',
    margin: { top: '100px', right: '50px', bottom: '100px', left: '50px' },
    printBackground: true,
    format: 'A4',
  });

  // Close the browser instance
  await browser.close();
})();
```

html로 페이지를 만들어 pdf를 출력하는 예제이다.
```js
const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {

  // Create a browser instance
  const browser = await puppeteer.launch();

  // Create a new page
  const page = await browser.newPage();

  //Get HTML content from HTML file
  const html = fs.readFileSync('sample.html', 'utf-8');
  await page.setContent(html, { waitUntil: 'domcontentloaded' });

  // To reflect CSS used for screens instead of print
  await page.emulateMediaType('screen');

  // Downlaod the PDF
  const pdf = await page.pdf({
    path: 'result.pdf',
    margin: { top: '100px', right: '50px', bottom: '100px', left: '50px' },
    printBackground: true,
    format: 'A4',
  });

  // Close the browser instance
  await browser.close();
})();
```