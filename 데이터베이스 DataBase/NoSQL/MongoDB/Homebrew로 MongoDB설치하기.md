# 🌿 Homebrew로 MongoDB 설치하기

1. 커스텀 홈브루 탭 셋업하기

```
brew install mongodb-community
```

2. mongoDB 설치하기

```
brew install mongodb-community
```

위 명령어로 설치하면 아래의 경로에 mongodb data file들이 생성됩니다.

```
/usr/local/ect/mongod.conf  //config
/usr/local/var/log/mongodb  //log
/usr/local/ver/mongodb      //file
```

3. 실행하기

```
brew services start mongodb-community 
```

중지하기

```
brew services stop mongodb-community 
```