문맥 의존 렉싱은 토큰의 경계나 종류가 앞뒤 문맥에 따라 달라지는 경우를 처리하는 것이다. 렉서는 정규표현으로 기술되고 [유한 오토마타](./NFA와%20DFA.md)로 구현된다는 것이 원칙이지만, 실제 언어에는 그 전제가 깨지는 곳이 많다.

CPython의 토크나이저 상태 구조체가 얼마나 커졌는지를 보면 그 규모가 드러난다.

```c
struct tok_state {
    char *buf, *cur, *inp;
    const char *end, *start;
    int done, tabsize, indent;
    int indstack[MAXINDENT];        // 들여쓰기 스택
    int atbol, pendin;              // 줄 시작 여부, 밀린 INDENT/DEDENT
    int lineno, first_lineno, col_offset;
    int level;                      // 괄호 중첩 깊이
    char parenstack[MAXLEVEL];
    char *encoding;                 // PEP 263
    tokenizer_mode tok_mode_stack[MAXFSTRINGLEVEL];  // f-string 모드 스택
    int tok_mode_stack_index;
    enum interactive_underflow_t interactive_underflow;
    /* ... */
};
```

필드가 40개가 넘는다. 손으로 짠 최소 렉서가 입력 버퍼와 위치 두 개, 현재 문자 하나로 끝나는 것과 비교하면 차이가 크다. 이 필드들이 각각 어떤 문법적 요구에서 나왔는지 보면, 정규표현만으로는 안 되는 지점이 어디인지 알 수 있다.

아래 내용은 CPython `main`(3.16.0a0, 커밋 `f81c03a673a`)의 `Parser/lexer/`와 `Parser/tokenizer/` 기준이다.

## 오프사이드 규칙

파이썬은 중괄호 대신 들여쓰기로 블록을 나눈다. 그런데 파서는 블록의 시작과 끝을 알아야 한다. 해결책은 토크나이저가 원본에 없는 토큰을 합성해서 내보내는 것이다.

```python
def f():
    if x:
        return [1,
                2]
```

이걸 `tokenize`로 돌리면 이렇게 나온다.

```
NAME 'def'   NAME 'f'   OP '('   OP ')'   OP ':'   NEWLINE
INDENT '    '
NAME 'if'    NAME 'x'   OP ':'   NEWLINE
INDENT '        '
NAME 'return'  OP '['  NUMBER '1'  OP ','
NL '\n'                      ← 개행인데 NEWLINE이 아니다
NUMBER '2'   OP ']'   NEWLINE
DEDENT ''    DEDENT ''       ← 문자열이 비어 있다
ENDMARKER
```

`DEDENT`의 문자열이 비어 있는 것에 주목할 만하다. 원본 어디에도 대응하는 문자가 없기 때문이다. 파서 입장에서는 `INDENT`/`DEDENT`가 `{`와 `}`처럼 보이고, 그래서 파서 문법은 중괄호 언어와 똑같이 쓸 수 있다. 원칙대로면 블록 구조를 알아내는 것은 파서의 일이지만, 파서에 넘기려면 토큰 스트림에 문맥이 실려야 하고 그러면 파서 문법이 지저분해진다. 복잡도를 없애는 게 아니라 어디에 둘지 고르는 문제다.

구현은 들여쓰기 스택과 대기 카운터다.

```c
else /* col < tok->indstack[tok->indent] */ {
    /* Dedent -- any number, must be consistent */
    while (tok->indent > 0 && col < tok->indstack[tok->indent]) {
        tok->pendin--;
        tok->indent--;
    }
    if (col != tok->indstack[tok->indent]) {
        tok->done = E_DEDENT;
        return MAKE_TOKEN(ERRORTOKEN);
    }
}

/* Return pending indents/dedents */
if (tok->pendin != 0) {
    if (tok->pendin < 0) { tok->pendin++; return MAKE_TOKEN(DEDENT); }
    else                 { tok->pendin--; return MAKE_TOKEN(INDENT); }
}
```

