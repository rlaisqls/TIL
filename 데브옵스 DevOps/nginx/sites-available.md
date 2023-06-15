# site-availables

```bash
ubuntu@:~/ cd /etc/nginx
```

`/etc/nginx`의 경로에서 nginx에 대한 기본적인 설정을 진행할 수 있다.

그 중 프록시 관련 설정을 할 때

```bash
/etc/nginx/sites-enabled
```

라는 폴더에서 직접적으로 설정이 가능하고

유저는 저 폴더에 있는 설정파일을 직접적으로 수정하지 않고

```bash
/etc/nginx/sites-available
```

의 폴더에서 여러 설정파일들을 생성한 뒤

symlink 기능을 이용해서 그 파일들 중 원하는 설정을 선택적으로 `sites-enabled`폴더에 동기화해서 적용할 수 있다.

다음은 sites-available에 만든 설정파일을 sites-enabled에 symlink 시킬 수 있는 명령어이다.

먼저 sites-available에 'proxy-setting1'이라는 설정파일을 하나 만들었다고 해보자.

```bash
ubuntu@:~/ cd /etc/nginx/sites-available
ubuntu@:~/etc/nginx/sites-available$ ls
	proxy-setting1
```

이렇게 만들어 졌으면 다음 symlink 명령어를 입력한다.

```bash
ubuntu@:~/etc/nginx/sites-available$ sudo ln -s /etc/nginx/sites-available/proxy-setting1
/etc/nginx/sites-enabled/
```

symlink가 잘 되었는지 확인하기 위해 sites-enabled폴더로 들어가보자

```bash
ubuntu@:~/etc/nginx/sites-available$ cd /etc/nginx/sites-enabled
ubuntu@:~/etc/nginx/sites-enabled$ ls
	proxy-setting1
```

symlink가 잘 된 것을 확인할 수 있다.

마지막으로 세팅변화가 nginx에 적용될 수 있게 재실행시켜준다.

```bash
ubuntu@:~/etc/nginx/sites-enabled$ sudo service nginx restart
```