# Keytoole

Keystore 정보를 확인하기 위해선 터미널 또는 CMD에서 아래 명령어를 실행하면 된다.

```bash
keytool -v -list -keystore [Keystore 파일]
```

명령어 입력 후 비밀번호를 입력하면, 키스토어의 정보가 나오게 된다.

## Keytool 명령어

```bash
-certreq     [-v] [-protected]
             [-alias <별명>] [-sigalg <서명 알고리즘>]
             [-file <csr 파일>] [-keypass <키 암호>]
             [-keystore <keystore>] [-storepass <암호 입력>]
             [-storetype <입력 유형>] [-providerName <이름>]
             [-providerClass <공급자 클래스 이름> [-providerArg <인자>]] ...
-delete      [-v] [-protected] -alias <별명>
             [-keystore <keystore>] [-storepass <암호 입력>]
             [-storetype <입력 유형>] [-providerName <이름>]
             [-providerClass <공급자 클래스 이름> [-providerArg <인자>]] ...
-export      [-v] [-rfc] [-protected]
             [-alias <별명>] [-file <인증서 파일>]
             [-keystore <keystore>] [-storepass <암호 입력>]
             [-storetype <입력 유형>] [-providerName <이름>]
             [-providerClass <공급자 클래스 이름> [-providerArg <인자>]] ...
-genkey      [-v] [-protected]
             [-alias <별명>]
             [-keyalg <키 알고리즘>] [-keysize <키 크기>]
             [-sigalg <서명 알고리즘>] [-dname <대상 이름>]
             [-validity <유효일>] [-keypass <키 암호>]
             [-keystore <keystore>] [-storepass <암호 입력>]
             [-storetype <입력 유형>] [-providerName <이름>]
             [-providerClass <공급자 클래스 이름> [-providerArg <인자>]] ...
-help
-identitydb  [-v] [-protected]
             [-file <신원 데이터베이스 파일>]
             [-keystore <keystore>] [-storepass <암호 입력>]
             [-storetype <입력 유형>] [-providerName <이름>]
             [-providerClass <공급자 클래스 이름> [-providerArg <인자>]] ...
-import      [-v] [-noprompt] [-trustcacerts] [-protected]
             [-alias <별명>]
             [-file <인증서 파일>] [-keypass <키 암호>]
             [-keystore <keystore>] [-storepass <암호 입력>]
             [-storetype <입력 유형>] [-providerName <이름>]
             [-providerClass <공급자 클래스 이름> [-providerArg <인자>]] ...
-keyclone    [-v] [-protected]
             [-alias <별명>] -dest <대상 별명>
             [-keypass <키 암호>] [-new <새 키 암호>]
             [-keystore <keystore>] [-storepass <암호 입력>]
             [-storetype <입력 유형>] [-providerName <이름>]
             [-providerClass <공급자 클래스 이름> [-providerArg <인자>]] ...
-keypasswd   [-v] [-alias <별명>]
             [-keypass <기존 키 암호>] [-new <새 키 암호>]
             [-keystore <keystore>] [-storepass <암호 입력>]
             [-storetype <입력 유형>] [-providerName <이름>]
             [-providerClass <공급자 클래스 이름> [-providerArg <인자>]] ...
-list        [-v | -rfc] [-protected]
             [-alias <별명>]
             [-keystore <keystore>] [-storepass <암호 입력>]
             [-storetype <입력 유형>] [-providerName <이름>]
             [-providerClass <공급자 클래스 이름> [-providerArg <인자>]] ...
-printcert   [-v] [-file <인증서 파일>]
-selfcert    [-v] [-protected]
             [-alias <별명>]
             [-dname <대상 이름>] [-validity <유효일>]
             [-keypass <키 암호>] [-sigalg <서명 알고리즘>]
             [-keystore <keystore>] [-storepass <암호 입력>]
             [-storetype <입력 유형>] [-providerName <이름>]
             [-providerClass <공급자 클래스 이름> [-providerArg <인자>]] ...
-storepasswd [-v] [-new <새 암호 입력>]
             [-keystore <keystore>] [-storepass <암호 입력>]
             [-storetype <입력 유형>] [-providerName <이름>]
             [-providerClass <공급자 클래스 이름> [-providerArg <인자>]]
```

