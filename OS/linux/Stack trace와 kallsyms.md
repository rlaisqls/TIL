# Stack Frame

<img width="472" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/be6e0da1-4174-48e6-95ce-41106eec2f51">

- frame pointer 레지스터는 linked list 구조처럼 스택에 있는 이전의 frame pointer의 주소를 저장한다. (마지막 프레임은 다음 프레임이 없으므로 0을 저장한다.)
- stack의 frame pointer 앞에는 LR 레지스터의 값(리턴시 점프할 주소)도 같이 저장된다.
- 위와 같은 특성을 이용하면, stack frame을 순회하면서 frame pointer와 LR의 값들을 확인할 수 있다. 아래는 이 특성을 이용하여 구현한 단순한 `dump_stack` 함수이다.

    ```c
    #include <stdint.h>
    #include <stdio.h>
            
    void dump_stack()
    {          
            uint64_t *fp;
            uint64_t lr;
            
            fp = __builtin_frame_address(0);  
            
            for (;fp;fp=(uint64_t*)*fp) {     
                    lr = fp[1];
                    printf(" [lr:%016lx fp:%016lx]\n", lr, fp[0]);
            }  
    }          
            
    int main(){
            dump_stack();
    }
    ```

- 해당 코드를 ARM64에서 실행하면 아래와 같은 결과를 얻을 수 있다. frame pointer가 0에 도달할 때까지 stack frame을 순회한 것을 알 수 있다.

    ```bash
    [lr:00000055751977d8 fp:0000007fe9015b60]
    [lr:0000007f9ac2c090 fp:0000007fe9015b70]
    [lr:0000005575197694 fp:0000000000000000]
    ```

- 하지만 주소만 보여주는 것만으로는 정보를 파악하기 쉽지 않다. 디버깅을 위해선 주소에 대응하는 함수 이름도 같이 출력을 해줘야 한다.
  
# KALLSYMS

- 리눅스에서는 커널의 심볼 정보들을 담당하는 `kallsym`으로 함수 이름(심볼)을 가져올 수 있다.
- `/proc/kallsyms` 파일을 열면 현재 커널의 여러 심볼 정보들을 살펴볼 수 있다.

## Kallsyms에서 정보를 읽어오는 과정 (`/scripts/kallsyms.c`)

- [`/scripts/kallsyms.c`](https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c)라는 스크립트를 사용해 vmlinux의 심볼 정보들을 편하게 읽을 수 있다.
- 해당 스크립트는 별도로 컴파일 되어 실행 가능한 파일이다. 입력으로는 파일의 심볼을 읽는 `nm` 유틸리티의 stdout을 사용한다.
- 이 스크립트를 기준으로 kallsyms의 구조를 살펴보자.

- kallsyms에서 주로 사용되는 구조체는 4개가 있다.
  - `sym_entry`: 하나의 심볼에 대응하는 자료 구조이다. 심볼의 주소(`addr`), 이름(`sym[]`)을 저장한다.
  - `addr_range`: 어떤 영역에 대응하는 자료 구조 입니다. 영역의 시작과 끝에 대응하는 심볼과 주소를 저정한다.
  - `token_profit`: 2개의 문자로 이루어진 문자열의 빈도 수를 기록하는 테이블이다. 2개의 문자가 가질 수 있는 조합 수는 `0x10000`(=256x256) 이므로 테이블의 길이는 `0x10000` 이다.
  - `best_table`: 압축에 사용되는 매핑 테이블이다. 각각의 char이 매핑되는 문자열을 저장한다.

    ```c
    struct sym_entry {
        unsigned long long addr;
        unsigned int len;
        unsigned int start_pos;
        unsigned int percpu_absolute;
        unsigned char sym[];
    };

    struct addr_range {
            const char *start_sym, *end_sym;
            unsigned long long start, end;
    };

    static struct sym_entry **table;
    static unsigned int table_size, table_cnt;

    static int token_profit[0x10000];

    /* the table that holds the result of the compression */
    static unsigned char best_table[256][2];
    static unsigned char best_table_len[256];
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c#L35
    ```

