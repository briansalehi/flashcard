#!/usr/bin/env bash

keyword="$*"
buffer="$(mktemp)" || exit 1
share=$HOME/.local/share/flashcard
notefile=$share/notes
keywords=$share/keywords
practices=$share/practices.csv
grammars=$share/grammars

lookup_noun() {
    local noun
    local phonetic
    local exact_match
    local plural

    noun="$(sed -n '/entity-anchor/,+1s/\s*\(.*\)\s*/\1/p' "$buffer" | sed '1d')"
    phonetic="$(sed -n '/<span class="text-muted">/s/.*>\(\/.*\/\)<.*/\1/p' "$buffer")"
    exact_match="$(sed -n '/translation-index/,+4p' "$buffer" | grep '<strong>' | awk '{print $2}')"
    plural="$(sed -n '/class="d-inline-block"/s/.*:\s*\(.*\)\].*/\1/p' "$buffer" | sed '2d')"
    possessive="$(sed -n '/class="d-inline-block"/s/.*:\s*\(.*\)\].*/\1/p' "$buffer" | sed '1d')"

    echo "$exact_match"
    echo
    echo -e "\e[1m${noun}\e[0m $phonetic \e[2;3mnomen\e[0m"
    [ -n "${plural}" ] && echo -e "${plural} \e[2;3mplural\e[0m"
    [ -n "${possessive}" ] && echo -e "${possessive} \e[2;3mpossessiv\e[0m"
}

lookup_verb() {
    local verb
    local past
    local perfect
    local tokens
    local phonetic
    local exact_match
    local exact_match

    verb="$(sed -n '/entity-anchor/,+1s/\s*\(.*\)\s*/\1/p' "$buffer" | sed '1d')"
    phonetic="$(sed -n '/<span class="text-muted">/s/.*>\(\/.*\/\)<.*/\1/p' "$buffer")"
    exact_match="$(sed -n '/translation-index/,+4p' "$buffer" | grep '<strong>' | awk '{print $2}')"
    tokens="$(grep -A3 'd-inline-block my-0' "$buffer" | xargs | sed 's|\s*</span>\s*|\n|g' | sed 's|.*\[.*:\s*\(.*\)\s*\].*|\1|' | uniq)"
    past="$(sed -n '1p' <<< "$tokens")"
    perfect="$(sed -n '3p' <<< "$tokens")$(sed -n '2p' <<< "$tokens")"

    echo "$exact_match"
    echo
    echo -e "\e[1m${verb}\e[0m $phonetic \e[2;3mverben\e[0m"
    [ -n "${past}" ] && echo -e "${past} \e[2;3mpräteritum\e[0m"
    [ -n "${perfect}" ] && echo -e "${perfect} \e[2;3mperfekt\e[0m"
}

lookup_adjective() {
    local adjective
    local phonetic
    local exact_match
    local exact_match

    adjective="$(sed -n '/entity-anchor/,+1s/\s*\(.*\)\s*/\1/p' "$buffer" | sed '1d')"
    phonetic="$(sed -n '/<span class="text-muted">/s/.*>\(\/.*\/\)<.*/\1/p' "$buffer")"
    exact_match="$(sed -n '/translation-index/,+4p' "$buffer" | grep '<strong>' | awk '{print $2}')"

    echo "$exact_match"
    echo
    echo -e "\e[1m${adjective}\e[0m $phonetic \e[2;3madjektiv\e[0m"
}

save_practice() {
    read -rp "Section: " section
    read -rp "Task: " task
    read -rp "Question: " question
    read -rp "Answer: " answer

    if [ -n "$section" ] && [ -n "$task" ] && [ -n "$question" ] && [ -n "$answer" ]
    then
        echo "${section}::${task}::${question}::${answer}" >> "${practices}"
        echo -e "\e[1;31mPractice saved\e[0m" >&2
    else
        echo -e "\e[1;31mPractice incomplete\e[0m" >&2
    fi
}

save_grammar() {
    local temp
    local title
    local section
    local filename

    temp="$(mktemp)"

    if read -rp "Grammar title: " title && read -rp "Section: " section && $EDITOR "$temp"
    then
        filename="$grammars/${title,,}"
        filename="${title// /-}"

        [ -d "$grammars" ] || mkdir -p "$grammars"

        if ! [ -f "$filename" ]
        then
            echo "$section" > "$filename"
            cat "$temp" >> "$filename"
            echo -e "\e[1;31mGrammar saved: cache $temp\e[0m" >&2
        else
            echo -e "\e[1;31mGrammar name already reserved: cached $temp\e[0m" >&2
        fi
    else
        echo -e "\e[1;31mGrammar could not be saved: cached $temp\e[0m" >&2
    fi
}

if [ "$1" == "save" ] && [ $# -eq 2 ]
then
    [ -d "$share" ] || mkdir -p "$share"
    grep -qw "$2" "$keywords" || echo "$2" >> "$keywords"
    echo -e "\e[1;31mKeyword saved\e[0m" >&2
elif [ "$1" == "save" ]
then
    shift
    [ -d "$share" ] || mkdir -p "$share"
    grep -q "$*" "$notefile" || echo "$*" >> "$notefile"
elif [ "$1" == "practice" ]
then
    save_practice
elif [ "$1" == "grammar" ]
then
    save_grammar
else
    curl -L -s "https://dic.b-amooz.com/de/dictionary/w?word=$keyword" --compressed \
        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        -H 'Accept-Encoding: gzip, deflate, br' \
        -H 'Connection: keep-alive' \
        -H 'Upgrade-Insecure-Requests: 1' > "$buffer"

    word_type_fa="$(sed -n '/part-of-speech/,+1s/.*\[\(.*\)\].*/\1/p' "$buffer" | sed -n '1p')"

    case "$word_type_fa" in
        "اسم") lookup_noun ;;
        "فعل") lookup_verb ;;
        "صفت") lookup_adjective ;;
    esac
fi

rm "$buffer"
