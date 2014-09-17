# Common settings for all Mosai Workshop scripts

# Enables word split on zsh
command -v setopt 2>/dev/null >/dev/null && setopt SH_WORD_SPLIT

# -e exits on any untreated error
# -u exits on any undeclared variable
# -f disables pathname expansion
set -euf