- addr_range는 아래와 같이 총 3개의 영역(text, init text, percpu)을 미리 정의한 뒤 실행된다. 각 영역의 시작과 끝에 대응하는 심볼은 알지만 그 주소는 아직 모르기 때문이다.

    ```c
    static struct addr_range text_ranges[] = {
        { "_stext",     "_etext"     },
        { "_sinittext", "_einittext" },
    };
    #define text_range_text     (&text_ranges[0])
    #define text_range_inittext (&text_ranges[1])

    static struct addr_range percpu_range = {
        "__per_cpu_start", "__per_cpu_end", -1ULL, 0
    };
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c#L44
    ```

- 전체 과정은 크게 5단계로 나뉜다.

    ```c
    int main(int argc, char **argv) {
            if (argc >= 2) {
                    int i;
                    for (i = 1; i < argc; i++) {
                            if(strcmp(argv[i], "--all-symbols") == 0)
                                    all_symbols = 1;
                            else if (strcmp(argv[i], "--absolute-percpu") == 0)
                                    absolute_percpu = 1;
                            else if (strcmp(argv[i], "--base-relative") == 0)
                                    base_relative = 1;
                            else
                                    usage();
                    }
            } else if (argc != 1)
                    usage();

            read_map(stdin); // (1)
            shrink_table(); // (2)
            if (absolute_percpu)
                    make_percpus_absolute();
            sort_symbols(); // (3)
            if (base_relative)
                    record_relative_base();
            optimize_token_table(); // (4)
            write_src(); // (5)

            return 0;
    }
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c#L810
    ```

    1. symbol 파싱
    2. 유효하지 않은 심볼 삭제
    3. symbol entry 정렬
    4. symbol entry 압축
    5. symbol entry 출력
   
### 1. symbol 파싱

- `read_map` 함수에서는 symbol을 파싱하고 테이블에 추가한다.
  
    ```c
    static void read_map(FILE *in)
    {
            struct sym_entry *sym;

            while (!feof(in)) {
                    sym = read_symbol(in); // EOF에 도달할 때까지 계속해서 재귀호출한다. 
                    if (!sym)
                            continue;

                    sym->start_pos = table_cnt;

                    if (table_cnt >= table_size) {
                            table_size += 10000;
                            table = realloc(table, sizeof(*table) * table_size);
                            if (!table) {
                            fprintf(stderr, "out of memory\n");
                            exit (1);
                            }
                    }

                    table[table_cnt++] = sym;
            }
    }
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c#L257
    ```

- symbol에 대한 핵심 파싱은 `read_symbol` 함수를 통해 이뤄진다. 파싱한 데이터는 `symbol_entry`의 형태로 반환되고, 테이블에 추가된다.

- 해당 함수는 3가지의 일을 수행한다.

   1. 입력에서 심볼의 주소(addr), 타입(type), 심볼의 이름(name)을 받아온다. 
   2. 받아온 정보들을 이용해 `symbol_entry`를 생성 및 초기화한다. 
   3. 읽어온 심볼이 `addr_range`에 시작과 끝에 해당하는 심볼이라면, 이 심볼의 주소를 `addr_range`에 저장한다.

    ```c
    static struct sym_entry *read_symbol(FILE *in)
    {
            char name[500], type;
            unsigned long long addr;
            unsigned int len;
            struct sym_entry *sym;
            int rc;

            // 표준 입출력을 통해 addr, type, name을 받아온다.
            rc = fscanf(in, "%llx %c %499s\n", &addr, &type, name);
            
            ...
            
            if (strcmp(name, "_text") == 0)
                    _text = addr;

            /* Ignore most absolute/undefined (?) symbols. */
            if (is_ignored_symbol(name, type))
                    return NULL;

            // 전역으로 생성한 percpu addr_range와 text addr_range의 시작과 끝에 해당하는 심볼인지 확인 후, 맞다면 주소를 addr_range에 저장한다.
            check_symbol_range(name, addr, text_ranges, ARRAY_SIZE(text_ranges));
            check_symbol_range(name, addr, &percpu_range, 1);

            /* include the type field in the symbol name, so that it gets
            * compressed together */

            // sym_entry, type, name을 저장할 수 있도록 동적 할당을 받는다. sym_entry.sym[0]에 type을 저장하기에 문자열의 크기보다 1 더 큰 사이즈를 요청한다.
            len = strlen(name) + 1;
            sym = malloc(sizeof(*sym) + len + 1);
            if (!sym) {
                    fprintf(stderr, "kallsyms failure: "
                            "unable to allocate required amount of memory\n");
                    exit(EXIT_FAILURE);
            }
            // 생성한 sym_entry에 addr, len, type, name을 저장한다. percpu_absolute는 0으로 초기화한다.
            sym->addr = addr;
            sym->len = len;
            sym->sym[0] = type;
            strcpy(sym_name(sym), name);
            sym->percpu_absolute = 0;

            return sym;
    }
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c#L124
    ```

