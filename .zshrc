HISTFILE=~/.histfile
HISTSIZE=5000
SAVEHIST=5000

source $HOME/.aliases

bindkey -e
zstyle :compinstall filename '$HOME.zshrc'

autoload -Uz compinit
compinit

autoload -U promptinit
promptinit
prompt gentoo

# SCREEN CAPTION/HARDSTATUS
case ${TERM} in
	xterm*|rxvt*|Eterm|aterm|kterm|gnome*|interix)
		precmd () {
                    echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/$HOME/~}\007"
                }
		;;
	screen*)
		precmd () {
                    echo -ne "\033k${USER}@${HOSTNAME%%.*}:${PWD/$HOME/~}\033\\"
                }
                preexec () {
                    echo -ne "\033k${USER}@${HOSTNAME%%.*}:${PWD/$HOME/~} $1\033\\"
                }
		;;
esac
