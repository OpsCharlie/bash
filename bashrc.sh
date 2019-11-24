#!/usr/bin/env bash


# export TERM=xterm-256color

# enable/disable tmux loading
[[ ${USER} = root ]] && EN_TMUX=0 || EN_TMUX=1
command -v tmux &>/dev/null || EN_TMUX=0

# manual set tmux
#EN_TMUX=0

# is git available
[[ -x "$(which git 2>&1)" ]] && GIT_AVAILABLE=1 || GIT_AVAILABLE=0

# set base session and git when logged in via ssh
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    base_session='C-b'
    GIT=0
else
    base_session='C-a'
    # if tmux is enabled, disable git prompt. tmux will show git.
    # [[ $EN_TMUX -eq "1" ]] && GIT=0 || GIT=1
    GIT=1
fi

# enable/disable fuzzy search
EN_FUZZY=1

# ~/.bashrc: executed by bash(1) for non-login shells.
# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace
export HISTTIMEFORMAT="| %d.%m.%y %T =>  "

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=2000
HISTFILESIZE=4000

# Don't record some commands
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi


# Reset
Color_Off='\e[0m'       # Text Reset

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Underline
UBlack='\e[4;30m'       # Black
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
UYellow='\e[4;33m'      # Yellow
UBlue='\e[4;34m'        # Blue
UPurple='\e[4;35m'      # Purple
UCyan='\e[4;36m'        # Cyan
UWhite='\e[4;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Bold High Intensity
BIBlack='\e[1;90m'      # Black
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIBlue='\e[1;94m'       # Blue
BIPurple='\e[1;95m'     # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\e[0;100m'   # Black
On_IRed='\e[0;101m'     # Red
On_IGreen='\e[0;102m'   # Green
On_IYellow='\e[0;103m'  # Yellow
On_IBlue='\e[0;104m'    # Blue
On_IPurple='\e[0;105m'  # Purple
On_ICyan='\e[0;106m'    # Cyan
On_IWhite='\e[0;107m'   # White

# Color man-pages
export LESS_TERMCAP_mb=$'\e[01;31m'       # begin blinking
export LESS_TERMCAP_md=$'\e[01;38;5;74m'  # begin bold
export LESS_TERMCAP_me=$'\e[0m'           # end mode
export LESS_TERMCAP_se=$'\e[0m'           # end standout-mode
# export LESS_TERMCAP_so=$'\e[38;5;246m'    # begin standout-mode - info box
export LESS_TERMCAP_so=$'\e[30;43m'
export LESS_TERMCAP_ue=$'\e[0m'           # end underline
export LESS_TERMCAP_us=$'\e[04;38;5;146m' # begin underline


if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null
then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
else
	color_prompt=
fi

HOST_COLOR=${BGreen}




function _fuzzyfiles()  {
    local IFS=$'\n'
    if [ -z $2 ]; then
        COMPREPLY=( $(\ls) )
    else
        DIRPATH=$(echo "$2" | sed 's|[^/]*$||' | sed 's|//|/|')
        BASENAME=$(echo "$2" | sed 's|.*/||')
        FILTER=$(echo "$BASENAME" | sed 's|.|\0.*|g')
        if [[ $BASENAME == .* ]]; then
            FILES=$(\ls -A $DIRPATH 2>/dev/null)
        else
            FILES=$(\ls -A $DIRPATH 2>/dev/null | egrep -v '^\.')
        fi
        X=$(echo "$FILES" | \grep -i "$BASENAME" 2>/dev/null)
        if [ -z "$X"  ]; then
            X=$(echo "$FILES" | \grep -i "$FILTER" 2>/dev/null)
        fi
        # create array from X
        COMPREPLY=($X)
        # add DIRPATH as prefix
        COMPREPLY=("${COMPREPLY[@]/#/$DIRPATH}")
    fi
    # echo
    # echo DIRPATH=$DIRPATH
    # echo BASENAME=$BASENAME
    # echo FILTER=$FILTER
    # echo COMPREPLY=${COMPREPLY[@]}
    # echo
}

function _fuzzypath() {
    local IFS=$'\n'
    if [ -z $2 ]; then
        COMPREPLY=( $(\ls -d */ | sed 's|/$||') )
    else
        DIRPATH=$(echo "$2" | sed 's|[^/]*$||' | sed 's|//|/|')
        BASENAME=$(echo "$2" | sed 's|.*/||')
        FILTER=$(echo "$BASENAME" | sed 's|.|\0.*|g')
        if [[ $BASENAME == .* ]]; then
            if [ -z "$DIRPATH" ]; then
                DIRS=$(\ls -d .*/ | \egrep -v '^\./$|^\.\./$')
            else
                DIRS=$(\ls -d ${DIRPATH}.*/ | sed "s|^$DIRPATH||g" | \egrep -v '^\./$|^\.\./$')
            fi
        else
            if [ -z "$DIRPATH" ]; then
                DIRS=$(\ls -d ${DIRPATH}*/ 2>/dev/null)
            else
                DIRS=$(\ls -d ${DIRPATH}*/ 2>/dev/null | sed "s|^$DIRPATH||g")
            fi
        fi
        X=$(echo "$DIRS" | \grep -i "$BASENAME" 2>/dev/null | sed 's|/$||g')
        if [ -z "$X"  ]; then
            X=$(echo "$DIRS" | \grep -i "$FILTER" 2>/dev/null | sed 's|/$||g')
        fi
        # create array from X
        COMPREPLY=($X)
        # add DIRPATH as prefix
        COMPREPLY=("${COMPREPLY[@]/#/$DIRPATH}")
    fi
    # echo
    # echo DIRPATH=$DIRPATH
    # echo BASENAME=$BASENAME
    # echo FILTER=$FILTER
    # echo COMPREPLY=${COMPREPLY[@]}
    # echo
}