### 2. 유효하지 않은 심볼 삭제

- `shrink_table`에서는 유효하지 않은 `symbol`들을 삭제한다.
- 테이블을 순회하면서 invalid한 심볼들에 대해 free를 해줌으로써 valid한 symbol_entry만 남도록 한다.

```c
/* remove all the invalid symbols from the table */
static void shrink_table(void)
{
    unsigned int i, pos;

    pos = 0;
    for (i = 0; i < table_cnt; i++) {
        if (symbol_valid(table[i])) {
            if (pos != i)
                table[pos] = table[i];
            pos++;
        } else {
            free(table[i]);
        }
    }
    table_cnt = pos;

    /* When valid symbol is not registered, exit to error */
    if (!table_cnt) {
        fprintf(stderr, "No valid symbol.\n");
        exit(1);
    }
}
// https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c#L234
```

### 3. symbol entry 정렬

- `symbol_entry` 테이블 정렬은 `sort_symbol` 함수에서 실행된다.
- `compare_symbols` 함수를 통해 qsort 방식으로 정렬을 수행한다. 정렬 기준은 주소이고, 주소가 동일한 경우 다른 속성을 비교한다.)

    ```c
    static int compare_symbols(const void *a, const void *b) {
            const struct sym_entry *sa = *(const struct sym_entry **)a;
            const struct sym_entry *sb = *(const struct sym_entry **)b;
            int wa, wb;

            /* sort by address first */
            if (sa->addr > sb->addr)
                    return 1;
            if (sa->addr < sb->addr)
                    return -1;

            ...
    }

    static void sort_symbols(void) {
            qsort(table, table_cnt, sizeof(table[0]), compare_symbols);
    }
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c#L739
    ```


### 4. symbol entry 압축

- symbol entry 압축은 `optimize_table` 함수에서 이뤄진다.
- `optimize_table` 함수는 아래와 같이 총 3개의 단계로 구성되어 있다.

    ```c
    static void optimize_token_table(void) {
        build_initial_token_table();
        insert_real_symbols_in_table();
        optimize_result();
    }
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c#L695
    ```

- `build_initial_tok_table()`: 
  - 구성한 `symbol_entry` 테이블을 순회하면서 `learn_symbol` 함수를 호출한다. 
  - `learn_symbol` 함수는 `symbol_entry`의 `sym`(type+name)과 `len`을 인자로 받는다.
  - `learn_symbol`은 받은 문자열 `symobl_entry.sym`을 순회하면서, `char[2]`의 분포를 `token_profit` 테이블에 반영한다.

    ```c
    /* count all the possible tokens in a symbol */
    static void learn_symbol(const unsigned char *symbol, int len)
    {
        int i;

        for (i = 0; i < len - 1; i++)
            token_profit[ symbol[i] + (symbol[i + 1] << 8) ]++;
    }

    /* decrease the count for all the possible tokens in a symbol */
    static void forget_symbol(const unsigned char *symbol, int len)
    {
        int i;

        for (i = 0; i < len - 1; i++)
            token_profit[ symbol[i] + (symbol[i + 1] << 8) ]--;
    }

    /* do the initial token count */
    static void build_initial_tok_table(void)
    {
        unsigned int i;

        for (i = 0; i < table_cnt; i++)
            learn_symbol(table[i]->sym, table[i]->len);
    }
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c#L554
    ```

- `insert_real_symbols_in_table()`
  - `insert_real_symbols_in_table`은 `symbol_entry` 테이블을 순회하면서 sym에 사용되는 문자를 기록한다.
  - 한 번이라도 사용된 char은 `best_table`에 기록되고, 사용되지 않은 char은 기록되지 않는다.

        ```c
        /* start by placing the symbols that are actually used on the table */
        static void insert_real_symbols_in_table(void)
        {
            unsigned int i, j, c;

            for (i = 0; i < table_cnt; i++) {
                for (j = 0; j < table[i]->len; j++) {
                    c = table[i]->sym[j];
                    best_table[c][0]=c;
                    best_table_len[c]=1;
                }
            }
        }
        // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c#L682
        ```

