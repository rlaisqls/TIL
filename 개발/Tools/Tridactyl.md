<https://github.com/tridactyl/tridactyl>

- 설정파일 위치: `~/.config/tridactyl/tridactylrc`

### vimR 연동

vimR을 연동하면 브라우저 입력창에서 vim 입력기를 열어 편집할 수 있다.

[editor](https://tridactyl.xyz/build/static/docs/modules/_src_excmds_.html#editor) 옵션으로 vimR이 아닌 다른 도구를 설정할 수도 있다.

```
brew install --cask vimr
```

설정파일에 아래 내용을 추가한다.

```
set editorcmd /opt/homebrew/bin/vimr --wait
```

---
참고

- <https://tridactyl.xyz/build/static/docs/modules/_src_excmds_.html>