한 줄에서 여러 단계를 한꺼번에 빠져나올 수 있으므로 `pendin`에 음수로 쌓아두고 한 번에 하나씩 내보낸다. 위 예제에서 `DEDENT`가 두 번 연속 나온 이유가 이것이다.

여기서 쓰는 것이 스택이라는 것은 유한 오토마타의 상태로 표현할 수 없다는 뜻이다. 들여쓰기 깊이는 원리적으로 제한이 없기 때문이다. CPython은 `MAXINDENT 100`으로 상한을 두어 유한하게 만들지만, 그것은 배열을 고정 크기로 잡기 위한 타협이지 정규언어라서가 아니다. 뒤에 나오는 `MAXLEVEL 200`, `MAXFSTRINGLEVEL 150`도 언어 명세의 일부가 아니라 구현이 정한 숫자다.

`altindstack`이 하나 더 있는 것은 탭과 공백을 다르게 계산했을 때 결과가 갈리는지 검사하기 위해서다. 탭을 1로 셌을 때와 8로 셌을 때 들여쓰기 관계가 달라지면 `TabError`를 낸다.

## 괄호 깊이와 f-string 모드 스택

위 출력에서 `[1,` 다음의 개행은 `NEWLINE`이 아니라 `NL`로 나왔다. 대괄호 안이기 때문이다.

```c
/* Newline */
if (c == '\n') {
    tok->atbol = 1;
    if (blankline || tok->level > 0) {
        /* ... NEWLINE을 내보내지 않고 다음 줄로 */
        goto nextline;
    }
    return MAKE_TOKEN(NEWLINE);
}
```

`tok->level`이 괄호 중첩 깊이다. 여는 괄호에서 늘고 닫는 괄호에서 준다. 같은 `\n` 문자가 문맥에 따라 문장 끝이 되기도 하고 아무 의미 없는 공백이 되기도 하므로, 정규표현 하나로는 이 구분을 표현할 수 없다.

`parenstack`은 깊이만이 아니라 어떤 괄호였는지도 기억한다. `(`로 열고 `]`로 닫는 것을 잡기 위해서다.

```c
if (tok->level > 0) {
    tok->level--;
    int opening = tok->parenstack[tok->level];
    if (!((opening == '(' && c == ')') ||
          (opening == '[' && c == ']') ||
          (opening == '{' && c == '}'))) { /* 오류 */ }
}
```

괄호 짝 맞추기는 원래 파서의 일이다. 문맥 자유 문법의 전형적인 예이고 렉서가 할 수 있는 일이 아니다. 그런데 개행 처리를 위해 깊이를 세야 하다 보니, 이왕 세는 김에 짝까지 검사해서 에러 메시지를 개선한 것이다.

깊이 하나로 부족한 경우가 f-string이다. 3.12부터 f-string이 정식 토크나이저 대상이 됐다. 그 전에는 문자열 하나로 읽어서 나중에 따로 파싱했다.

```python
f"{f'{x}'}"
```

```
FSTRING_START 'f"'
OP '{'
FSTRING_START "f'"      ← 중첩
OP '{'
NAME 'x'
OP '}'
FSTRING_END "'"
OP '}'
FSTRING_END '"'
```

f-string 안의 `{...}`는 완전한 파이썬 표현식이고, 그 표현식 안에 또 f-string이 올 수 있다. 토크나이저가 자기 자신을 재귀적으로 호출하는 셈이라, 상태 하나로는 부족하고 모드 스택이 필요하다.

```c
#define MAXFSTRINGLEVEL 150 /* Max f-string nesting level */

tokenizer_mode tok_mode_stack[MAXFSTRINGLEVEL];
int tok_mode_stack_index;
```

각 모드는 그 f-string의 따옴표 종류와 개수, raw 여부, 시작 위치, 중괄호 깊이, 포맷 스펙 안인지 여부 등을 따로 들고 있다.

