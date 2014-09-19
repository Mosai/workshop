# Common settings for all Mosai Workshop scripts

# Enables word split on zsh
setopt SH_WORD_SPLIT >/dev/null 2>&1 || :

# -e exits on any untreated error
# -u exits on any undeclared variable
# -f disables pathname expansion
set -euf