- `optimize_result()`

  - `optimize_result`는 `best_table`을 순회하면서 사용되지 않은 char을 찾고, 이 char을 빈번하게 사용된 `char[2]`와 매핑한다.
  - 빈번하게 `char[2]`는 앞서 구성한 `token_profit`에서 가장 큰 값을 가진 것에 해당한다.
  - 그런 다음 `symbol_entry`에 사용된 문자열을 매핑한 문자로 치환하는 작업을 수행한다.

    ```c
    /* this is the core of the algorithm: calculate the "best" table */
    static void optimize_result(void)
    {
        int i, best;

        /* using the '\0' symbol last allows compress_symbols to use standard
        * fast string functions */
        for (i = 255; i >= 0; i--) {

            /* if this table slot is empty (it is not used by an actual
            * original char code */
            if (!best_table_len[i]) {

                /* find the token with the best profit value */
                best = find_best_token(); 
                if (token_profit[best] == 0)
                    break;

                /* place it in the "best" table */
                best_table_len[i] = 2;
                best_table[i][0] = best & 0xFF;
                best_table[i][1] = (best >> 8) & 0xFF;

                /* replace this token in all the valid symbols */
                compress_symbols(best_table[i], i);
            }
        }
    }
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c#L653
    ```

    - `compress_symbols` 함수에서 핵심 압축 로직을 수행한다. 첫 번째 인자는 압축할 `char[2]`이고, 두 번째 인자는 매핑된 1byte 정수이다. 
    - `symbol_entry` 테이블을 순회하면서 각 `symbol_entry.sym`에 압축 대상의 문자열이 존재하는지 확인한다. 만약 그렇다면, 해당 문자열을 idx로 치환한다.
    - 압축한 `symbol_entry.sym`을 반영하기 위해 이전의 내용을 지우고(`forget_symbol`), 압축이 완료된 후에는 다시 `learn_symbols`를 호출하여 `token_profit`을 최신으로 업데이트한다.

        ```c
        static void compress_symbols(const unsigned char *str, int idx)
        {
            unsigned int i, len, size;
            unsigned char *p1, *p2;

            for (i = 0; i < table_cnt; i++) {

                len = table[i]->len;
                p1 = table[i]->sym;

                /* find the token on the symbol */
                p2 = find_token(p1, len, str);
                if (!p2) continue;

                /* decrease the counts for this symbol's tokens */
                forget_symbol(table[i]->sym, len);

                size = len;

                do {
                    *p2 = idx;
                    p2++;
                    size -= (p2 - p1);
                    memmove(p2, p2 + 1, size);
                    p1 = p2;
                    len--;

                    if (size < 2) break;

                    /* find the token on the symbol */
                    p2 = find_token(p1, size, str);

                } while (p2);

                table[i]->len = len;

                /* increase the counts for this symbol's new tokens */
                learn_symbol(table[i]->sym, len);
            }
        }
        ```

### 5. symbol entry 출력

- `write_src`에서는 assembly 파일 포맷에 맞춰 필요한 정보들을 출력한다.

- 먼저 Archtiecture(64bit or 32bit)에 따라 매크로(`PTR`, `ALGN`)를 정의한다. 심볼 관련 정보들은 `.rodata` 섹션에 배치된다.

    ```c
    static void write_src(void)
    {
        unsigned int i, k, off;
        unsigned int best_idx[256];
        unsigned int *markers;
        char buf[KSYM_NAME_LEN];

        printf("#include <asm/bitsperlong.h>\n");
        printf("#if BITS_PER_LONG == 64\n");
        printf("#define PTR .quad\n");
        printf("#define ALGN .balign 8\n");
        printf("#else\n");
        printf("#define PTR .long\n");
        printf("#define ALGN .balign 4\n");
        printf("#endif\n");

        printf("\t.section .rodata, \"a\"\n");

        output_label("kallsyms_addresses");
        ...
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/kallsyms.c#L386
    ```

