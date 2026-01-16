## perl option

Perl은 심플한 프로그래밍 언어 중 하나이다. CLI에서 `perl` 명령어를 통해 짧은 스크립트를 실행할 수 있다.

아래와 같이 텍스트 대치 등 간단한 처리 스크립트를 작성하는 데 사용하기 좋다.

```bash
perl -p0e 's/__PROJECT_TREE__/`cat`/se' "$readme_template" > "$readme"
```

1. **실행 제어**
    - -e  : 스크립트로서 실행할 스트링을 지정하여 Command Line에서 수행
    - -M : 펄 모듈을 로드하는 옵션이며, Default Import 하지 않을 경우 -m 옵션을 사용
    - -l   : 표준 장소 앞에서 모듈을 검색하기 위한 디렉토리 지정 
    - -c  : 펄 프로그램을 컴파일(실행전 에러 체크)

2. **데이터**
    - -0  : (zero) Input Record 구분자 지정(00, 0777)
    - -a  : split된 결과를 @F 배열에 사용 (-p, -n)
    - -n  : <>를 사용하여 파일에 레코드 값을 @ARGV 인자로 검색(-p,-e로 정의 및 파일을 한라인씩 처리)
    - -p  : -n과 동일, $_의 내용을 프린트
    - -i  : 파일 편집(perldoc perlnum 참조)
    - -F  : 패턴으로 분활하여 사용(awk -f'|' eq perl -F'|')
    - -s : enable rudimentary parsing for switches after programfile
    - -S : look for programfile using PATH environment variable

3. **위험**
    - -w  : 펄 코드에 대한 에러코드(warning)를 출력 (코드상 use warnings 키워드 사용)

4. **버전**
    - -v   : 버전을 확인 하기 위한 옵션(중요한 펄 정보를 보여줌)
    - -V   : 버전에 대한 구성을 보여주는 옵션(Config.pm 참조)

## 텍스트 치환

```
s/{before}/{after}/;
```

https://www.perl.com/pub/2004/08/09/commandline.html/
https://thdnice.tistory.com/49