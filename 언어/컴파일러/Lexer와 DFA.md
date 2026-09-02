렉서(어휘분석기, 스캐너)는 원시 프로그램을 문자 단위로 읽어 토큰이라는 문법 단위로 자르는 단계이다. 토큰의 형태는 정규표현으로 기술되고 정규표현이 나타내는 언어는 유한 오토마타가 인식하므로, 렉서의 실체는 DFA 하나를 돌리는 일이다. 구현이 갈리는 지점은 그 DFA를 사람이 짜느냐 생성하느냐다.

일반적인 프로그래밍 언어가 쓰는 토큰은 크게 다섯 종류가 있다. 식별자(`sum`, `a`, `b`), 상수(`1`, `3.14`, `"abc"`), 예약어(`if`, `while`, `return`), 연산자(`+`, `-`, `*`, `==`), 구분자(`(`, `[`, `;`, `,`)다.

전부 정규표현으로 적을 수 있다. 중첩 괄호처럼 세는 능력이 필요한 것은 여기 없다. 그래서 렉서는 스택 없이 상태만으로 돌아가고, 그것이 유한 오토마타다.

## 손으로 짜는 쪽

한 글자를 읽고 switch로 분기하는 구조다.

```go
func (l *Lexer) NextToken() Token {
    l.skipWhitespace()

    switch l.ch {
    case '=':
        if l.peekChar() == '=' {      // 두 글자 토큰 때문에 한 글자 미리보기
            l.readChar()
            return Token{Type: EQ, Literal: "=="}
        }
        return newToken(ASSIGN, l.ch)
    case '+':
        return newToken(PLUS, l.ch)
    // ...
    default:
        if isLetter(l.ch) {
            lit := l.readIdentifier()   // isLetter인 동안 계속 읽는다
            return Token{Type: lookupIdent(lit), Literal: lit}
        }
        if isDigit(l.ch) {
            return Token{Type: INT, Literal: l.readNumber()}
        }
        return newToken(ILLEGAL, l.ch)
    }
}
```

여기에는 상태 변수가 없다. `readIdentifier()`를 실행 중이라는 사실 자체가 "식별자를 읽는 중"이라는 상태이고, 제어 흐름의 현재 위치가 곧 DFA의 현재 상태다. 사람이 머릿속에서 DFA를 돌려 코드로 편 것이라, 상태 전이표가 코드의 분기 구조에 녹아 있다.

이 방식에는 표에는 없는 성질이 하나 있다. 검사 순서가 성능을 좌우한다는 것이다. 상태전이도를 그대로 옮겨 식별자와 상수를 항상 먼저 검사하도록 짜면, 연산자가 많은 프로그램에서는 매번 헛검사를 하게 된다. 어느 토큰이 자주 나오는지를 고려해 분기 순서를 정해야 한다. 표 구동 방식에서는 이런 고민이 없다. 어느 상태에서든 조회 한 번이다.

## 생성하는 쪽

생성기는 정규표현에서 출발해 기계적으로 DFA를 만든다.

```
정규표현  →  NFA  →  DFA  →  최소화된 DFA
         Thompson   부분집합 구성   상태 병합
```

교재의 표현을 그대로 옮기면 "문법을 보고 NFA를 구성하고, NFA를 DFA로 변환한 다음 DFA를 최소화시키면 어휘분석기가 된다"이다. 각 규칙의 정규표현을 NFA로 만들고 전부 하나로 합친 뒤, 부분집합 구성으로 결정적으로 바꾸고, 구별할 수 없는 상태를 합치면 끝난다. 각 단계의 원리는 [NFA와 DFA](./NFA와%20DFA.md)에 정리했다.

LEX는 1975년 벨연구소에서 나왔고 지금은 그 재구현인 flex가 표준이다. 입력은 `%%`로 나뉜 세 부분이다.

```lex
%option noyywrap
DIGIT   [0-9]
LETTER  [a-zA-Z_]
%%
[ \t\r\n]+                   { /* skip */ }
"=="                         { return EQ; }
"!="                         { return NOT_EQ; }
"="                          { return ASSIGN; }
[-+*/<>;:,(){}\[\]]          { return yytext[0]; }
{DIGIT}+                     { return INT; }
{LETTER}({LETTER}|{DIGIT})*  { return IDENT; }
\"[^"\n]*\"                  { return STRING; }
.                            { return ILLEGAL; }
%%
```

