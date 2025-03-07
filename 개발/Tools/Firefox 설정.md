## 상단 탭 목록 없애기

1. 아래 명령어 실행

```
ls ~/Library/Application\ Support/Firefox/Profiles/
```

2. `.default-release`로 끝나는 경로 들어가서

    ```
    mkdir chrome && vi chrome/userChrome.css 
    ```

3. `userChrome.css` 파일에 아래 내용 삽입

    ```css
    @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");

    #tabbrowser-tabs {
        visibility: collapse !important;
    }

    #nav-bar {
        border-top: 0px !important;
        margin-left: 200px;
        margin-top: -37px;
    } 
    ```

4. firefox에서 url에 about:config 입력하고 들어가서

    toolkit.legacyUserProfileCustomizations.stylesheets 옵션 true로 변경

5. firefox 재시작

참고

- <https://superuser.com/questions/1424478/can-i-hide-native-tabs-at-the-top-of-firefox>
- <https://www.reddit.com/r/kde/comments/10ckq05/comment/j4g8s3k/>

## Custum Search Url 설정

1. about:config에서 browser.urlbar.update2.engineAliasRefresh를 True로 변경

2. about:preferences#search > Search Shortcuts에서 원하는 항목 추가