- 그런 다음 `symbol_entry`를 순회하면서 각각의 address를 출력한다. `symbol_entry`의 갯수도 `kallsyms_num_syms`라는 이름으로 출력한다. 출력의 형식은 옵션에 따라 다르다. 

    ```c
        ...
        for (i = 0; i < table_cnt; i++) {
            printf("\tPTR\t%#llx\n", table[i]->addr);
        }
        printf("\n");

        output_label("kallsyms_num_syms");
        printf("\t.long\t%u\n", table_cnt);
        printf("\n");
        ...
    ```

- 그런 다음 `symbol_entry`의 sym을 출력한다. `symbol_entry.sym`은 가변 길이이므로 검색의 용이성을 위해 `marker`라는 검색 인덱스를 만든다. `marker`는 256개의 `symbol_entry.sym`마다 오프셋을 저장한다. 

    ```c
        ...
        /* table of offset markers, that give the offset in the compressed stream
        * every 256 symbols */
        markers = malloc(sizeof(unsigned int) * ((table_cnt + 255) / 256));
        if (!markers) {
            fprintf(stderr, "kallsyms failure: "
                "unable to allocate required memory\n");
            exit(EXIT_FAILURE);
        }

        output_label("kallsyms_names");
        off = 0;
        for (i = 0; i < table_cnt; i++) {
            if ((i & 0xFF) == 0)
                markers[i >> 8] = off;
            ...
                
            if (table[i]->len <= 0xFF) {
                /* Most symbols use a single byte for the length. */
                printf("\t.byte 0x%02x", table[i]->len);
                off += table[i]->len + 1;
            } else {
                /* "Big" symbols use a zero and then two bytes. */
                printf("\t.byte 0x00, 0x%02x, 0x%02x",
                    (table[i]->len >> 8) & 0xFF,
                    table[i]->len & 0xFF);
                    off += table[i]->len + 3;
            }
            for (k = 0; k < table[i]->len; k++)
                printf(", 0x%02x", table[i]->sym[k]);
            printf("\n");
        }
        printf("\n");
        
        /* 마커 출력 */
        output_label("kallsyms_markers");
        for (i = 0; i < ((table_cnt + 255) >> 8); i++)
            printf("\t.long\t%u\n", markers[i]);
        printf("\n");

        free(markers);
        ...
    ```

- 최종적으로 `0x00`에서 `0xFF`까지 순회하면서 char마다 대응하는 문자열 또는 char를 출력한다. 어떤 char은 재압축이 되었을 수도 있으므로 `expand_symbol`을 통해 압축을 해제한 문자열을 buf에 저장한다.
- 이렇게 출력된 정보들은 `kallsyms_token_table`에서 찾을 수 있다.

    ```c
        ...
        output_label("kallsyms_token_table");
        off = 0;
        for (i = 0; i < 256; i++) {
            best_idx[i] = off;
            expand_symbol(best_table[i], best_table_len[i], buf);
            printf("\t.asciz\t\"%s\"\n", buf);
            off += strlen(buf) + 1;
        }
        printf("\n");

        output_label("kallsyms_token_index");
        for (i = 0; i < 256; i++)
            printf("\t.short\t%d\n", best_idx[i]);
        printf("\n");
    }
    ```

- 정리하면, `write_src`는 다음과 같은 여러 정보들을 출력한다.
  - `kallsyms_address`: 심볼들의 주소
  - `kallsyms_num_syms`: symbol의 갯수
  - `kallsyms_names`: symbol들의 압축된 이름
  - `kallsyms_marker`: `kallsyms_names`의 검색 인덱스
  - `kallsyms_token_table`: 압축된 문자(char)가 매핑 된 문자 또는 문자열

## vmlinux 생성 관련 스크립트 (`/scripts/link-vmlinux.sh`)

- vmlinux를 생성하는 Makefile command에서는 `/scripts/link-vmlinux.sh`라는 스크립트가 실행되는데, `CONFIG_KALLSYMS` 옵션이 활성화 되어 있다면 kallsyms 관련 일을 수행한다. 

    ```makefile
    vmlinux: scripts/link-vmlinux.sh autoksyms_recursive $(vmlinux-deps) FORCE
            +$(call if_changed_dep,link-vmlinux)
    ```