위쪽은 이름 정의, 가운데는 `정규표현 { 실행코드 }` 쌍, 아래는 사용자 코드다. 매칭된 문자열은 `yytext`, 길이는 `yyleng`, 줄 번호는 `yylineno`로 액션에 전달된다.

이 14줄을 flex 2.6.4로 돌리면 **C 코드 1,790줄**이 나온다. 알맹이는 배열 일곱 개다.

```c
static const flex_int16_t yy_accept[21];   // 상태 → 몇 번 규칙으로 accept인가
static const YY_CHAR     yy_ec[256];       // 문자 → 등가 클래스
static const YY_CHAR     yy_meta[10];
static const flex_int16_t yy_base[23];     // 상태 → 전이표 시작 위치
static const flex_int16_t yy_def[23];      // 실패 시 위임할 상태
static const flex_int16_t yy_nxt[33];      // 다음 상태
static const flex_int16_t yy_chk[33];      // 이 칸이 정말 그 상태 것인지 검증
```

규칙 아홉 개가 상태 20개짜리 DFA로 접혔다. `yylex()`는 이 표를 따라가는 루프일 뿐이고, 문법이 바뀌면 코드가 아니라 표가 바뀐다. LR 파서에서 구동기는 같고 파싱표만 다르던 것과 같은 구조다. 대신 산출물 자체는 읽을 것이 못 된다. 스캐너가 이상하게 동작할 때 볼 것은 생성된 C가 아니라 `.l` 파일과 `flex -b` 리포트다.

정규표현만으로 표현할 수 없는 것들도 있다. 들여쓰기로 블록을 나누거나, 문자열 안의 중첩 보간을 다루거나, 파일을 읽기 전에 인코딩을 먼저 알아야 하는 경우가 실제 언어에는 흔하다. flex는 `%x` 시작 조건으로 모드를 나눠 대응하지만, 이쯤 되면 사람이 짠 스캐너와 복잡도가 비슷해진다. 자세한 것은 [Context-sensitive Lexing](./Context-sensitive%20Lexing.md)에 정리했다.

## 최장 일치와 백트래킹

두 방식의 진짜 차이는 여기서 나온다. 생성된 스캐너는 **최장 일치**(maximal munch)로 동작한다. 가능한 한 길게 먹고, 길이가 같은 후보가 여럿이면 먼저 쓴 규칙이 이긴다. 그래서 위 예제에서 `"=="`를 `"="`보다 위에 둘 필요가 사실 없다. 길이가 다르므로 최장 일치가 알아서 고른다. 순서가 중요한 것은 `if`와 `{IDENT}`처럼 길이가 같아질 때뿐이다.

길게 먹으려면 실패했을 때 되돌아갈 수 있어야 한다. 정수와 실수와 범위 연산자가 함께 있는 문법을 보자.

```lex
[0-9]+          { return INT; }
[0-9]+"."[0-9]+ { return FLOAT; }
".."            { return RANGE; }
```

`1..5`를 만나면 스캐너는 `1`을 먹고 `.`을 먹은 뒤 실수 규칙의 중간 상태에 도달한다. 그런데 다음 글자가 `5`가 아니라 `.`이라 실수가 될 수 없다. `flex -b`로 백업 리포트를 뽑으면 이 상태가 그대로 보고된다.

```
State #9 is non-accepting -
 associated rule line numbers:
 4
 out-transitions: [ 0-9 ]
 jam-transitions: EOF [ \000-/  :-\377 ]

Compressed tables always back up.
```

9번 상태는 accept 상태가 아니고, 여기서 나갈 수 있는 길은 숫자뿐이다. 숫자가 아니면 마지막 accept 지점으로 되감아야 한다. 그 되감기를 위해 생성된 코드가 `yy_last_accepting_state`와 `yy_last_accepting_cpos`를 들고 다닌다.

손으로 짠 렉서에는 이 되감기가 없다. `readNumber()`는 숫자인 동안 앞으로만 가고 `position`을 되돌리는 코드가 어디에도 없다. 우연히도 문법이 접두사-단순하면 이걸로 충분하다. `=`/`==`, `!`/`!=`처럼 한 글자만 미리 보면 갈라지는 경우다. 하지만 위 실수 리터럴을 추가하는 순간 이 구조는 깨지고, 위치를 저장하고 복원하는 코드를 직접 넣어야 한다. flex의 `r/s` 트레일링 컨텍스트나 `REJECT`, `yymore()`, `yyless()`에 해당하는 것도 물론 없다.

