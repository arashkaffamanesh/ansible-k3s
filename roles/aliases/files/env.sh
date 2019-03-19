export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color

ppid () { ps -p ${1:-$$} -o ppid=; }

alias lsd='ls -lhF --color=auto --group-directories-first'
alias lsda='ls -lhaF --color=auto --group-directories-first'
alias logz='find /var/log -type f -mtime -1 -exec tail -Fn0 {} +'
alias df='df -h'
alias mkdir='mkdir -p -v'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias dammit='sudo $(history -p !!)'
alias ssh='SSH_AUTH_SOCK=0 ssh'

export LESS='--quit-if-one-screen --ignore-case --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --tabs=4 --no-init --window=-4'
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:~/bin"
export EDITOR=vim
export PAGER=less