- `link-vmlinux.sh`에서 사용되는 핵심 함수는 `vmlinux_link`와 `kallsyms`이다. 
  - `vmlinux_link`: 첫 번째 인자로 받는 오브젝트 파일과 `vmlinux.o`를 링크하고, 두 번째 인자에서 받은 이름으로 출력 파일을 저장한다. 
  - `kallsyms`:  첫 번째 인자로 받은 오프젝트 파일의 심볼 정보를 추출하고 어셈블리 파일으로 저장한다. 이때 저장하는 파일의 이름은 함수의 2번째 인자와 같다.


    ```bash
        # link-vmlinux.sh
        # https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/link-vmlinux.sh#L148
        kallsymso="" # /script/kallsyms을 통해 생성한 최종 오브젝트 파일 이름
        kallsyms_vmlinux="" # /script/kallsyms에 입력으로 넘겨준 최종 오브젝트 파일의 이름  
        if [ -n "${CONFIG_KALLSYMS}" ]; then
            kallsymso=.tmp_kallsyms2.o
            kallsyms_vmlinux=.tmp_vmlinux2

            # (1)
            vmlinux_link "" .tmp_vmlinux1
            kallsyms .tmp_vmlinux1 .tmp_kallsyms1.o

            # (2)
            vmlinux_link .tmp_kallsyms1.o .tmp_vmlinux2
            kallsyms .tmp_vmlinux2 .tmp_kallsyms2.o

            # (3)
            size1=$(${CONFIG_SHELL} "${srctree}/scripts/file-size.sh" .tmp_kallsyms1.o)
            size2=$(${CONFIG_SHELL} "${srctree}/scripts/file-size.sh" .tmp_kallsyms2.o)

            if [ $size1 -ne $size2 ] || [ -n "${KALLSYMS_EXTRA_PASS}" ]; then
                kallsymso=.tmp_kallsyms3.o
                kallsyms_vmlinux=.tmp_vmlinux3

                vmlinux_link .tmp_kallsyms2.o .tmp_vmlinux3

                kallsyms .tmp_vmlinux3 .tmp_kallsyms3.o
            fi
        fi

        info LD vmlinux
        # (4)
        vmlinux_link "${kallsymso}" vmlinux
    ```

  1. `vmlinux.o`를 링크하여 `tmp_vmlinux1`이라는 임시 오브젝트 파일을 생성한다. 이 임시 오브젝트 파일은 kallsyms의 입력 파일로 제공되며, `.tmp_kallsyms1.o`라는 중간 산출물 오브젝트 파일을 생성한다. 해당 중간 산출물 파일은 자신에 대한 심볼 정보(`kallsyms_token_table`, ..)들을 포함하지 않는다.

  2. 앞서 생성한 `.tmp_kallsyms1.o`와 `vmlinux.o`를 링크하여 `.tmp_vmlinux2`라는 오브젝트 파일을 생성한다. 해당 오브젝트는 이전 `.tmp_vmlinux1`와 다르게 `kallsyms` 관련 심볼들에 대한 올바른 정보를 포함하고 있다. 이렇게 생성한 오브젝트 파일을 `/script/kallsyms`의 입력으로 주어 최종적인 심볼 관련 오브젝트 파일 `.tmp_kallsyms2.o`를 생성한다.

  3. `tmp_kallsyms1.o`와 `.tmp_kallsyms2.o`의 크기가 다르다면 변환 단계를 추가로 실행한다.

  4. 최종적으로 `vmlinux.o`와 생성한 최종 오브젝트를 링크하여 `vmlinux` 파일을 생성한다. 

## 심볼 정보 API `kernel/kallsyms.c`

- 해당 파일에서는 생성한 여러 심볼 정보를 사용하는 여러 API를 제공한다.

- 리눅스 커널에서 사용되는 표준 출력 함수인 `printk()`의 포인터 관련 추가 기능에도 내부적으로 `kallsyms`의 API가 사용된다.

- 핵심 함수로 `__sprint_symbol`이 있다.

