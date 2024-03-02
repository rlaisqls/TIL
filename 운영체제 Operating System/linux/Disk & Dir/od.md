
`od` is a command that dumps binary files to eight digits.

```bash
od [-aBbcDdeFfHhIiLlOosvXx] [-A base] [-j skip] [-N length] [-t type]
        [[+]offset[.][Bb]] [file ...]
```

|Option|Description|
|-|-|
|-A base|Specify the input address base.  The argument base may be one of d, o, x or n, which specify decimal, octal, hexadecimal addresses or no address, respectively.|
|-a|Output named characters.  Equivalent to `-t a`.|
|-B, -o|Output octal shorts.  Equivalent to `-t o2`.|
|-b|Output octal bytes.  Equivalent to `-t o1`.
|-c|Output C-style escaped characters.  Equivalent to `-t c`.
|-D|Output unsigned decimal ints.  Equivalent to `-t u4`.
|-d|Output unsigned decimal shorts.  Equivalent to `-t u2`.
|-e, -F|Output double-precision floating point numbers. Equivalent to `-t fD`.|
|-f|Output single-precision floating point numbers. Equivalent to `-t fF`.|
|-H, -X|Output hexadecimal ints.  Equivalent to `-t x4`.|
| -h, -x|Output hexadecimal shorts.  Equivalent to `-t x2`.|
|-I, -L, -l|Output signed decimal longs.  Equivalent to `-t dL`.|
|-i|Output signed decimal ints.  Equivalent to `-t dI`.|
|-j skip|Skip skip bytes of the combined input before dumping. The number may be followed by one of b, k, m or g which specify the units of the number as blocks (512 bytes), kilobytes, megabytes and gigabytes, respectively.|
|-N length|Dump at most length bytes of input.|
|-O|Output octal ints. Equivalent to `-t o4`.|
|-s|Output signed decimal shorts. Equivalent to `-t d2`.|
|-t type|Specify the output format. The type argument is a string containing one or more of the following kinds of type specifiers.|
|a|Named characters (ASCII).  Control characters are displayed using the following names:<img width="353" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/c5b6459b-8d53-419f-8b5d-42beb6354eaf">|
|c|Characters in the default character set.  Non-printing characters are represented as 3-digit octal character codes, except the following characters, which are represented as C escapes like `\0`, `\n`, `\t`, so on. Multi-byte characters are displayed in the area corresponding to the first byte of the character. The remaining bytes are shown as ‘**’.|
|[d|o|u|x][C|S|I|L|n]|Signed decimal (d), octal (o), unsigned decimal (u) or hexadecimal (x).  Followed by an optional size specifier, which may be either C (char), S (short), I (int), L (long), or a byte count as a decimal integer.|
|f[F|D|L|n]|Floating-point number.  Followed by an optional size specifier, which may be either F (float), D (double) or L (long double).|
|-v|Write all input data, instead of replacing lines of duplicate values with a ‘*’.|

### Example

File `test`'s content is:

```
abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890
```

`od -t x1 test` -> Express the test file by 1 byte in hexadecimal.

```bash
$ od -t x1 test
0000000    61  62  63  64  65  66  67  68  69  6a  6b  6c  6d  6e  6f  70
0000020    71  72  73  74  75  76  77  78  79  7a  41  42  43  44  45  46
0000040    47  48  49  4a  4b  4c  4d  4e  4f  50  51  52  53  54  55  56
0000060    57  58  59  5a  31  32  33  34  35  36  37  38  39  30  0a
0000077
```

`od -t x1z test` -> Express 1 byte by hexadecimal and display ASCII characters on the below.

```bash
$ od -t x1c test
0000000    61  62  63  64  65  66  67  68  69  6a  6b  6c  6d  6e  6f  70
           a   b   c   d   e   f   g   h   i   j   k   l   m   n   o   p
0000020    71  72  73  74  75  76  77  78  79  7a  41  42  43  44  45  46
           q   r   s   t   u   v   w   x   y   z   A   B   C   D   E   F
0000040    47  48  49  4a  4b  4c  4d  4e  4f  50  51  52  53  54  55  56
           G   H   I   J   K   L   M   N   O   P   Q   R   S   T   U   V
0000060    57  58  59  5a  31  32  33  34  35  36  37  38  39  30  0a
           W   X   Y   Z   1   2   3   4   5   6   7   8   9   0  \n
0000077
```

`od -Ad test` -> Print as demical.

```bash
$ od -Ad test
0000000    061141  062143  063145  064147  065151  066153  067155  070157
0000016    071161  072163  073165  074167  075171  041101  042103  043105
0000032    044107  045111  046113  047115  050117  051121  052123  053125
0000048    054127  055131  031061  032063  033065  034067  030071  000012
0000063
```

---
reference
- https://man7.org/linux/man-pages/man1/od.1.html
- https://m.blog.naver.com/syung1104/191927932
