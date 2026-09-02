Pratt 파싱(top-down operator precedence)은 연산자 우선순위를 문법 규칙의 계층이 아니라 토큰에 붙은 정수 하나로 표현하는 하향식 파싱 기법이다.

무엇이 문제였는지부터 보는 게 빠르다. 재귀 하강으로 표현식을 파싱하면 우선순위 단계마다 함수를 하나씩 만들어야 한다.

```
expression → equality
equality   → comparison (('==' | '!=') comparison)*
comparison → sum (('<' | '>') sum)*
sum        → term (('+' | '-') term)*
term       → factor (('*' | '/') factor)*
factor     → ('-' | '!') factor | primary
primary    → NUMBER | IDENT | '(' expression ')'
```

`1 + 2`를 파싱하려고 `expression`을 부르면 `equality → comparison → sum`까지 아무 일도 하지 않는 함수 호출이 세 번 쌓인다. 우선순위 단계가 늘어날수록 이 사슬이 길어지고, C처럼 우선순위가 15단계인 언어에서는 함수 15개와 호출 15번이 된다. 단계를 하나 끼워넣으려면 위아래 두 함수를 모두 고쳐야 한다.

Pratt 파싱은 이 계층을 정수 비교 한 번으로 접는다.

## 우선순위 표

우선순위를 문법이 아니라 맵에 담는다.

```go
const (
    LOWEST      = iota + 1
    EQUALS      // == !=
    LESSGREATER // < >
    SUM         // + -
    PRODUCT     // * /
    PREFIX      // -x, !x
    CALL        // f(x)
    INDEX       // a[i]
)

var precedences = map[TokenType]int{
    EQ:     EQUALS,      NOT_EQ:   EQUALS,
    LT:     LESSGREATER, GT:       LESSGREATER,
    PLUS:   SUM,         MINUS:    SUM,
    SLASH:  PRODUCT,     ASTERISK: PRODUCT,
    LPAREN: CALL,        LBRACKET: INDEX,
}
```

그리고 토큰 타입마다 두 가지 역할의 함수를 등록한다. 앞에 올 때 쓰는 함수(prefix)와 왼쪽 피연산자를 받아 중간에 올 때 쓰는 함수(infix)다. Pratt의 원 논문에서는 각각 null denotation(nud), left denotation(led)이라고 부른다.

```go
type (
    prefixParseFn func() Expression
    infixParseFn  func(Expression) Expression
)

p.registerPrefix(LPAREN, p.parseGroupedExpression) // (a + b)
p.registerInfix(LPAREN, p.parseCallExpression)     // f(a, b)
```

같은 `(`가 위치에 따라 괄호 묶음이 되기도 하고 함수 호출이 되기도 한다. 이 분리가 Pratt 파싱의 핵심이다.

## 엔진

파서 본체는 이 15줄이 전부다.

```go
func (p *Parser) parseExpression(precedence int) Expression {
    prefix := p.prefixParseFns[p.curToken.Type]
    if prefix == nil {
        p.noPrefixParseFnError(p.curToken.Type)
        return nil
    }
    leftExp := prefix()

    // 다음 연산자가 나보다 세면 왼쪽을 넘겨주고, 약하면 여기서 끝낸다
    for !p.peekTokenIs(SEMICOLON) && precedence < p.peekPrecedence() {
        infix := p.infixParseFns[p.peekToken.Type]
        if infix == nil {
            return leftExp
        }
        p.nextToken()
        leftExp = infix(leftExp)
    }
    return leftExp
}
```

`precedence < p.peekPrecedence()` 한 줄이 앞의 문법 계층 전체를 대신한다. 인자로 받은 precedence는 "나를 부른 연산자의 결합력"이고, 이보다 다음 연산자가 세면 오른쪽으로 더 내려가고, 약하면 지금까지 만든 것을 왼쪽 피연산자로 돌려준다.

`1 + 2 * 3`을 따라가면 이렇게 된다.

```
parseExpression(LOWEST=1)
  leftExp = 1,  peek='+'(SUM=4)      1 < 4  → 내려감
  parseInfixExpression(1)
    precedence = SUM = 4
    Right = parseExpression(4)
      leftExp = 2,  peek='*'(PRODUCT=5)   4 < 5  → 내려감
      parseInfixExpression(2)
        precedence = PRODUCT = 5
        Right = parseExpression(5)
          leftExp = 3,  peek=EOF(LOWEST=1)  5 < 1  거짓 → 반환
        → (2 * 3)
      peek=EOF,  4 < 1 거짓 → 반환
    → (1 + (2 * 3))
```