```c
/* Look up a kernel symbol and return it in a text buffer. */
static int __sprint_symbol(char *buffer, unsigned long address,
                           int symbol_offset, int add_offset, int add_buildid)
{
        char *modname;
        const unsigned char *buildid;
        const char *name;
        unsigned long offset, size;
        int len;

        address += symbol_offset;
        name = kallsyms_lookup_buildid(address, &size, &offset, &modname, &buildid,
                                       buffer);
        if (!name)
                return sprintf(buffer, "0x%lx", address - symbol_offset);

        if (name != buffer)
                strcpy(buffer, name);
        len = strlen(buffer);
        offset -= symbol_offset;

        if (add_offset)
                len += sprintf(buffer + len, "+%#lx/%#lx", offset, size);

        if (modname) {
            ...
        }

        return len;
}
// https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/kernel/kallsyms.c#L482
```

- 주소에 대응하는 정보를 조회하는 `kallsyms_lookup_buildid` 함수를 살펴보자.

    ```c
    static const char *kallsyms_lookup_buildid(unsigned long addr,
                            unsigned long *symbolsize,
                            unsigned long *offset, char **modname,
                            const unsigned char **modbuildid, char *namebuf)
    {
            const char *ret;

            namebuf[KSYM_NAME_LEN - 1] = 0;
            namebuf[0] = 0;

            // 입력으로 받은 주소가 커널 영역인지 확인한다. 아니라면 별도의 처리 루틴으로 빠진다.
            if (is_ksym_addr(addr)) {
                    unsigned long pos;

                    // get_symbol_pos 함수를 통해 주소에 대응하는 심볼의 인덱스를 구한다. 또한 해당 함수의 오프셋과 사이즈도 가져온다.
                    pos = get_symbol_pos(addr, symbolsize, offset);
                    
                    // 구한 인덱스를 가지고 kallsyms_name에 위치한 압축된 문자열을 구한다. 그런 다음 문자열을 압축 해제한다.
                    kallsyms_expand_symbol(get_symbol_offset(pos),
                                        namebuf, KSYM_NAME_LEN);
                    if (modname)
                            *modname = NULL;
                    if (modbuildid)
                            *modbuildid = NULL;

                    // 압축 해제한 문자열의 주소를 반환될 변수에 저장한다.
                    ret = namebuf;
                    goto found;
            }

            /* See if it's in a module or a BPF JITed image. */
            ret = module_address_lookup(addr, symbolsize, offset,
                                        modname, modbuildid, namebuf);
            if (!ret)
                    ret = bpf_address_lookup(addr, symbolsize,
                                            offset, modname, namebuf);

            if (!ret)
                    ret = ftrace_mod_address_lookup(addr, symbolsize,
                                                    offset, modname, namebuf);

    found:
            cleanup_symbol_name(namebuf);
            return ret;
    }
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/kernel/kallsyms.c#L397
    ```

- `get_symbol_pos()` 함수는 조사하려는 주소가 심볼들의 주소를 저장했던 `kallsyms_address`라는 테이블에서 몇 번쨰 인덱스에 해당하는지 탐색한다. 

- 주소에 대응하는 인덱스를 구하는 `get_symbol_pos` 함수는 이진 탐색으로 구현되었다. 앞서 심볼들의 주소를 저장할 때 정렬을 했기 때문에 이진 탐색이 가능하다.

- 다만, 몇몇 심볼들은 동일한 주소를 가지고 있기에 해당 함수의 크기와 오프셋을 구하기 위해 추가적인 루틴이 존재한다.

    ```c
    static unsigned long get_symbol_pos(unsigned long addr,
                                        unsigned long *symbolsize,
                                        unsigned long *offset)
    {
            unsigned long symbol_start = 0, symbol_end = 0;
            unsigned long i, low, high, mid;

            /* This kernel should never had been booted. */
            if (!IS_ENABLED(CONFIG_KALLSYMS_BASE_RELATIVE))
                    BUG_ON(!kallsyms_addresses);
            else
                    BUG_ON(!kallsyms_offsets);

            /* Do a binary search on the sorted kallsyms_addresses array. */
            low = 0;
            high = kallsyms_num_syms;

            while (high - low > 1) {
                    mid = low + (high - low) / 2;
                    if (kallsyms_sym_address(mid) <= addr)
                            low = mid;
                    else
                            high = mid;
            }

            /*
            * Search for the first aliased symbol. Aliased
            * symbols are symbols with the same address.
            */
            while (low && kallsyms_sym_address(low-1) == kallsyms_sym_address(low))
                    --low;

            symbol_start = kallsyms_sym_address(low);

            /* Search for next non-aliased symbol. */
            for (i = low + 1; i < kallsyms_num_syms; i++) {
                    if (kallsyms_sym_address(i) > symbol_start) {
                            symbol_end = kallsyms_sym_address(i);
                            break;
                    }
            }

            /* If we found no next symbol, we use the end of the section. */
            if (!symbol_end) {
                    if (is_kernel_inittext(addr))
                            symbol_end = (unsigned long)_einittext;
                    else if (IS_ENABLED(CONFIG_KALLSYMS_ALL))
                            symbol_end = (unsigned long)_end;
                    else
                            symbol_end = (unsigned long)_etext;
            }

            if (symbolsize)
                    *symbolsize = symbol_end - symbol_start;
            if (offset)
                    *offset = addr - symbol_start;

            return low;
    }
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/kernel/kallsyms.c#L321
    ```

