## map, noremap

> <https://stackoverflow.com/questions/3776117/what-is-the-difference-between-the-remap-noremap-nnoremap-and-vnoremap-mapping>

map, noremap 둘다 특정키를 매핑하는 역할을 한다.
둘의 차이는 recursive vs non-recursive 이다. 에를 들어

```
:map j gg
:map Q j
```

를 하면 j를 누르면 gg를 누른 것과 동일한 효과를 얻게 된다.
만약 대문자 Q를 누른다면 j로 매핑한다음 다시 j가 gg를 가리키므로 결과적으로 Q는 gg를 수행하게 된다.
그래서 map을 ‘recursive’하다라고 얘기한다. 매핑되는 키의 또다른 매핑되는 키를 찾아가게 된다.

하지만 noremap은 non-recursive map이다.

```
:map j gg
:noremap Q j
```

Q를 누르면 j를 누르는 효과이다.

map command에 대한 mode별 버전들이 있다.

    nmap - works recursively in normal mode.
    imap - works recursively in insert mode.
    vmap - works recursively in visual and select modes.
    xmap - works recursively in visual mode.
    smap - works recursively in select mode.
    cmap - works recursively in command-line mode.
    omap - works recursively in operator pending mode.

non-recursive 버전도 동일하다.

    nnoremap - works non-recursively in normal mode.
    inoremap - works non-recursively in insert mode.
    vnoremap - works non-recursively in visual and select modes.
    xnoremap - works non-recursively in visual mode.
    snoremap - works non-recursively in select mode.
    cnoremap - works non-recursively in command-line mode.
    onoremap - works non-recursively in operator pending mode.
