if 문 하나를 [bytecode](./opcode.md)처럼 평탄한 instruction 나열로 펼치면 두 가지를 모르는 채로 코드를 만들어야 함

- **position을 모름**: jump를 쓰는 순간엔 어디로 뛰어야 하는지 모름 → backpatching
- **값을 모름**: 두 branch가 합쳐진 뒤 그 값이 어느 branch에서 왔는지 모름 → SSA의 φ
- 둘 다 "join point"의 문제이고, 푸는 요령도 같음: **모르는 건 자리만 잡아두고, 알게 되면 채운다**

## Why jumps

- [tree-walking](./트리%20순회와%20바이트코드.md) interpreter에서 if는 쉬움
  - condition을 평가하고, 참이면 Consequence node만, 아니면 Alternative node만 골라서 내려가면 끝
  - AST node를 손에 쥐고 있으니 branch를 고르는 게 공짜
- bytecode로 컴파일하면 child node가 사라지고 instruction이 한 줄로 늘어섬
  - 그대로 두면 VM이 then과 else를 위에서 아래로 전부 실행해버림
  - 그래서 "건너뛰기" instruction, 즉 jump가 필요함

```
if (true) { 10 } else { 20 }; 3333;

OpTrue            ← 조건
???               ← 거짓이면 else로 뛰어야 함
OpConstant 0      ← then (10)
???               ← then 끝나면 else를 건너뛰어야 함
OpConstant 1      ← else (20)
OpPop
OpConstant 2      ← 3333
OpPop
```

- 『Writing A Compiler In Go』 4장은 빈칸에 두 opcode를 넣음
  - `OpJumpNotTruthy <position>`: stack top이 참이 아니면 jump → then을 건너뜀
  - `OpJump <position>`: unconditional jump → then 끝에서 else를 건너뜀
  - operand는 target의 byte offset(absolute offset), 2-byte 고정

## Forward reference

- compiler는 AST를 위에서 아래로 **한 번만** 걸으며 byte를 이어 붙임
- 그런데 jump를 emit하는 순간엔 target을 모름

| compiler가 하는 일 | 그 시점에 아는 것 |
|---|---|
| condition 컴파일 → `OpTrue` | — |
| `OpJumpNotTruthy` emit | **target 모름** — then이 몇 byte일지 아직 모름 |
| then 컴파일 | then의 길이 |
| `OpJump` emit | **target 모름** — else 길이를 아직 모름 |
| | 이제야 `OpJumpNotTruthy`의 target을 앎 |
| else 컴파일 | 이제야 `OpJump`의 target을 앎 |

- 아직 만들지 않은 코드를 가리켜야 하는 상황 = **forward reference**
- assembler, linker, 문서의 "그림 ?? 참조"에서도 똑같이 나오는 고전적인 문제

## Backpatching

- 책의 표현: *"let's just put garbage in there and fix it later"*
- 세 step으로 끝남
  1. **자리 잡기**: target 자리에 가짜 값 `9999`를 넣어 emit
  2. **position 기억**: 그 instruction이 들어간 position을 variable에 저장
  3. **덮어쓰기**: target을 알게 되면 기억한 position으로 돌아가 `9999`를 진짜 값으로 교체
- 뒤로(back) 돌아가서 덧대기(patch)라서 backpatching
- AST를 한 번만 걷는 single-pass compiler에서 흔한 기법

### Prerequisites

- `emit`이 방금 넣은 instruction의 시작 position을 돌려줌 → step 2 "position 기억"에 씀
  - 책 2장에서 emit을 처음 만들 때부터 "나중에 돌아가 고칠 때 쓴다"고 복선을 깔아둠

```go
func (c *Compiler) emit(op code.Opcode, operands ...int) int {
    ins := code.Make(op, operands...)
    pos := c.addInstruction(ins)
    c.setLastInstruction(op, pos)
    return pos
}
```

- `changeOperand`가 step 3 "덮어쓰기"를 담당
  - operand byte만 만지지 않고, 그 position의 opcode를 읽어 새 operand로 **instruction 전체를 다시 만든 뒤** 같은 자리에 덮어씀
  - big-endian encoding을 `Make`에 맡기려는 것

```go
func (c *Compiler) replaceInstruction(pos int, newInstruction []byte) {
    for i := 0; i < len(newInstruction); i++ {
        c.instructions[pos+i] = newInstruction[i]
    }
}

func (c *Compiler) changeOperand(opPos int, operand int) {
    op := code.Opcode(c.instructions[opPos])
    newInstruction := code.Make(op, operand)
    c.replaceInstruction(opPos, newInstruction)
}
```

### Step by step

- 책 4장의 `*ast.IfExpression` 컴파일 코드