```c
typedef struct _tokenizer_mode {
    enum tokenizer_mode_kind_t kind;   // TOK_REGULAR_MODE / TOK_FSTRING_MODE
    int curly_bracket_depth;
    int curly_bracket_expr_start_depth;
    char quote;
    int quote_size;
    int raw;
    int in_format_spec;
    int in_debug;
    enum string_kind_t string_kind;    // FSTRING / TSTRING
    /* ... */
} tokenizer_mode;
```

f-string을 만나면 모드를 push하고, 끝나면 pop한다.

```c
if (tok->tok_mode_stack_index + 1 >= MAXFSTRINGLEVEL) {
    return MAKE_TOKEN(_PyTokenizer_syntaxerror(tok,
        "too many nested f-strings or t-strings"));
}
tokenizer_mode *the_current_tok = TOK_NEXT_MODE(tok);
the_current_tok->kind = TOK_FSTRING_MODE;
the_current_tok->quote = quote;
the_current_tok->quote_size = quote_size;
```

따옴표를 모드마다 기억하는 이유는, 안쪽 f-string이 바깥과 다른 따옴표를 쓸 수 있고 `'`를 만났을 때 그것이 어느 문자열의 끝인지 판단해야 하기 때문이다. 중괄호 깊이를 기억하는 이유는 `}`가 표현식의 끝인지 딕셔너리 리터럴의 닫는 괄호인지 구분하기 위해서다. f-string 안의 딕셔너리 리터럴 안의 f-string 안의 포맷 스펙 같은 조합이 실제로 존재하고, 상태가 곱으로 늘어나는 만큼 검증해야 할 경우도 늘어난다.

## 인코딩과 대화형 입력

PEP 263은 소스 파일 첫 두 줄에 인코딩을 선언할 수 있게 한다.

```python
# -*- coding: euc-kr -*-
```

여기에 닭과 달걀 문제가 있다. 이 줄을 읽으려면 인코딩을 알아야 하는데, 인코딩을 알려면 이 줄을 읽어야 한다. 해결책은 첫 두 줄이 ASCII 호환이라고 가정하고 바이트 단위로 쿠키를 찾은 뒤, 알아낸 인코딩으로 전체를 다시 디코딩하는 것이다. `Parser/tokenizer/decoder.c` 519줄이 이 일을 한다.

```
find_cookie()           첫 두 줄에서 coding 선언을 바이트로 찾는다
_PyTok_DetectEncoding() BOM과 쿠키를 함께 판단, 충돌하면 오류
_PyTok_SetEncoding()    이후 디코딩에 사용할 인코딩 확정
_PyTok_DecodeChunk()    청크 단위로 디코딩하며 읽어들인다
```

BOM이 있는데 쿠키가 `utf-8`이 아니면 `"encoding problem: %s with BOM"` 오류를 낸다. 둘이 모순되기 때문이다.

이건 렉싱 이전 단계지만 렉서가 짊어진다. 렉서가 바이트 스트림과 만나는 유일한 지점이기 때문이다.

입력이 파일이 아니라 REPL일 때는 또 다른 상태가 붙는다. "줄이 끝났지만 문장은 안 끝났으니 더 입력받아야 한다"를 표현해야 한다.

```c
enum interactive_underflow_t {
    IUNDERFLOW_NORMAL,  /* 대화형에서 토큰을 더 요청하면 새로 읽는다 */
    IUNDERFLOW_STOP,    /* 강제로 ENDMARKER를 반환해 더 묻지 않는다 */
};
```

`fp_interactive`, `prompt`, `interactive_src_start/end`도 같은 목적이다. 파일을 통째로 읽는 렉서에는 없는 개념이다. 입력이 아직 존재하지 않을 수 있다는 것 자체가 상태다.

## flex의 시작 조건

flex에도 대응책이 있다. **시작 조건**(start condition)으로 렉서를 여러 모드로 나눈다.