function timer_now {
    date +%s%N
}

function timer_start {
    timer_start=${timer_start:-$(timer_now)}
}

function timer_stop {
    local delta_us=$((($(timer_now) - $timer_start) / 1000))
    local us=$((delta_us % 1000))
    local ms=$(((delta_us / 1000) % 1000))
    local s=$(((delta_us / 1000000) % 60))
    local m=$(((delta_us / 60000000) % 60))
    local h=$((delta_us / 3600000000))
    # Goal: always show around 3 digits of accuracy
    if ((h > 0)); then timer_show=${h}h${m}m
    elif ((m > 0)); then timer_show=${m}m${s}s
    elif ((s >= 10)); then timer_show=${s}.$((ms / 100))s
    elif ((s > 0)); then timer_show=${s}.$(printf %03d $ms)s
    elif ((ms >= 100)); then timer_show=${ms}ms
    elif ((ms > 0)); then timer_show=${ms}.$((us / 100))ms
    else timer_show=${us}us
    fi
    unset timer_start
}


function __makeTerminalTitle() {
    local title=''

    local CURRENT_DIR="${PWD/#$HOME/\~}"

    if [ -n "${SSH_CONNECTION}" ]; then
        title+="`hostname`:${CURRENT_DIR} [`whoami`@`hostname -f`]"
    else
        title+="${CURRENT_DIR} [`whoami`]"
    fi

    echo -en '\033]2;'${title}'\007'
}
# "
function __getMachineId() {
    if [ -f /etc/machine-id ]; then
        echo $((0x$(cat /etc/machine-id | head -c 15)))
    else
        echo $(( (${#HOSTNAME}+0x$(hostid))))
    fi
}



function __makePS1() {
    local EXIT="$?"

    timer_stop

    # write history immediatly
    history -a

    if [ ! -n "${HOST_COLOR}" ]; then
        local H=$(__getMachineId)
        HOST_COLOR=$(tput setaf $((H%5 + 2))) # foreground
        #HOST_COLOR="\e[4$((H%5 + 2))m" # background
    fi

    PS1=''

    PS1+="\[${Yellow}\]${timer_show} "
    PS1+="${debian_chroot:+($debian_chroot)}"

    if [ ${USER} == root ]; then
        PS1+="\[${BRed}\]" # root
    elif [ ${USER} != ${LNAME} ]; then
        PS1+="\[${BBlue}\]" # normal user
    else
        if [ -n "${SSH_CONNECTION}" ]; then
            PS1+="\[${BGreen}\]" # normal user with ssh
        else
            PS1+="\[${Green}\]" # normal local user
        fi
    fi
    PS1+="\u\[${Color_Off}\]"

    if [ -n "${SSH_CONNECTION}" -o ${USER} == root ]; then
        if [ ${USER} == root ]; then
            PS1+="\[${BRed}\]@\h\[${Color_Off}\]" # host displayed red when root
        else
            PS1+="\[${BGreen}\]@"
            PS1+="\[${HOST_COLOR}\]\h\[${Color_Off}\]" # host displayed only if ssh connection
        fi
    fi

    # PS1+=":\[${BBlue}\]\w" # working directory
    PS1+=":\[\033[38;5;111m\]\w" # working directory

    # background jobs
    local NO_JOBS=`jobs -p | wc -w`
    if [ ${NO_JOBS} != 0 ]; then
        PS1+=" \[${Green}\][j${NO_JOBS}]\[${Color_Off}\]"
    fi

    # screen sessions I don't use screen
    # local SCREEN_PATHS="/var/run/screens/S-`whoami` /var/run/screen/S-`whoami` /var/run/uscreens/S-`whoami`"

    # for screen_path in ${SCREEN_PATHS}; do
        # if [ -d ${screen_path} ]; then
            # SCREEN_JOBS=`ls ${screen_path} | wc -w`
            # if [ ${SCREEN_JOBS} != 0 ]; then
                # local current_screen="$(echo ${STY} | cut -d '.' -f 1)"
                # if [ -n "${current_screen}" ]; then
                    # current_screen=":${current_screen}"
                # fi
                # PS1+=" \[${Green}\][s${SCREEN_JOBS}${current_screen}]\[${Color_Off}\]"
            # fi
            # break
        # fi
    # done

    # git branch
    if [ $GIT_AVAILABLE -eq 1 ] && [ $GIT -eq 1 ]; then
        # local branch="$(git name-rev --name-only HEAD 2>/dev/null)"
        local branch="$(git branch 2>/dev/null | grep '^*' | colrm 1 2)"

        if [ -n "${branch}" ]; then
            local git_status="$(git status --porcelain -b 2>/dev/null)"
            local letters="$( echo "${git_status}" | grep --regexp=' \w ' | sed -e 's/^\s\?\(\w\)\s.*$/\1/' )"
            local untracked="$( echo "${git_status}" | grep -F '?? ' | sed -e 's/^\?\(\?\)\s.*$/\1/' )"
            local status_line="$( echo -e "${letters}\n${untracked}" | sort | uniq | tr -d '[:space:]' )"
            PS1+=" \[${Cyan}\](${branch}"
            if [ -n "${status_line}" ]; then
                PS1+=" ${status_line}"
            fi
            PS1+=")\[${Color_Off}\]"
        fi
    fi

    # exit code
    if [ ${EXIT} != 0 ]; then
        PS1+=" \[${BRed}\][!${EXIT}]\[${Color_Off}\]"
    fi

    # prompt
    # PS1+=" \[${BPurple}\]\\$\[${Color_Off}\] " # prompt
    if [ ${USER} == root ]; then
        PS1+=" \[${BRed}\]\\$\[${Color_Off}\] " # root
    elif [ ${USER} != ${LNAME} ]; then
        PS1+=" \[${BBlue}\]\\$\[${Color_Off}\] " # normal user but not login
    else
        PS1+=" \[${BGreen}\]\\$\[${Color_Off}\] " # normal user
    fi


    __makeTerminalTitle
}

if [ "$color_prompt" = yes ]; then
    if ! logname &>/dev/null; then
        LNAME=${USER}
    else
        LNAME=$(logname)
    fi
    PROMPT_COMMAND=__makePS1
    # PS2="\[${BPurple}\]>\[${Color_Off}\] " # continuation prompt
    if [ ${USER} == root ]; then
        PS2=" \[${BRed}\]>\[${Color_Off}\] " # root
    elif [ ${USER} != ${LNAME} ]; then
        PS2=" \[${BBlue}\]>\[${Color_Off}\] " # normal user
    else
        PS2=" \[${BGreen}\]>\[${Color_Off}\] " # normal user
    fi
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

unset color_prompt force_color_prompt

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# source bash_completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# trap every command
trap 'timer_start' DEBUG

umask 022

export EDITOR=vim
export PAGER=less


# set local bin in path
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# enable ssh-agent
#if [ -z "$SSH_AUTH_SOCK" ] ; then
#    eval `ssh-agent -s`
#fi

# TMUX completion
[[ -f ~/.tmux/tmux_completion.sh ]] && source ~/.tmux/tmux_completion.sh

# enable tmux and start session
if [ $EN_TMUX -eq 1 ]; then
    ## TMUX
    #if which tmux >/dev/null 2>&1; then
    #    #if not inside a tmux session, and if no session is started, start a new session
    #    test -z "$TMUX" && (tmux attach || tmux new-session)
    #fi

    if [ -z "$TMUX" ]; then
        # Create a new session if it doesn't exist
        tmux has-session -t $base_session || tmux new-session -d -s $base_session
        # Are there any clients connected already?
        client_cnt=$(tmux list-clients | wc -l)
        if [ $client_cnt -ge 1 ]; then
            session_name=$base_session"-"$client_cnt
            tmux new-session -d -t $base_session -s $session_name
            tmux -2 attach-session -t $session_name \; set-option destroy-unattached
        else
            tmux -2 attach-session -t $base_session
        fi
    fi
fi

# tab completion like zsh
bind 'set show-all-if-ambiguous on'
bind 'TAB:menu-complete'
bind '"\e[Z": menu-complete-backward'
bind 'set colored-completion-prefix on'
bind 'set colored-stats on'


# enable fuzzy search
if [ $EN_FUZZY -eq 1 ]; then
    complete -o nospace -o filenames -o bashdefault -F _fuzzypath cd mkdir
    complete -o nospace -o filenames -o bashdefault -F _fuzzyfiles ls cat less tail cp mv vi vim
fi


# tab completion case insensitive
bind 'set completion-ignore-case on'

# search history with arrow keys
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'


# https://github.com/dvorka/hstr
# if this is interactive shell, then bind hstr to Ctrl-r (for Vi mode check doc)
# [[ -x $(command -v hstr) ]] && { if [[ $- =~ .*i.* ]]; then bind '"\C-r": "\C-a hstr -- \C-j"'; fi }

# https://github.com/junegunn/fzf
# fuzzy search
# CTRL-T - Paste the selected files and directories onto the command-line
# CTRL-R - Paste the selected command from history onto the command-line
# ALT-C - cd into the selected directory
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
FZF_TMUX=$EN_TMUX
FZF_TMUX_HEIGHT="20%"

# faster find
# https://github.com/sharkdp/fd
command -v fd >/dev/null 2>&1 && FZF_DEFAULT_COMMAND='fd --type f'


