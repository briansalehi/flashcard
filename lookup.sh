#!/usr/bin/env bash

buffer="$(mktemp)" || exit 1
keyword="$1"

curl -s "https://dic.b-amooz.com/de/dictionary/w?word=$keyword" --compressed \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9' \
    -H 'Accept-Language: en-US,en;q=0.5' \
    -H 'Accept-Encoding: gzip, deflate, br' \
    -H 'Connection: keep-alive' \
    -H 'Upgrade-Insecure-Requests: 1' > "$buffer"

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
    echo -e "\e[1m${noun}\e[0m $phonetic"
    echo -e "\e[3mpl:\e[0m $plural"
    echo "$possessive"
}

lookup_verb() {
    local verb
    local phonetic
    local exact_match
    local exact_match

    verb="$(sed -n '/entity-anchor/,+1s/\s*\(.*\)\s*/\1/p' "$buffer" | sed '1d')"
    phonetic="$(sed -n '/<span class="text-muted">/s/.*>\(\/.*\/\)<.*/\1/p' "$buffer")"
    exact_match="$(sed -n '/translation-index/,+4p' "$buffer" | grep '<strong>' | awk '{print $2}')"

    echo "$exact_match"
    echo
    echo -e "\e[1m${verb}\e[0m $phonetic"
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
    echo -e "\e[1m${adjective}\e[0m $phonetic"
}

word_type_fa="$(sed -n '/part-of-speech/,+1s/.*\[\(.*\)\].*/\1/p' "$buffer" | sed -n '1p')"

case "$word_type_fa" in
    "اسم") lookup_noun ;;
    "فعل") lookup_verb ;;
    "صفت") lookup_adjective ;;
esac

echo "$buffer"