리포트의 마지막 줄이 말하는 압축은 표 크기 문제에서 온다. 상태 전이표를 그대로 만들면 크기가 `상태 수 × 256`이다. 상태가 500개면 12만 8천 칸이다. flex가 이걸 줄이는 첫 번째 수단이 **등가 클래스**다. 위 예제에서 `yy_ec[256]`에 실제로 들어 있는 값은 0부터 9까지 열 개뿐이다. 256개 바이트 값이 열 개 클래스로 접혔다는 뜻이다. `a`와 `b`와 `z`는 이 문법 안에서 완전히 똑같이 취급되므로 같은 클래스가 되고, 전이표의 가로 폭이 256에서 10으로 줄어든다.

그 위에 `yy_base`/`yy_def`/`yy_nxt`/`yy_chk` 네 개짜리 중첩 구조가 얹힌다. 상태마다 전이가 비슷하다는 성질을 이용해 행들을 겹쳐 저장하고, `yy_chk`로 "이 칸이 정말 내 것인지"를 검증한다. 결과적으로 위 예제의 표 전체가 399개 엔트리로 끝난다.

압축을 끄면(`flex -Cf`) `yy_nxt[][128]`처럼 상태마다 온전한 행을 갖는 2차원 배열이 나온다. 표는 커지지만 조회가 배열 접근 한 번이라 빠르고, 백트래킹 정보를 표에 넣을 수 있어 되감기도 줄어든다. 리포트의 "Compressed tables always back up"이 그 뜻이다. 속도와 크기를 맞바꾸는 선택지다.

## 키워드는 DFA에 넣지 않는다

입문서는 보통 `"if" { return IF; }`를 `{IDENT}` 규칙 위에 나열하라고 한다. 길이가 같을 때 먼저 쓴 규칙이 이기므로 동작은 한다. 하지만 키워드가 늘어나는 만큼 DFA 상태가 불어난다.

식별자를 DFA로 전부 인식하려는 시도가 왜 무리인지는 가짓수를 세어 보면 바로 나온다. 첫 글자가 영문자, 이후 영문자나 숫자, 최대 6자라고 하면 `26×36⁵ + 26×36⁴ + … + 26`개다. 이걸 전부 상태로 만들 수는 없다.

그래서 실무 스캐너는 flex를 쓰더라도 `{IDENT}` 규칙 하나만 두고 액션 안에서 해시 조회를 한다.

```lex
{LETTER}({LETTER}|{DIGIT})*  { return lookupIdent(yytext); }
```

손으로 짠 렉서가 `readIdentifier()` 후에 `lookupIdent()`를 부르는 것과 정확히 같은 구조다. 어느 쪽이든 키워드는 오토마타의 일이 아니라 표 조회의 일로 넘긴다.

## 비교

| | 손으로 짠 렉서 | 생성된 렉서 |
|---|---|---|
| 명세 | 코드의 분기 구조 | `.l` 파일의 정규표현 규칙 |
| 상태 | 제어 흐름의 위치 | `yy_accept` 등 배열 |
| 매칭 | 각 분기가 알아서 소비 | 최장 일치, 동률이면 먼저 쓴 규칙 |
| 룩어헤드 | 손으로 넣은 만큼 | 무제한, 실패 시 되감기 |
| 검사 순서 | 성능에 영향 | 무관 |
| 키워드 | 해시 조회 | (실무에선) 해시 조회 |
| 의존성 | 없음 | 빌드에 생성 단계 |

GCC와 Clang, CPython은 모두 스캐너를 손으로 짜고, 설정 언어나 도메인 특화 언어에서는 flex가 여전히 표준이다. 둘 다 기본적으로 바이트 단위로 동작하므로, 유니코드 식별자를 받으려면 어느 쪽이든 별도 설계가 필요하다.

---
참고

- [NFA와 DFA](./NFA와%20DFA.md)
- [Context-sensitive Lexing](./Context-sensitive%20Lexing.md)
- [Pratt 파싱](./Pratt%20파싱.md)
- [LR 파싱](./LR%20파싱.md)
- [c언어 컴파일과정](../../OS/c언어%20컴파일과정.md)
- <https://github.com/westes/flex>
- <https://westes.github.io/flex/manual/>
- <https://swtch.com/~rsc/regexp/regexp1.html>