`1 * 2 + 3`이면 `*`가 준 5를 들고 내려간 자리에서 `+`의 4를 만나 `5 < 4`가 거짓이 되므로 `2`만 오른쪽으로 가져간다. 그 결과 `(1 * 2)`가 완성되어 바깥 루프로 돌아가고 `((1 * 2) + 3)`이 된다. 괄호를 어디에 칠지를 정수 비교가 결정한다.

이 엔진이 담당하는 범위는 표현식뿐이다. 문(statement)은 여전히 재귀 하강으로 짜야 하고, 지금 읽는 것이 어떤 문인지 가르는 부분은 `parseExpression()` 위의 평범한 switch다.

## 결합 방향

중위 함수가 재귀 호출에 넘기는 값이 결합 방향을 정한다.

```go
func (p *Parser) parseInfixExpression(left Expression) Expression {
    expression := &InfixExpression{
        Token: p.curToken, Operator: p.curToken.Literal, Left: left,
    }
    precedence := p.curPrecedence()
    p.nextToken()
    expression.Right = p.parseExpression(precedence) // 좌결합
    return expression
}
```

`a - b - c`에서 `b`를 읽은 뒤 다음 `-`를 만나면 `SUM < SUM`이 거짓이라 오른쪽 확장이 멈춘다. 그래서 `((a - b) - c)`가 된다. 여기서 `precedence`를 `precedence - 1`로 바꾸면 `SUM-1 < SUM`이 참이 되어 오른쪽으로 계속 내려가고 `(a - (b - c))`가 된다. 우결합 연산자는 1을 빼서 넘기면 되고, 거듭제곱 `**`처럼 우결합이어야 하는 연산자를 추가할 때 고치는 것은 이 한 글자뿐이다.

정수 하나에 1을 빼는 방식은 편법처럼 보이는데, 연산자마다 왼쪽 결합력과 오른쪽 결합력을 따로 준다고 보면 정체가 드러난다. 숫자는 상대적인 크기만 의미가 있어서, `+`와 `-`에 (1, 2)를, `*`와 `/`에 (3, 4)를 주면 둘 다 왼쪽이 오른쪽보다 작아 좌결합이 되고, `**`에 (6, 5)를 주면 왼쪽이 더 커서 우결합이 된다. 루프 조건은 "다음 연산자의 왼쪽 결합력이 내가 받은 값보다 약하면 멈춘다"가 되고, 재귀에는 그 연산자의 오른쪽 결합력을 넘긴다.

```rust
fn expr_bp(lexer: &mut Lexer, min_bp: u8) -> S {
    let mut lhs = parse_primary(lexer);
    loop {
        let (l_bp, r_bp) = binding_power(peek(lexer));
        if l_bp < min_bp { break; }
        let op = lexer.next();
        let rhs = expr_bp(lexer, r_bp);   // 오른쪽 결합력을 물려준다
        lhs = combine(op, lhs, rhs);
    }
    lhs
}
```

`a - b - c`에서는 두 번째 `-`의 왼쪽 결합력 1이 앞서 물려받은 오른쪽 결합력 2보다 약해서 멈추므로 `((a - b) - c)`가 된다. `2 ** 3 ** 2`에서는 두 번째 `**`의 왼쪽 6이 물려받은 오른쪽 5보다 세서 계속 내려가므로 `(2 ** (3 ** 2))`가 된다. 결합 방향은 두 숫자의 대소일 뿐이고, 앞의 `precedence - 1`은 이 쌍을 정수 하나로 접느라 생긴 표현이다.

같은 기법이 Pratt 파싱과 precedence climbing 두 이름으로 돌아다니는 것도 여기서 설명된다. 두 계보가 서로를 인용하지 않고 독립적으로 발명했다. Pratt(1973)은 Floyd(1963)의 연산자 우선순위 표를 개선한 것이고, precedence climbing이라는 이름이 붙은 Clarke(1986)는 Richards(1979)를 개선한 것이다. 그래서 위키백과에도 문서가 따로 있고 자료마다 다른 이름을 쓴다. 두 전통이 결합 방향을 적는 방식을 나란히 놓으면 같은 것임이 드러난다.

