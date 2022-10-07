INV="$(tput rev)"
COLOR1="$(tput setaf 1)"
RESET="$(tput sgr0)"
EDITOR=nano
GIT_EDITOR=nano
PS1='${INV} \W ${COLOR1} ${RESET} '

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
