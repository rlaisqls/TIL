
EME(Encrypted Media Extension)의 약자로, DRM이 걸려있는 영상 컨텐츠를 사용자가 단말기에서 보안 프로그램 설치 없이 사용할 수 있게 해주는 기술이다.

<img width="579" alt="image" src="https://github.com/user-attachments/assets/3b90fc13-c894-4ab9-878b-9ab16b34e8bc" />

EME를 적용하기 위해선 아래 네 가지가 필요하다.

1. 암호화된 영상이 저장되어있는 스토리지 서버

    - 콘텐츠를 암호화된 형태로 저장하고, 재생시 영상을 반환한다.
    - [Shaka Packager](https://github.com/shaka-project/shaka-packager)와 같은 도구를 사용해 암호화할 수 있다.

2. 복호화 키가 들어있는 라이센스 서버

    - 콘텐츠 재생에 필요한 암호화 키를 안전하게 발급한다.

3. 인증서

    - 영상을 복호화할 때, 복호화키와 인증서를 같이 가져와 인증해야한다.
    - 이 인증서는 개인적으로 발급받기 어렵다. 따라서 인증서를 생성하여 나눠주는 [Pallycon](https://pallycon.com/) 등의 서비스를 사용할 수 있다.

4. CDM(Contents Decryption Module)

    - 라이센스 서버에서 복호화 키, 인증서를 가져와 영상을 복호화한다.

    - 대표적인 CDM은 아래와 같은 것들이 있다.
        - Widevine(Google에서 개발. Chrome, Android, Firefox, Opera에서 지원)
        - Playready(Microsoft에서 개발. IE, Edge, Smart TV에서 지원)
        - Fairplay(Apple에서 개발. Safari, IOS에서 지원)

---
참고

- <https://github.com/LeeJaeBin/About-EME/tree/master>
- <https://d2.naver.com/helloworld/7122>
- <https://github.com/shaka-project>
- <https://www.w3.org/TR/encrypted-media-2/>