- 구한 인덱스로 압축된 문자열의 주소를 구하기 위해 `get_symbol_offset()` 함수를 사용한다.

    ```c
    /*
    * Find the offset on the compressed stream given and index in the
    * kallsyms array.
    */
    static unsigned int get_symbol_offset(unsigned long pos)
    {
            const u8 *name;
            int i;

            /*
            * Use the closest marker we have. We have markers every 256 positions,
            * so that should be close enough.
            */
            name = &kallsyms_names[kallsyms_markers[pos >> 8]];

            /*
            * Sequentially scan all the symbols up to the point we're searching
            * for. Every symbol is stored in a [<len>][<len> bytes of data] format,
            * so we just need to add the len to the current pointer for every
            * symbol we wish to skip.
            */
            for (i = 0; i < (pos & 0xFF); i++)
                    name = name + (*name) + 1;

            return name - kallsyms_names;
    }
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/kernel/kallsyms.c#L116
    ```



- 다음으로, `kallsyms_expand_symbol()` 함수에서는 구한 pos에 위치한 압축된 문자열을 압축 해제한다. 만약 조사하는 주소가 모듈, bpf, ftrace에 속한다면 별도의 처리를 수행한다.
- 압축 해제를 위해선 `kallsyms_token_table`을 사용한다.

    ```c
    /*
    * Expand a compressed symbol data into the resulting uncompressed string,
    * if uncompressed string is too long (>= maxlen), it will be truncated,
    * given the offset to where the symbol is in the compressed stream.
    */
    static unsigned int kallsyms_expand_symbol(unsigned int off,
                                            char *result, size_t maxlen)
    {
            int len, skipped_first = 0;
            const char *tptr;
            const u8 *data;

            /* Get the compressed symbol length from the first symbol byte. */
            data = &kallsyms_names[off];
            len = *data;
            data++;

            /*
            * Update the offset to return the offset for the next symbol on
            * the compressed stream.
            */
            off += len + 1;

            /* If zero, it is a "big" symbol, so a two byte length follows. */
            if (len == 0) {
                    len = (data[0] << 8) | data[1];
                    data += 2;
                    off += len + 2;
            }

            /*
            * For every byte on the compressed symbol data, copy the table
            * entry for that byte.
            */
            while (len) {
                    tptr = &kallsyms_token_table[kallsyms_token_index[*data]];
                    data++;
                    len--;

                    while (*tptr) {
                            if (skipped_first) {
                                    if (maxlen <= 1)
                                            goto tail;
                                    *result = *tptr;
                                    result++;
                                    maxlen--;
                            } else
                                    skipped_first = 1;
                            tptr++;
                    }
            }

    tail:
            if (maxlen)
                    *result = '\0';

            /* Return to offset to the next symbol. */
            return off;
    }
    // https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/kernel/kallsyms.c#L42
    ```

---
참고
- https://github.com/torvalds/linux/blob/2c8159388952f530bd260e097293ccc0209240be/scripts/link-vmlinux.sh#L148
- https://stackoverflow.com/questions/20196636/does-kallsyms-have-all-the-symbol-of-kernel-functions
- https://www.bhral.com/post/stacktrace%EC%99%80kallsyms%EC%9D%98%EA%B5%AC%ED%98%84%EC%82%B4%ED%8E%B4%EB%B3%B4%EA%B8%B0