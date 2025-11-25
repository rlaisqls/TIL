#!/bin/bash
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_COLLATE=C
export LANG=en_US.UTF-8
filepath="$HOME/obsidian/TIL"

Y=$(date +%Y)
M=$(date +%m)
D=$(date +%d)
Ymd=$Y-$M-$D

function generate_project_tree() {
    LC_ALL=C LC_COLLATE=C LC_CTYPE=en_US.UTF-8 LANG=en_US.UTF-8 /opt/homebrew/bin/tree . -I '+*' -f --dirsfirst --noreport -I '~' --charset ascii |
    gsed -e 's/[|]-\+/┗━/g' |
    gsed -e 's/[|]/┃/g' |
    gsed -e 's/[`]/┗━/g' |
    gsed -e 's/[-]/━/g' |
    gsed -e "s:\(━ \)\(\(.*/\)\([^/]\+\)\):\1[**\4**](\2)<\/br>:g" |
    gsed -e "s:\[\*\*\(.*\)\.md\*\*\]:\[\1\]:g" |
    gsed -e "s=$filepath/=./=g" |
    gsed -e "s=$filepath=./TIL</br>=g" |
    gsed -e 's/━━━/━/g' |
    gsed -e 's/[ ]/　/g' |
    printf '%b\n' "$(cat)"
}

function generate_project_file_count() {
  find . -type f \( -name "*.md" \) |
    wc -l |
    gsed -e 's/[ ]//g' |
    gsed -e 's/\n//g'
}

function generate_project_derectory_count() {
  find . -type d ! -path "*/.git/*" |
    wc -l |
    gsed -e 's/[ ]//g' |
    gsed -e 's/\n//g'
}

function generate_avg_file_legnth() {
  total=$(file_legnth_total)
  count=$(generate_project_file_count)

  echo $(expr $total / $count)
}

readme="$filepath/README.md"

function generate_readme() {
  readme_template="$filepath/.scripts/readme_template.md"
  cp -f "$readme_template" "$readme"

  generate_project_tree . |
    LANG="UTF-8" perl -p0e 's/__PROJECT_TREE__/`cat`/se' -i ./README.md

  generate_project_file_count . |
    LANG="UTF-8" perl -p0e 's/__FILE_COUNT__/`cat`/se' -i ./README.md

  generate_project_derectory_count . |
    LANG="UTF-8" perl -p0e 's/__DERECTORY_COUNT__/`cat`/se' -i ./README.md
}

generate_readme .
git add $readme