```python
# precedence climbing — 좌결합일 때 1을 더한다
next_min_prec = prec + 1 if assoc == 'LEFT' else prec
atom_rhs = compute_expr(tokenizer, next_min_prec)

# Pratt — 우결합일 때 1을 뺀다
class operator_pow_token:
    lbp = 30
    def led(self, left):
        return left ** expression(30 - 1)
```

Clarke의 원 논문도 `E(if RightAssoc(oper) then oprec else oprec+1)`로 같은 말을 한다. 어느 쪽에 1을 붙이느냐의 차이일 뿐이다. 그리고 Pratt의 1973년 논문은 처음부터 왼쪽 결합력 `lbp`와 오른쪽 결합력 `rbp` 두 숫자를 쓰고 있었다. 앞에서 본 결합력 쌍이 원래 모습이고, 정수 하나로 접은 쪽이 나중에 단순화한 형태다. 남는 차이는 nud/led로 토큰마다 함수를 나누느냐, 단항 연산자와 괄호를 파싱 함수 안에서 직접 처리하느냐뿐인데 이는 코드 구성의 문제이지 알고리즘의 차이가 아니다.

## 연산자가 아닌 것도 중위다

우선순위 표에 `LPAREN: CALL`과 `LBRACKET: INDEX`가 들어 있는 이유가 여기 있다. 함수 호출과 인덱싱은 결합력이 아주 센 중위 연산자로 취급된다. 왼쪽 피연산자를 받아 새 노드를 만든다는 점에서 `+`와 다를 게 없다.

```go
p.registerInfix(LPAREN, p.parseCallExpression)    // add(1, 2)
p.registerInfix(LBRACKET, p.parseIndexExpression) // arr[0]
```

`-arr[0]`에서 `PREFIX(6) < INDEX(8)`이므로 인덱싱이 먼저 묶여 `(-(arr[0]))`이 된다. 재귀 하강이었다면 `primary` 규칙 안에 후위 반복 루프를 따로 만들어야 할 부분이다.

결합력 쌍으로 보면 세 종류가 깔끔하게 갈린다. 한쪽이 비어 있다는 것이 곧 그 방향에 피연산자가 없다는 뜻이다.

- **전위** `-x`: 왼쪽 피연산자가 없으니 오른쪽 결합력만 갖는다. `((), 5)`
- **중위** `a + b`: 양쪽 다 갖는다. `(1, 2)`
- **후위** `a[i]`, `a!`: 오른쪽으로 내려갈 것이 없으니 왼쪽 결합력만 갖는다. `(7, ())`

전위 연산자는 오른쪽 결합력을 들고 재귀 호출을 하고, 후위 연산자는 왼쪽 피연산자가 이미 손에 있으므로 재귀 호출 자체가 없다. 인덱싱이 후위라는 것은 `[` 안쪽을 파싱하지 않는다는 뜻이 아니라, 닫는 `]`가 경계를 만들어주므로 결합력을 물려줄 필요가 없다는 뜻이다. 대괄호 안쪽은 최소 결합력 0으로 새로 시작해서 `]`에서 끝난다. 삼항 연산자 `c ? a : b`도 같은 방식으로, `?`를 중위 연산자로 두고 `:`를 그 문법의 일부로 취급하면 된다.

## PEG

CPython은 정확히 반대로 간다. 우선순위를 규칙의 계층으로 표현하고, 그 문법 파일로부터 파서를 생성한다. `Grammar/python.gram`의 산술 부분이다.

```
sum[expr_ty]:
    | a=sum '+' b=term { _PyAST_BinOp(a, Add, b, EXTRA) }
    | a=sum '-' b=term { _PyAST_BinOp(a, Sub, b, EXTRA) }
    | invalid_arithmetic
    | term

term[expr_ty]:
    | a=term '*' b=factor { _PyAST_BinOp(a, Mult, b, EXTRA) }
    | a=term '/' b=factor { _PyAST_BinOp(a, Div, b, EXTRA) }
    | a=term '//' b=factor { _PyAST_BinOp(a, FloorDiv, b, EXTRA) }
    | a=term '%' b=factor { _PyAST_BinOp(a, Mod, b, EXTRA) }
    | factor

factor[expr_ty] (memo):
    | '+' a=factor { _PyAST_UnaryOp(UAdd, a, EXTRA) }
    | '-' a=factor { _PyAST_UnaryOp(USub, a, EXTRA) }
    | '~' a=factor { _PyAST_UnaryOp(Invert, a, EXTRA) }
    | power

power[expr_ty]:
    | a=await_primary '**' b=factor { _PyAST_BinOp(a, Pow, b, EXTRA) }
    | await_primary
```