```lex
%x COMMENT STRING

%%
"/*"              { BEGIN(COMMENT); }
<COMMENT>"*/"     { BEGIN(INITIAL); }
<COMMENT>.|\n     { /* 무시 */ }

\"                { BEGIN(STRING); }
<STRING>\"        { BEGIN(INITIAL); return STR; }
<STRING>\\n       { /* 이스케이프 */ }
<STRING><<EOF>>   { return ILLEGAL; }   /* 종료되지 않은 문자열 */
```

`%x`는 배타적 시작 조건이라, 그 모드에서는 해당 조건이 붙은 규칙만 활성화된다. 각 모드가 별개의 DFA인 셈이다. flex 저장소의 예제들도 이 방식을 쓴다. `pascal.lex`는 두 종류의 주석에 `%x COMMENT1 COMMENT2`를, `myname2.lex`는 문자열에 `%x STRING`을 쓴다.

여기까지는 깔끔하다. 문제는 모드가 유한 개여야 한다는 점이다. 중첩 없는 주석과 문자열은 시작 조건으로 충분하지만, 중첩 주석은 깊이 카운터를 액션에 직접 둬야 하고, f-string 중첩은 모드 스택이 필요한데 `BEGIN()`은 스택이 아니라 대입이라 표현할 수 없다. 들여쓰기도 스택이 필요하다.

즉 flex의 시작 조건은 상태가 유한할 때만 답이 된다. 그 이상은 액션 안에 C 변수를 두게 되고, 그 순간 "정규표현으로 기술한다"는 원칙이 깨진다. 상태가 액션 코드로 새어 나가면 손으로 짠 렉서와 복잡도가 다르지 않다.

지금까지 나온 요구를 정규표현으로 되는 것과 안 되는 것으로 갈라 보면 이렇다.

| 요구 | 필요한 것 | 정규표현으로 되나 |
|---|---|---|
| 들여쓰기 블록 | 들여쓰기 스택 + 토큰 합성 | 안 됨 |
| 괄호 안 개행 무시 | 깊이 카운터 | 안 됨 |
| 괄호 짝 검사 | 괄호 스택 | 안 됨 (원래 파서의 일) |
| 주석·문자열 | 모드 하나 | 시작 조건으로 됨 |
| 중첩 주석 | 깊이 카운터 | 안 됨 |
| f-string 중첩 | 모드 스택 | 안 됨 |
| 인코딩 선언 | 2패스 읽기 | 해당 없음 |
| 대화형 입력 | 언더플로 상태 | 해당 없음 |

셀 수 있어야 하는 것은 전부 정규표현 밖이다. 유한 오토마타는 상태가 유한하므로 깊이를 기억할 수 없고, 그것이 [렉서와 파서가 나뉘는 경계](./NFA와%20DFA.md)다. 문맥 의존 렉싱이란 결국 그 경계를 렉서 쪽으로 조금 밀어낸 것이고, 밀어낸 만큼 스택과 카운터가 늘어난다. 이 정도가 되면 생성기로 얻을 것이 거의 없어서, GCC와 Clang과 CPython은 전부 스캐너를 손으로 짠다.

---
참고

- [Lexer와 DFA](./Lexer와%20DFA.md)
- [NFA와 DFA](./NFA와%20DFA.md)
- [오토마타 계층](./오토마타%20계층.md)
- [LR 파싱](./LR%20파싱.md)
- <https://peps.python.org/pep-0263/>
- <https://peps.python.org/pep-0701/>
- <https://westes.github.io/flex/manual/Start-Conditions.html>
- <https://github.com/python/cpython/blob/main/Parser/lexer/state.h>
- <https://github.com/python/cpython/blob/main/Parser/lexer/lexer.c>
- <https://github.com/python/cpython/blob/main/Parser/lexer/string.c>
- <https://github.com/python/cpython/blob/main/Parser/tokenizer/decoder.c>