```go
case *ast.IfExpression:
    err := c.Compile(node.Condition)
    // ...
    jumpNotTruthyPos := c.emit(code.OpJumpNotTruthy, 9999)

    err = c.Compile(node.Consequence)
    // ...
    if c.lastInstructionIs(code.OpPop) {
        c.removeLastPop()
    }

    jumpPos := c.emit(code.OpJump, 9999)

    afterConsequencePos := len(c.currentInstructions())
    c.changeOperand(jumpNotTruthyPos, afterConsequencePos)

    if node.Alternative == nil {
        c.emit(code.OpNull)
    } else {
        err := c.Compile(node.Alternative)
        // ...
        if c.lastInstructionIs(code.OpPop) {
            c.removeLastPop()
        }
    }

    afterAlternativePos := len(c.currentInstructions())
    c.changeOperand(jumpPos, afterAlternativePos)
```

- 이 코드를 그대로 옮긴 Go 프로그램([appendix](#appendix-demo-code))으로 `if (true) { 10 } else { 20 }; 3333;`을 컴파일하며 step마다 상태를 찍어보면 아래와 같음
  - `9999`는 big-endian으로 `27 0f`, patch되면 `00 0a`(10), `00 0d`(13)로 바뀜

```
# 1. 조건 + OpJumpNotTruthy 9999          (jumpNotTruthyPos = 1 기억)
0000 OpTrue
0001 OpJumpNotTruthy 9999
   bytes: 06 0d 27 0f

# 2. then 컴파일 후 removeLastPop       (if는 값을 남겨야 하니 OpPop 제거)
0000 OpTrue
0001 OpJumpNotTruthy 9999
0004 OpConstant 0
   bytes: 06 0d 27 0f 00 00 00

# 3. OpJump 9999                        (jumpPos = 7 기억, 구멍 두 개)
0000 OpTrue
0001 OpJumpNotTruthy 9999
0004 OpConstant 0
0007 OpJump 9999
   bytes: 06 0d 27 0f 00 00 00 0e 27 0f

# 4. 패치: @0001의 9999 → 10            (OpJump 뒤 = else 시작)
0000 OpTrue
0001 OpJumpNotTruthy 10
0004 OpConstant 0
0007 OpJump 9999
   bytes: 06 0d 00 0a 00 00 00 0e 27 0f

# 5. else 컴파일 후 removeLastPop
0000 OpTrue
0001 OpJumpNotTruthy 10
0004 OpConstant 0
0007 OpJump 9999
0010 OpConstant 1
   bytes: 06 0d 00 0a 00 00 00 0e 27 0f 00 00 01

# 6. 패치: @0007의 9999 → 13            (구멍 0개)
0000 OpTrue
0001 OpJumpNotTruthy 10
0004 OpConstant 0
0007 OpJump 13
0010 OpConstant 1
   bytes: 06 0d 00 0a 00 00 00 0e 00 0d 00 00 01
```

- 뒤에 if를 감싼 expression statement의 `OpPop`과 `3333`이 붙으면 최종 결과는 책 4장 `TestConditionals`의 기대값과 정확히 같음

```
0000 OpTrue
0001 OpJumpNotTruthy 10
0004 OpConstant 0
0007 OpJump 13
0010 OpConstant 1
0013 OpPop
0014 OpConstant 2
0017 OpPop
```

- block으로 잘라 그려보면 diamond 모양
  - 위에서 갈라져(0000~0001) then(0004~0007)과 else(0010)를 지나 아래(0013~)에서 다시 합쳐짐
  - 이 **join point**가 뒤에서 나올 두 번째 문제(값)가 생기는 곳
- 곁가지 두 개
  - `removeLastPop`: then/else block 끝의 `OpPop`을 잘라냄. if가 값을 내는 식이어야 `let r = if (...) {...} else {...}`가 되기 때문. 이것도 "되돌아가 고치기"의 일종
  - else가 없으면 `OpNull` 한 줄을 가짜 else로 끼워 넣음. 덕분에 항상 `OpJump`를 쓰게 되어 backpatching 코드가 한 가지 모양으로 통일됨

### On the VM side

- VM은 훨씬 쉬움. jump = instruction pointer에 숫자 하나를 assign
- for loop가 매 반복마다 `ip++`를 하니까 target보다 1 작게 넣어둠

```go
case code.OpJump:
    pos := int(code.ReadUint16(ins[ip+1:]))
    ip = pos - 1

case code.OpJumpNotTruthy:
    pos := int(code.ReadUint16(ins[ip+1:]))
    ip += 2
    condition := vm.pop()
    if !isTruthy(condition) {
        ip = pos - 1
    }
```

### Hidden assumption: same-length overwrite

- 책 4장: *"The underlying assumption here is that we only replace instructions of the same type, with the same non-variable length."*
- `9999`도, `10`도, `13`도 전부 2-byte operand
  - 덮어써도 instruction 길이가 그대로라서 뒤쪽 instruction position이 안 밀림
- target에 따라 instruction 길이가 달라진다면?
  - 덮어쓰는 순간 뒤의 모든 instruction position이 밀리고, 이미 채운 다른 jump들까지 틀어짐
- 책은 operand를 2-byte로 고정해서 이 문제를 원천 봉쇄함
  - 대가: function 하나가 65535 bytes를 못 넘고, 짧은 jump도 항상 3 bytes

## Digging deeper into backpatching

- 책은 Monkey에 loop, `break`, `&&`가 없어서 몇 가지 문제를 피해 감

### Multiple holes

```
while (cond) {
    if (a) { break; }   // 구멍 1
    ...
    if (b) { break; }   // 구멍 2
}
// ← 둘 다 여기로
```

- 같은 target을 가리키는 jump가 여럿이고, 그 target(loop 끝)은 맨 나중에야 앎
- Dragon Book(Aho et al. 2판 §6.7)의 backpatching은 hole position 하나가 아니라 **hole list**를 들고 다님
  - `makelist(i)`: hole 하나짜리 목록 만들기
  - `merge(p1, p2)`: 목록 합치기
  - `backpatch(p, target)`: target이 정해지면 목록 전체를 한 번에 채움
- `&&`, `||` short-circuit evaluation도 "참이면 갈 곳" 목록과 "거짓이면 갈 곳" 목록 두 개를 들고 다니는 같은 방식
- Monkey는 이런 구문이 없어서 `jumpNotTruthyPos` 같은 variable 하나로 충분함

### When a patch changes instruction size

- RustPython(= CPython 3.14)은 instruction이 2-byte 단위(opcode 1 + argument 1)
  - argument가 255를 넘으면 앞에 `EXTENDED_ARG`를 붙여 instruction이 길어짐
- 그러면 책이 피한 문제가 그대로 생김
  - jump distance를 채움 → instruction이 길어짐 → 뒤쪽 position이 전부 밀림 → 다른 jump distance도 바뀜
- 그래서 RustPython은 **instruction 크기가 더 이상 안 바뀔 때까지** position 계산과 argument 채우기를 반복함
  - 크기는 커지기만 하니 반드시 멈춤(fixed point)

```rust
// crates/codegen/src/ir.rs — resolve_jump_offsets (CPython assemble.c 이식, 일부 생략)
loop {
    // 1) 지금 크기로 모든 명령의 위치 계산
    for i in 0..instr_sequence.instr_used {
        instr.i_offset = totsize;
        totsize += instr.info.instr_size() as i32;
    }
    // 2) 점프 인자 채우기
    extended_arg_recompile = false;
    for i in 0..instr_sequence.instr_used {
        // ...
        info.arg = OpArg::new(oparg as u32);
        if info.instr_size() != i_size {
            extended_arg_recompile = true;
        }
    }
    if !extended_arg_recompile {
        break;
    }
}
```

### Labels instead of holes

- RustPython은 jump가 byte offset이 아니라 **block index**를 가리킴
- if를 시작할 때 끝 block을 먼저 만들어두면, 그 block이 나중에 몇 번째 byte에 놓일지 몰라도 번호는 바로 쓸 수 있음

```rust
// crates/codegen/src/compile.rs — compile_if (일부 생략)
let end_block = self.new_block();
let next_block = if elif_else_clauses.is_empty() { end_block } else { self.new_block() };

self.compile_jump_if_inner(test, false, next_block, Some(stmt_range))?;
self.compile_statements(body)?;
emit!(self, PseudoInstruction::JumpNoInterrupt { delta: end_block });
self.use_cpython_label_block(next_block);
```

- 되돌아가 고칠 일이 없음. 9999도 없음
- byte offset은 모든 optimization이 끝난 뒤, 위의 `resolve_jump_offsets`가 한 번에 계산
- 책 4장도 이 방식을 짧게 언급함: *"More advanced compilers might leave the target of the jump instructions empty until they know how far to jump and then do a second pass over the AST (or another IR) and fill in the targets."*

| | backpatching (Monkey) | label + assemble (RustPython) |
|---|---|---|
| jump가 가리키는 것 | byte offset (처음엔 9999) | block index |
| address가 정해지는 때 | 그 block 컴파일이 끝나는 즉시 | 모든 optimization이 끝난 뒤 한 번에 |
| 기억해야 하는 것 | hole의 position | block graph 전체 |
| instruction 길이가 바뀌면 | 전제에서 배제 (2-byte 고정) | fixed point까지 재계산 |
| pass 수 | 1 | 여러 개 (codegen → optimization → assemble) |

## The value problem: SSA

### Stack machines merge values by slot

```
let x = if (y > 10) { 1 } else { 2 };

...
OpJumpNotTruthy L1
OpConstant 1        // 스택 칸 k에 1
OpJump L2
L1: OpConstant 2    // 같은 칸 k에 2
L2: OpSetGlobal 0   // 칸 k에서 꺼내 x에
```

- 어느 길로 왔든 값은 **같은 stack slot**에 있음
- local variable도 마찬가지로, 두 branch 모두 같은 `OpSetLocal i` slot에 씀
- 그래서 Monkey와 RustPython의 bytecode compiler는 "이 값이 어디서 왔나"를 따질 일이 없음
- 문제는 값을 자리가 아니라 **name**으로 다루고 싶을 때 생김 — optimization, machine code 생성

### Naming values: which x?

```
x = 1
x = x + 2
y = x * 3     ← 이 x는?
```

- 셋째 줄의 x는 둘째 줄에서 define된 것인데, 그걸 알려면 거꾸로 따라 올라가야 함
- assignment가 여러 번이고 branch까지 섞이면 "reaching definitions" 분석이 필요
- optimizer는 이 def-use 관계를 계속 물어봄 → 같은 name이 여러 값을 가리키는 게 문제

### SSA: every name is defined exactly once

```
x1 = 1
x2 = x1 + 2
y1 = x2 * 3
```

- assign할 때마다 새 name을 붙이면 **name 자체가 def-use 연결**이 됨
  - x2를 쓰는 곳은 무조건 둘째 줄의 값
- Static Single Assignment: 코드 텍스트에 definition이 하나라는 뜻. loop에서 여러 번 실행되는 건 괜찮음
- [intermediate representation](./중간언어.md)에서 본 three-address code의 temporary name이 reassignment되지 않는 형태

### At the join point: φ

```
if (y > 10)
    x1 = 1
else
    x2 = 2

x3 = φ(x1, x2)
return x3 * y
```

- join point에서 x는 x1일 수도, x2일 수도 있음
- φ(파이): **어느 길로 왔느냐**에 따라 값을 고르는 pseudo instruction
- 사실 Monkey의 "같은 stack slot"을 name의 세계에서 표현한 것
- 실제 LLVM IR 모양은 [code optimization](./코드%20최적화.md)의 `phi` 참고

### Two ways to build SSA

- **나중에 한꺼번에** (Cytron et al. 1991)
  - variable을 일단 전부 memory slot에 두고, CFG를 다 만든 뒤 φ를 둘 곳을 계산해서 승격
  - "dominance frontier"라는 개념으로 position을 찾음
  - LLVM(clang)이 이 계열
- **만들면서 바로** (Braun et al. 2013, *Simple and Efficient Construction of SSA Form*)
  - AST나 bytecode를 번역하는 **도중에** variable을 읽을 때마다 그 자리에서 결정
  - Cranelift의 `cranelift-frontend`가 이 방식이고, RustPython JIT가 Cranelift를 씀

### Braun's algorithm and sealing

- variable x를 읽으면
  - 이 block에 x definition이 있다 → 그걸 씀
  - predecessor block이 하나 → 거기서 찾음
  - predecessor block이 여럿 → φ를 만들고 각 predecessor에서 찾아 argument로 넣음
- 그런데 **predecessor block을 아직 다 모른다면?**
  - loop header가 대표적: back edge는 loop body를 다 번역해야 생김
- 그래서 block마다 sealed/unsealed 상태를 둠
  - seal = "이 block의 predecessor block은 이제 다 정해졌다"는 선언
  - seal 전에 variable을 읽으면 φ **자리만** 만들고, argument는 비워둔 채 "채워야 할 variable" 목록에 적어둠
  - seal되는 순간 각 predecessor block에서 값을 찾아 채움
- 어디서 본 요령 같음 → backpatching

### Measured: before and after sealing

- RustPython JIT와 같은 버전의 Cranelift(`cranelift-frontend` 0.132.3, RustPython `Cargo.lock` 기준)로 직접 SSA를 만들어 찍어봄 (전체 코드는 [appendix](#appendix-demo-code))
- Cranelift는 φ 대신 **block parameter**를 씀. `jump block3(v2)`가 곧 φ의 입력 하나

```rust
// pick(y) { if y > 10 { x = 1 } else { x = 2 }; return x * y }  (일부 생략)
let x = b.declare_var(I32);
// ...
b.switch_to_block(then_b);
let one = b.ins().iconst(I32, 1);
b.def_var(x, one);
b.ins().jump(merge, &[]);

b.switch_to_block(else_b);
let two = b.ins().iconst(I32, 2);
b.def_var(x, two);
b.ins().jump(merge, &[]);

b.switch_to_block(merge);
let xv = b.use_var(x);          // merge는 아직 봉인 전
let r = b.ins().imul(xv, y);
b.ins().return_(&[r]);

println!("{}", b.func.display());
b.seal_all_blocks();
println!("{}", b.func.display());
```

- seal 전: join block `block3`에 φ 자리(`v4`)만 있고, 들어오는 jump는 **빈손**

```
block1:
    v2 = iconst.i32 1
    jump block3
block2:
    v3 = iconst.i32 2
    jump block3
block3(v4: i32):
    v5 = imul v4, v0
    return v5
```

- `seal_all_blocks()` 후: jump가 값을 넘기도록 **채워짐**

```
block1:
    v2 = iconst.i32 1
    jump block3(v2)  ; v2 = 1
block2:
    v3 = iconst.i32 2
    jump block3(v3)  ; v3 = 2
block3(v4: i32):
    v5 = imul v4, v0
    return v5
```

- loop라면 seal을 미뤄야 하는 이유가 더 잘 보임
  - `sum(n) { s = 0; i = 0; while i < n { s = s + i; i = i + 1 }; return s }`
  - seal 전: loop header를 처음 번역할 때 back edge가 아직 없으니, 모든 block에 φ 후보가 붙음

```
block0(v0: i32):
    v1 = iconst.i32 0
    jump block1
block1(v2: i32):
    v3 = icmp slt v2, v0
    brif v3, block2, block3
block2(v4: i32, v5: i32):
    v6 = iadd v4, v5
    v7 = iadd_imm v5, 1
    jump block1
block3(v8: i32):
    return v8
```

- seal 후: 들어오는 값이 하나뿐인 φ는 trivial φ로 지워지고 alias(`v5 -> v2`)가 됨
  - 남는 건 loop header의 두 개: `v2` = i, `v9` = s
  - entry jump는 `(0, 0)`을, body에서 돌아오는 jump는 `(i+1, s+i)`를 넘김

```
block0(v0: i32):
    v1 = iconst.i32 0
    jump block1(v1, v1)  ; v1 = 0, v1 = 0
block1(v2: i32, v9: i32):
    v5 -> v2
    v4 -> v9
    v8 -> v9
    v3 = icmp slt v2, v0
    brif v3, block2, block3
block2:
    v6 = iadd.i32 v4, v5
    v7 = iadd_imm.i32 v5, 1
    jump block1(v7, v6)
block3:
    return v8
```

### Sealing is backpatching for SSA

| | backpatching (책 4장) | SSA seal (Braun · Cranelift) |
|---|---|---|
| 모르는 것 | jump의 target position | join block의 predecessor block들 |
| 일단 쓰는 것 | `OpJumpNotTruthy 9999` | block parameter `v4`만, jump는 빈손 |
| 기억하는 것 | `jumpNotTruthyPos` | `undef_variables` (block별 목록) |
| 채우는 때 | then/else 컴파일이 끝났을 때 | `seal_block` — predecessor가 다 정해졌을 때 |
| 채우는 방법 | `changeOperand` | 각 predecessor jump에 argument 추가 |

- position의 문제와 값의 문제가 같은 요령으로 풀림
- loop에서 seal을 loop body 끝까지 미루는 건, Dragon Book backpatching에서 break 목록을 loop 끝에서 채우는 것과 같은 이유

### RustPython JIT

- RustPython의 bytecode compiler(codegen)는 SSA를 안 씀 — stack machine 코드로 바로 가니까
- SSA가 필요해지는 건 machine code를 만드는 `jit` crate(`f.__jit__()`, feature `jit`)
- Python local variable을 Cranelift variable로 선언하고, instruction을 1:1로 바꾸기만 함
  - `STORE_FAST` → `def_var`, `LOAD_FAST` → `use_var`
  - SSA 값과 φ(block parameter)는 cranelift-frontend가 알아서 만듦

```rust
// crates/jit/src/instructions.rs (일부 생략)
fn store_variable(&mut self, idx: oparg::VarNum, val: JitValue) -> Result<(), JitCompileError> {
    let builder = &mut self.builder;
    let ty = val.to_jit_type().ok_or(JitCompileError::NotSupported)?;
    let cranelift_ty = ty.to_cranelift().ok_or(JitCompileError::NotSupported)?;
    let local = self.variables[idx].get_or_insert_with(|| {
        let var = builder.declare_var(cranelift_ty);
        Local { var, ty: ty.clone() }
    });
    self.builder.def_var(local.var, val.into_value().unwrap());
    Ok(())
}

Instruction::LoadFast { var_num } | Instruction::LoadFastBorrow { var_num } => {
    let local = self.variables[var_num.get(arg)].as_ref().ok_or(JitCompileError::BadBytecode)?;
    self.stack.push(JitValue::from_type_and_value(local.ty.clone(), self.builder.use_var(local.var)));
    Ok(())
}
```

- bytecode엔 뒤로 가는 jump(`JUMP_BACKWARD`)가 있으니, 번역 도중엔 seal 시점을 따지지 않고 **전부 번역한 뒤 한 번에 seal**함
  - hole을 다 모았다가 끝에서 한꺼번에 채우는 것

```rust
// crates/jit/src/lib.rs
compiler.compile(func_ref, bytecode)?;
// ...
builder.seal_all_blocks();
builder.finalize();
```

- Cranelift 문서도 같은 말을 함: 가능하면 번역 중에 일찍 seal하는 게 효율적이지만, 어려운 frontend는 끝에서 `seal_all_blocks`를 불러도 됨

### Leaving SSA

- φ는 실제 기계에 없는 instruction
- machine code로 갈 때 φ(block parameter)는 **predecessor block 끝의 copy**로 바뀜

```
block1:              block1:
  v2 = 1               r1 ← 1
  jump block3(v2)      r4 ← r1   // 복사
block2:              block2:
  v3 = 2               r3 ← 2
  jump block3(v3)      r4 ← r3   // 복사
block3(v4):          block3:     // r4를 씀
```

- 양쪽 branch가 같은 register r4에 값을 넣어두면 join point는 r4만 보면 됨
- 결국 처음 Monkey가 "같은 stack slot"으로 했던 것과 같은 모양으로 돌아옴
- SSA는 그 사이에서 optimization을 쉽게 하려고 잠깐 "name의 세계"로 옮겨가는 것

## Summary

- 평탄한 코드의 if는 **position**과 **값** 두 가지를 모르는 채로 만들어짐
- position
  - 책은 `9999`로 자리를 잡고 돌아와 채움(backpatching). operand를 2-byte로 고정해서 "같은 길이로만 덮어쓴다"는 전제를 지킴
  - hole이 여러 개면 목록이 필요하고, patch가 크기를 바꾸면 fixed point까지 재계산해야 함
  - RustPython은 block index로 가리키고 끝에서 한 번에 assemble
- 값
  - bytecode는 같은 stack slot에 둬서 문제가 없음
  - name으로 다루려면(optimization, machine code) SSA와 φ가 필요함
  - SSA를 만들면서 짓는 Braun 방식의 seal은 backpatching과 같은 요령이고, RustPython JIT가 그걸 씀

## Appendix: demo code

- 본문의 실측 출력은 전부 아래 코드로 뽑은 것
- 측정 환경: arm64 macOS, Go 1.26.2, Rust(cargo) + cranelift 0.132.3

### Chapter 4 backpatching reproduction (Go)

- 책 4장의 `code.Make`, `emit`, `setLastInstruction`, `removeLastPop`, `replaceInstruction`, `changeOperand`, `*ast.IfExpression` branch를 그대로 옮김
- 책과 다른 점
  - 이 예제에 필요한 opcode definition만 넣음 (opcode 번호는 책의 `iota` 순서 그대로라 byte 값도 같음)
  - `Instructions.String()`은 operand 0개/1개만 처리하게 줄임
  - parser 대신 AST를 손으로 만들고, if branch 중간에 `snap()`으로 상태를 찍음
  - 에러 처리 생략
- 실행

```bash
mkdir monkeybp && cd monkeybp
# main.go 저장
go mod init monkeybp
go run .
```

```go
// Writing A Compiler In Go 4장 코드를 옮겨 백패칭 과정을 단계별로 찍는 재현 프로그램.
// code.Make / Instructions.String / emit / changeOperand / removeLastPop / IfExpression 분기는 책 그대로.
package main

import (
    "bytes"
    "encoding/binary"
    "fmt"
    "strings"
)

type Instructions []byte
type Opcode byte

const (
    OpConstant Opcode = iota
    OpAdd
    OpPop
    OpSub
    OpMul
    OpDiv
    OpTrue
    OpFalse
    OpEqual
    OpNotEqual
    OpGreaterThan
    OpMinus
    OpBang
    OpJumpNotTruthy
    OpJump
    OpNull
)

type Definition struct {
    Name          string
    OperandWidths []int
}

var definitions = map[Opcode]*Definition{
    OpConstant:      {"OpConstant", []int{2}},
    OpPop:           {"OpPop", []int{}},
    OpTrue:          {"OpTrue", []int{}},
    OpJumpNotTruthy: {"OpJumpNotTruthy", []int{2}},
    OpJump:          {"OpJump", []int{2}},
    OpNull:          {"OpNull", []int{}},
}

func Make(op Opcode, operands ...int) []byte {
    def := definitions[op]
    instructionLen := 1
    for _, w := range def.OperandWidths {
        instructionLen += w
    }
    instruction := make([]byte, instructionLen)
    instruction[0] = byte(op)
    offset := 1
    for i, o := range operands {
        width := def.OperandWidths[i]
        switch width {
        case 2:
            binary.BigEndian.PutUint16(instruction[offset:], uint16(o))
        }
        offset += width
    }
    return instruction
}

func (ins Instructions) String() string {
    var out bytes.Buffer
    i := 0
    for i < len(ins) {
        def := definitions[Opcode(ins[i])]
        n := len(def.OperandWidths)
        if n == 1 {
            v := binary.BigEndian.Uint16(ins[i+1:])
            fmt.Fprintf(&out, "%04d %s %d\n", i, def.Name, v)
            i += 3
        } else {
            fmt.Fprintf(&out, "%04d %s\n", i, def.Name)
            i++
        }
    }
    return out.String()
}

// ── 최소 AST ──
type Node interface{}
type Program struct{ Statements []Node }
type ExpressionStatement struct{ Expression Node }
type BlockStatement struct{ Statements []Node }
type IntegerLiteral struct{ Value int64 }
type Boolean struct{ Value bool }
type IfExpression struct {
    Condition   Node
    Consequence *BlockStatement
    Alternative *BlockStatement
}

type EmittedInstruction struct {
    Opcode   Opcode
    Position int
}

type Compiler struct {
    instructions        Instructions
    constants           []int64
    lastInstruction     EmittedInstruction
    previousInstruction EmittedInstruction
}

func (c *Compiler) snap(label string) {
    fmt.Printf("── %s\n%s", label, c.instructions.String())
    fmt.Printf("   bytes: % x\n\n", []byte(c.instructions))
}

func (c *Compiler) Compile(node Node) {
    switch node := node.(type) {
    case *Program:
        for _, s := range node.Statements {
            c.Compile(s)
        }
    case *ExpressionStatement:
        c.Compile(node.Expression)
        c.emit(OpPop)
    case *BlockStatement:
        for _, s := range node.Statements {
            c.Compile(s)
        }
    case *IntegerLiteral:
        c.constants = append(c.constants, node.Value)
        c.emit(OpConstant, len(c.constants)-1)
    case *Boolean:
        if node.Value {
            c.emit(OpTrue)
        }
    case *IfExpression:
        c.Compile(node.Condition)
        // Emit an `OpJumpNotTruthy` with a bogus value
        jumpNotTruthyPos := c.emit(OpJumpNotTruthy, 9999)
        c.snap("1. 조건 + OpJumpNotTruthy 9999")

        c.Compile(node.Consequence)
        c.snap("2. consequence 컴파일 (끝에 OpPop이 붙음)")
        if c.lastInstructionIsPop() {
            c.removeLastPop()
        }
        c.snap("3. removeLastPop")

        // Emit an `OpJump` with a bogus value
        jumpPos := c.emit(OpJump, 9999)
        c.snap("4. OpJump 9999")

        afterConsequencePos := len(c.instructions)
        c.changeOperand(jumpNotTruthyPos, afterConsequencePos)
        c.snap(fmt.Sprintf("5. 패치: @%04d의 9999 → %d", jumpNotTruthyPos, afterConsequencePos))

        if node.Alternative == nil {
            c.emit(OpNull)
        } else {
            c.Compile(node.Alternative)
            if c.lastInstructionIsPop() {
                c.removeLastPop()
            }
        }
        c.snap("6. alternative 컴파일 + removeLastPop")

        afterAlternativePos := len(c.instructions)
        c.changeOperand(jumpPos, afterAlternativePos)
        c.snap(fmt.Sprintf("7. 패치: @%04d의 9999 → %d", jumpPos, afterAlternativePos))
    }
}

func (c *Compiler) emit(op Opcode, operands ...int) int {
    ins := Make(op, operands...)
    pos := c.addInstruction(ins)
    c.setLastInstruction(op, pos)
    return pos
}

func (c *Compiler) addInstruction(ins []byte) int {
    posNewInstruction := len(c.instructions)
    c.instructions = append(c.instructions, ins...)
    return posNewInstruction
}

func (c *Compiler) setLastInstruction(op Opcode, pos int) {
    previous := c.lastInstruction
    last := EmittedInstruction{Opcode: op, Position: pos}
    c.previousInstruction = previous
    c.lastInstruction = last
}

func (c *Compiler) lastInstructionIsPop() bool { return c.lastInstruction.Opcode == OpPop }

func (c *Compiler) removeLastPop() {
    c.instructions = c.instructions[:c.lastInstruction.Position]
    c.lastInstruction = c.previousInstruction
}

func (c *Compiler) replaceInstruction(pos int, newInstruction []byte) {
    for i := 0; i < len(newInstruction); i++ {
        c.instructions[pos+i] = newInstruction[i]
    }
}

func (c *Compiler) changeOperand(opPos int, operand int) {
    op := Opcode(c.instructions[opPos])
    newInstruction := Make(op, operand)
    c.replaceInstruction(opPos, newInstruction)
}

func main() {
    // if (true) { 10 } else { 20 }; 3333;
    prog := &Program{Statements: []Node{
        &ExpressionStatement{Expression: &IfExpression{
            Condition:   &Boolean{Value: true},
            Consequence: &BlockStatement{Statements: []Node{&ExpressionStatement{Expression: &IntegerLiteral{Value: 10}}}},
            Alternative: &BlockStatement{Statements: []Node{&ExpressionStatement{Expression: &IntegerLiteral{Value: 20}}}},
        }},
        &ExpressionStatement{Expression: &IntegerLiteral{Value: 3333}},
    }}
    c := &Compiler{}
    c.Compile(prog)
    fmt.Println(strings.Repeat("=", 40))
    c.snap("최종 (책 4장 TestConditionals 기대값과 비교)")
}
```

### Cranelift SSA sealing demo (Rust)

- RustPython `Cargo.lock`과 같은 `cranelift-codegen` / `cranelift-frontend` 0.132.3을 씀
- `src/main.rs`는 if/else(`pick`), `src/bin/loop.rs`는 loop(`sum`)
- 둘 다 seal 전에 `b.func.display()`로 한 번, `seal_all_blocks()` 후에 한 번 찍음
  - seal 전의 function은 jump argument가 비어 있는 미완성 상태라 그대로 machine code로 내릴 수는 없음. 출력용으로만 찍는 것
- 실행

```bash
cargo new ssademo && cd ssademo
# Cargo.toml, src/main.rs, src/bin/loop.rs 저장
cargo run --bin ssademo   # pick
cargo run --bin loop      # sum
```

`Cargo.toml`

```toml
[package]
name = "ssademo"
version = "0.1.0"
edition = "2021"

[dependencies]
cranelift-codegen = "=0.132.3"
cranelift-frontend = "=0.132.3"
```

`src/main.rs`

```rust
// pick(y) { if y > 10 { x = 1 } else { x = 2 }; return x * y }
use cranelift_codegen::ir::condcodes::IntCC;
use cranelift_codegen::ir::types::I32;
use cranelift_codegen::ir::{AbiParam, Function, InstBuilder, Signature, UserFuncName};
use cranelift_codegen::isa::CallConv;
use cranelift_frontend::{FunctionBuilder, FunctionBuilderContext};

fn main() {
    let mut sig = Signature::new(CallConv::SystemV);
    sig.params.push(AbiParam::new(I32));
    sig.returns.push(AbiParam::new(I32));
    let mut func = Function::with_name_signature(UserFuncName::testcase("pick"), sig);
    let mut ctx = FunctionBuilderContext::new();
    let mut b = FunctionBuilder::new(&mut func, &mut ctx);

    let entry = b.create_block();
    let then_b = b.create_block();
    let else_b = b.create_block();
    let merge = b.create_block();
    let x = b.declare_var(I32);

    b.append_block_params_for_function_params(entry);
    b.switch_to_block(entry);
    let y = b.block_params(entry)[0];
    let c = b.ins().icmp_imm(IntCC::SignedGreaterThan, y, 10);
    b.ins().brif(c, then_b, &[], else_b, &[]);

    b.switch_to_block(then_b);
    let one = b.ins().iconst(I32, 1);
    b.def_var(x, one);
    b.ins().jump(merge, &[]);

    b.switch_to_block(else_b);
    let two = b.ins().iconst(I32, 2);
    b.def_var(x, two);
    b.ins().jump(merge, &[]);

    b.switch_to_block(merge);
    let xv = b.use_var(x); // merge는 아직 봉인 전 → 자리만 만든 block param
    let r = b.ins().imul(xv, y);
    b.ins().return_(&[r]);

    println!("=== before seal_all_blocks ===\n{}", b.func.display());
    b.seal_all_blocks();
    println!("=== after seal_all_blocks ===\n{}", b.func.display());
    b.finalize();
}
```

`src/bin/loop.rs`

```rust
// sum(n) { s = 0; i = 0; while i < n { s = s + i; i = i + 1 }; return s }
use cranelift_codegen::ir::condcodes::IntCC;
use cranelift_codegen::ir::types::I32;
use cranelift_codegen::ir::{AbiParam, Function, InstBuilder, Signature, UserFuncName};
use cranelift_codegen::isa::CallConv;
use cranelift_frontend::{FunctionBuilder, FunctionBuilderContext};

fn main() {
    let mut sig = Signature::new(CallConv::SystemV);
    sig.params.push(AbiParam::new(I32));
    sig.returns.push(AbiParam::new(I32));
    let mut func = Function::with_name_signature(UserFuncName::testcase("sum"), sig);
    let mut ctx = FunctionBuilderContext::new();
    let mut b = FunctionBuilder::new(&mut func, &mut ctx);

    let entry = b.create_block();
    let header = b.create_block();
    let body = b.create_block();
    let exit = b.create_block();
    let s = b.declare_var(I32);
    let i = b.declare_var(I32);

    b.append_block_params_for_function_params(entry);
    b.switch_to_block(entry);
    let n = b.block_params(entry)[0];
    let zero = b.ins().iconst(I32, 0);
    b.def_var(s, zero);
    b.def_var(i, zero);
    b.ins().jump(header, &[]);

    b.switch_to_block(header); // 뒤로 오는 간선(body → header)은 아직 없음
    let iv = b.use_var(i);
    let c = b.ins().icmp(IntCC::SignedLessThan, iv, n);
    b.ins().brif(c, body, &[], exit, &[]);

    b.switch_to_block(body);
    let sv = b.use_var(s);
    let iv2 = b.use_var(i);
    let s2 = b.ins().iadd(sv, iv2);
    b.def_var(s, s2);
    let i2 = b.ins().iadd_imm(iv2, 1);
    b.def_var(i, i2);
    b.ins().jump(header, &[]);

    b.switch_to_block(exit);
    let sr = b.use_var(s);
    b.ins().return_(&[sr]);

    println!("=== before seal_all_blocks ===\n{}", b.func.display());
    b.seal_all_blocks();
    println!("=== after seal_all_blocks ===\n{}", b.func.display());
    b.finalize();
}
```

---
참고

- <https://link.springer.com/content/pdf/10.1007/978-3-642-37051-9_6.pdf>
- <https://github.com/bytecodealliance/wasmtime/blob/main/cranelift/frontend/src/ssa.rs>
- <https://github.com/RustPython/RustPython>