`{ }` 안이 AST 노드를 만드는 액션이다. 앞에서 본 재귀 하강 문법과 모양이 같은데, 결합 방향의 표현이 다르다.

- `sum: sum '+' term`은 **좌재귀**라서 좌결합이다.
- `power: await_primary '**' factor`는 오른쪽이 `factor`로 되돌아가는 **우재귀**라서 우결합이다. `2 ** 3 ** 2`가 `2 ** (3 ** 2)`가 되는 근거가 이 한 줄이다.

Pratt에서 정수에 1을 더하고 빼던 것을 여기서는 재귀의 방향으로 적는다.

PEG는 본래 좌재귀를 지원하지 않는다. `sum`을 확장하려고 `sum`을 부르면 무한 루프가 되기 때문이다. CPython의 생성기는 메모이제이션을 이용해 좌재귀 규칙을 지원하도록 확장되어 있다(`InternalDocs/parser.md`). 그래서 문법을 사람이 읽기 좋은 좌재귀 형태 그대로 쓸 수 있다.

또 하나의 특징은 무제한 백트래킹이다. 어떤 대안을 끝까지 시도해보고 실패하면 입력 위치를 되돌려 다음 대안을 본다. 이게 지수 시간이 되지 않는 이유는 packrat 메모이제이션 덕분이고, `factor[expr_ty] (memo)`처럼 명시적으로 표시된 규칙이 20개 있다. 좌재귀 규칙은 구현상 항상 메모이제이션을 쓴다.

규모는 이렇다. 규칙 277개 · 문법 1,661줄이 `Parser/parser.c` 39,628줄로 생성된다. 사람이 유지보수하는 것은 앞의 1,661줄뿐이다.

| | Pratt | PEG |
|---|---|---|
| 우선순위 표현 | 토큰 → 정수 맵 | 규칙 계층의 깊이 |
| 결합 방향 | 재귀에 넘기는 값 ±1 | 좌재귀 / 우재귀 |
| 단계 추가 비용 | 상수 하나 + 맵 두 줄 | 규칙 추가 + 위아래 연결 수정 + 재생성 |
| 위치별 역할 | prefix / infix 함수로 분리 | 규칙 대안으로 분리 |
| 코드량 | 엔진 15줄 + 연산자당 맵 항목 하나 | 문법 1,661줄 → 생성 39,628줄 |
| 모호성 | 정수 순서로 결정 | ordered choice, 먼저 쓴 대안이 이김 |
| 문법의 소재 | 코드가 곧 문법 | 문법이 곧 코드 |

마지막 행이 실제로 갈리는 지점이다. Pratt에서는 우선순위가 맵에, 결합 방향이 각 중위 함수의 인자에, 위치별 역할이 등록 코드에 흩어져 있어서 언어 명세를 문서로 뽑거나 문법을 포매터, 신택스 하이라이터, 린터와 공유할 방법이 없다. 파싱 규칙이 임의의 함수라서 모호성이나 도달 불가능한 규칙을 기계적으로 찾을 수도 없다. 반대로 PEG는 생성된 39,628줄을 디버깅해야 하는 순간이 오고, 백트래킹 때문에 에러 메시지가 나빠지기 쉽다. 문법에 `invalid_arithmetic`, `invalid_factor` 같은 규칙이 따로 들어 있는 것이 그 대가다. Python은 3.9에서 LL(1) 파서를 PEG로 교체하면서 그 대가를 치르는 쪽을 택했다.

---
참고

- [문법 변환](./문법%20변환.md)
- [LR 파싱](./LR%20파싱.md)
- [컴파일 과정](../Rust/컴파일%20과정.md)
- <https://matklad.github.io/2020/04/13/simple-but-powerful-pratt-parsing.html>
- <https://www.oilshell.org/blog/2016/11/01.html>
- <https://www.engr.mun.ca/~theo/Misc/exp_parsing.htm>
- <https://dl.acm.org/doi/10.1145/512927.512931>
- <https://peps.python.org/pep-0617/>
- <https://github.com/python/cpython/blob/main/InternalDocs/parser.md>
- <https://github.com/python/cpython/blob/main/Grammar/python.gram>
