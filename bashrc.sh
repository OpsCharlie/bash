# shellcheck disable=SC2034,SC1091,SC1090

# ~/.bashrc: executed by bash(1) for non-login shells.
# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return ;;
esac

function __fzf_complete() {
  [[ ${EN_FUZZY:-0} -eq 1 ]] || return 0

  local IFS=$'\n'
  local comp_type=$1 # 'file' or 'dir'
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local dirpath basename items choice

  if [[ -z $cur ]]; then
    dirpath="."
    basename=""
  else
    if [[ $cur =~ ^~ ]]; then
      cur="${cur/\~/$HOME}"
    fi

    if [[ "$cur" == */* ]]; then
      dirpath="${cur%/*}"
      basename="${cur##*/}"
    else
      dirpath="."
      basename="$cur"
    fi
  fi

  # if dirpath is empty, set to "/" to handle root paths
  [[ -z $dirpath ]] && dirpath="/"

  # ensure dirpath exists
  [[ ! -d "$dirpath" ]] && return 0

  local items
  if command -v fd &>/dev/null; then
    local -a fd_opts
    fd_opts=(--max-depth 1 --follow)
    if [[ "$comp_type" == "dir" ]]; then
      fd_opts+=(--type d)
    fi
    if [[ $basename == .* ]]; then
      fd_opts+=(--hidden)
    fi
    items=$(cd "$dirpath" 2>/dev/null && command fd "${fd_opts[@]}" 2>/dev/null)
  else
    local -a find_args
    find_args=(-L . -maxdepth 1 -mindepth 1)

    if [[ "$comp_type" == "dir" ]]; then
      find_args+=(-type d)
    fi

    if [[ $basename == .* ]]; then
      find_args+=(-name '.*')
    else
      find_args+=('!' -name '.*')
    fi
    items=$(cd "$dirpath" 2>/dev/null && command find "${find_args[@]}" -printf '%f\n' 2>/dev/null | sort -V)
  fi

  [[ -z $items ]] && return 0

  choice=$(printf '%s\n' "$items" | fzf --filter "$basename" --height "20%" --reverse --multi 2>/dev/null)
  [[ -z $choice ]] && return 0

  local -a replies
  mapfile -t replies <<<"$choice"

  if [[ -n $dirpath && $dirpath != "." ]]; then
    local prefix
    if [[ "$dirpath" == "/" ]]; then
      prefix="/"
    else
      prefix="$dirpath/"
    fi
    COMPREPLY=("${replies[@]/#/$prefix}")
  else
    COMPREPLY=("${replies[@]}")
  fi

  # echo
  # echo cur="$cur"
  # echo dirpath="$dirpath"
  # echo basename="$basename"
  # echo choice="$choice"
  # echo COMPREPLY="${COMPREPLY[*]}"
  # echo
}

function _fuzzyfiles() {
  __fzf_complete "file"
}

function _fuzzypath() {
  __fzf_complete "dir"
}

function timer_now() {
  date +%s%N
}

function timer_start() {
  [[ $COMP_LINE ]] && return
  timer_st=${timer_st:-$(timer_now)}
}

function timer_stop() {
  local delta_us us ms s m h
  delta_us=$((($(timer_now) - timer_st) / 1000))
  us=$((delta_us % 1000))
  ms=$(((delta_us / 1000) % 1000))
  s=$(((delta_us / 1000000) % 60))
  m=$(((delta_us / 60000000) % 60))
  h=$((delta_us / 3600000000))
  # Goal: always show around 3 digits of accuracy
  if ((h > 0)); then
    timer_show=${h}h${m}m
  elif ((m > 0)); then
    timer_show=${m}m${s}s
  elif ((s >= 10)); then
    timer_show=${s}.$((ms / 100))s
  elif ((s > 0)); then
    timer_show=${s}.$(printf %03d "$ms")s
  elif ((ms >= 100)); then
    timer_show=${ms}ms
  elif ((ms > 0)); then
    timer_show=${ms}.$((us / 100))ms
  else
    timer_show=${us}us
  fi
  unset timer_st
}

function __makeTerminalTitle() {
  local title=''

  local CURRENT_DIR="${PWD/#$HOME/\~}"

  if [[ -n ${SSH_CONNECTION} ]]; then
    title+="$(hostname):${CURRENT_DIR} [$(whoami)@$(hostname -f)]"
  else
    title+="${CURRENT_DIR} [$(whoami)]"
  fi

  printf '\033]2;%s\007' "$title"
}

function __getMachineId() {
  if [[ -f /etc/machine-id ]]; then
    echo $((0x$(head -c 15 /etc/machine-id)))
  else
    echo $((${#HOSTNAME} + 0x$(hostid)))
  fi
}

function __makePS1() {
  local EXIT="$?"

  timer_stop

  # write history immediately
  history -a

  if [[ -z ${HOST_COLOR} ]]; then
    local H
    H=$(__getMachineId)
    HOST_COLOR=$(tput setaf $((H % 5 + 2))) # foreground
    #HOST_COLOR="\e[4$((H%5 + 2))m" # background
  fi

  PS1=''

  PS1+="\[${Yellow}\]${timer_show} "
  PS1+="${debian_chroot:+($debian_chroot)}"

  if [[ ${USER} == root ]]; then
    PS1+="\[${BRed}\]" # root
  elif [[ ${USER} != "$LNAME" ]]; then
    PS1+="\[${BBlue}\]" # normal user
  else
    if [[ -n ${SSH_CONNECTION} ]]; then
      PS1+="\[${BGreen}\]" # normal user with ssh
    else
      PS1+="\[${Green}\]" # normal local user
    fi
  fi
  PS1+="\u\[${Color_Off}\]"

  if [[ -n ${SSH_CONNECTION} ]] || [[ ${USER} == root ]]; then
    if [[ ${USER} == root ]]; then
      PS1+="\[${BRed}\]@\h\[${Color_Off}\]" # host displayed red when root
    else
      PS1+="\[${BGreen}\]@"
      PS1+="\[${HOST_COLOR}\]\h\[${Color_Off}\]" # host displayed only if ssh connection
    fi
  fi

  # PS1+=":\[${BBlue}\]\w" # working directory
  PS1+=":\[\033[38;5;111m\]\w" # working directory

  # python env
  if [[ -v VIRTUAL_ENV ]]; then
    PS1+=" ${Yellow}(${VIRTUAL_ENV##*/})${Color_Off}"
  fi

  # background jobs
  local NO_JOBS
  NO_JOBS=$(jobs -p | wc -w)
  if [[ ${NO_JOBS} != 0 ]]; then
    PS1+=" \[${Green}\][j${NO_JOBS}]\[${Color_Off}\]"
  fi

  # git branch
  if [[ $GIT_AVAILABLE -eq 1 && $GIT -eq 1 ]]; then
    # Are we inside a repo?
    if git rev-parse --is-inside-work-tree &>/dev/null; then
      local git_status rest branch status letters mask=0

      # get branch + all file status in one command
      git_status=$(git status --porcelain -b 2>/dev/null)

      # read all lines into an array
      mapfile -t lines <<<"$git_status"

      # branch name from first line
      first_line="${lines[0]}"
      branch="${first_line#'## '}"
      branch="${branch%%...*}"

      # letters: S=staged, M=modified, D=deleted, ?=untracked
      for line in "${lines[@]:1}"; do
        [[ -z $line ]] && continue
        c1="${line:0:1}" # staged
        c2="${line:1:1}" # worktree

        # staged
        if (((mask & 1) == 0)) && [[ $c1 =~ [AMDCR] ]]; then
          letters+="S"
          ((mask |= 1))
        fi

        # modified
        if (((mask & 2) == 0)) && [[ $c2 == M ]]; then
          letters+="M"
          ((mask |= 2))
        fi

        # deleted
        if (((mask & 4) == 0)) && [[ $c2 == D ]]; then
          letters+="D"
          ((mask |= 4))
        fi

        # untracked
        if (((mask & 8) == 0)) && [[ $line == '??'* ]]; then
          letters+="?"
          ((mask |= 8))
        fi

        ((mask == 15)) && break # all letters found
      done

      # append to PS1
      PS1+=" \[${Cyan}\](${branch}"
      [[ -n $letters ]] && PS1+=" ${letters}"
      PS1+=")\[${Color_Off}\]"
    fi
  fi

  # exit code
  if [[ ${EXIT} != 0 ]]; then
    PS1+=" \[${BRed}\][!${EXIT}]\[${Color_Off}\]"
  fi

  # prompt
  # PS1+=" \[${BPurple}\]\\$\[${Color_Off}\] " # prompt
  if [[ ${USER} == root ]]; then
    PS1+=" \[${BRed}\]\\$\[${Color_Off}\] " # root
  elif [[ ${USER} != "$LNAME" ]]; then
    PS1+=" \[${BBlue}\]\\$\[${Color_Off}\] " # normal user but not login
  else
    PS1+=" \[${BGreen}\]\\$\[${Color_Off}\] " # normal user
  fi

  __makeTerminalTitle
}

Color_Off='\e[0m' # Text Reset
Black='\e[0;30m'  # Black
Red='\e[0;31m'    # Red
Green='\e[0;32m'  # Green
Yellow='\e[0;33m' # Yellow
Blue='\e[0;34m'   # Blue
Purple='\e[0;35m' # Purple
Cyan='\e[0;36m'   # Cyan
White='\e[0;37m'  # White

# Bold
BBlack='\e[1;30m'  # Black
BRed='\e[1;31m'    # Red
BGreen='\e[1;32m'  # Green
BYellow='\e[1;33m' # Yellow
BBlue='\e[1;34m'   # Blue
BPurple='\e[1;35m' # Purple
BCyan='\e[1;36m'   # Cyan
BWhite='\e[1;37m'  # White

# Underline
UBlack='\e[4;30m'  # Black
URed='\e[4;31m'    # Red
UGreen='\e[4;32m'  # Green
UYellow='\e[4;33m' # Yellow
UBlue='\e[4;34m'   # Blue
UPurple='\e[4;35m' # Purple
UCyan='\e[4;36m'   # Cyan
UWhite='\e[4;37m'  # White

# Background
On_Black='\e[40m'  # Black
On_Red='\e[41m'    # Red
On_Green='\e[42m'  # Green
On_Yellow='\e[43m' # Yellow
On_Blue='\e[44m'   # Blue
On_Purple='\e[45m' # Purple
On_Cyan='\e[46m'   # Cyan
On_White='\e[47m'  # White

# High Intensity
IBlack='\e[0;90m'  # Black
IRed='\e[0;91m'    # Red
IGreen='\e[0;92m'  # Green
IYellow='\e[0;93m' # Yellow
IBlue='\e[0;94m'   # Blue
IPurple='\e[0;95m' # Purple
ICyan='\e[0;96m'   # Cyan
IWhite='\e[0;97m'  # White

# Bold High Intensity
BIBlack='\e[1;90m'  # Black
BIRed='\e[1;91m'    # Red
BIGreen='\e[1;92m'  # Green
BIYellow='\e[1;93m' # Yellow
BIBlue='\e[1;94m'   # Blue
BIPurple='\e[1;95m' # Purple
BICyan='\e[1;96m'   # Cyan
BIWhite='\e[1;97m'  # White

# High Intensity backgrounds
On_IBlack='\e[0;100m'  # Black
On_IRed='\e[0;101m'    # Red
On_IGreen='\e[0;102m'  # Green
On_IYellow='\e[0;103m' # Yellow
On_IBlue='\e[0;104m'   # Blue
On_IPurple='\e[0;105m' # Purple
On_ICyan='\e[0;106m'   # Cyan
On_IWhite='\e[0;107m'  # White

# Color man-pages
export LESS_TERMCAP_mb=$'\e[01;31m'      # begin blinking
export LESS_TERMCAP_md=$'\e[01;38;5;74m' # begin bold
export LESS_TERMCAP_me=$'\e[0m'          # end mode
export LESS_TERMCAP_se=$'\e[0m'          # end standout-mode
# export LESS_TERMCAP_so=$'\e[38;5;246m'    # begin standout-mode - info box
export LESS_TERMCAP_so=$'\e[30;43m'
export LESS_TERMCAP_ue=$'\e[0m'           # end underline
export LESS_TERMCAP_us=$'\e[04;38;5;146m' # begin underline

if [[ -x /usr/bin/tput ]] && tput setaf 1 >&/dev/null; then
  color_prompt=yes
else
  color_prompt=
fi

# enable/disable tmux loading
if [[ $EUID -eq 0 ]]; then
  EN_TMUX=0
elif command -v tmux >/dev/null 2>&1; then
  EN_TMUX=1
else
  EN_TMUX=0
fi
#EN_TMUX=0 # manual set tmux

# is git available
command -v git &>/dev/null && GIT_AVAILABLE=1 || GIT_AVAILABLE=0

# set base session and git when logged in via ssh
if [[ -n $SSH_CLIENT ]] || [[ -n $SSH_TTY ]]; then
  base_session='C-b'
  GIT=0
else
  base_session='C-a'
  GIT=1
fi

# enable/disable fuzzy search
# https://github.com/junegunn/fzf
# fuzzy search
# CTRL-T - Paste the selected files and directories onto the command-line
# CTRL-R - Paste the selected command from history onto the command-line
# ALT-C - cd into the selected directory
[[ -f ~/.fzf.bash ]] && source ~/.fzf.bash
command -v fzf &>/dev/null && EN_FUZZY=1 || EN_FUZZY=0
# FZF_TMUX=$EN_TMUX
# FZF_TMUX_HEIGHT="20%"

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace
export HISTTIMEFORMAT="| %d.%m.%y %T =>  "
shopt -s histappend # append to the history file, don't overwrite it
HISTSIZE=2000
HISTFILESIZE=4000
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

shopt -s checkwinsize # update the values of LINES and COLUMNS.

if [[ -z ${debian_chroot} ]] && [[ -r /etc/debian_chroot ]]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

HOST_COLOR=${BGreen}

if [[ $color_prompt = yes ]]; then
  if ! LNAME=$(logname 2>/dev/null); then
    LNAME=$USER
  fi
  PROMPT_COMMAND=__makePS1
  # PS2="\[${BPurple}\]>\[${Color_Off}\] " # continuation prompt
  if [[ ${USER} == root ]]; then
    PS2=" \[${BRed}\]>\[${Color_Off}\] " # root
  elif [[ ${USER} != "$LNAME" ]]; then
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
fi

if [[ -f ~/.bash_aliases ]]; then
  source ~/.bash_aliases
fi

if [[ -f /etc/bash_completion ]]; then
  source /etc/bash_completion
fi

if [[ -f /snap/lxd/current/etc/bash_completion.d/snap.lxd.lxc ]]; then
  source /snap/lxd/current/etc/bash_completion.d/snap.lxd.lxc
fi

if [[ -f ~/.tmux/tmux_completion.sh ]]; then
  source ~/.tmux/tmux_completion.sh
fi

# enable ssh-agent
#if [ -z "$SSH_AUTH_SOCK" ] ; then
#    eval `ssh-agent -s`
#fi


# Is loaded via vim
IN_VIM=$(ps -p "$PPID" -o comm= | grep -qsE '[gn]?vim' && echo 1 || echo 0)
if [[ $IN_VIM -eq 1 ]]; then
  GIT=0
  EN_TMUX=0
fi

# enable tmux and start session
if [[ $EN_TMUX -eq 1 ]]; then
  if [[ -z $TMUX ]]; then
    # Create a new session if it doesn't exist
    tmux has-session -t "$base_session" || tmux new-session -d -s "$base_session"
    # Are there any clients connected already?
    client_cnt=$(tmux list-clients | wc -l)
    if [[ $client_cnt -ge 1 ]]; then
      session_name=$base_session"-"$client_cnt
      tmux new-session -d -t "$base_session" -s "$session_name"
      tmux -2 attach-session -t "$session_name" \; set-option destroy-unattached
    else
      if [[ -f ~/.session.tmux ]]; then
        tmux -2 attach-session -t "$base_session" \; source-file ~/.session.tmux
      else
        tmux -2 attach-session -t "$base_session"
      fi
    fi
  fi
fi

# tab completion like zsh
bind 'set show-all-if-ambiguous on'
bind 'TAB:menu-complete'
bind '"\e[Z": menu-complete-backward'
bind 'set colored-completion-prefix on'
bind 'set colored-stats on'
bind 'set completion-ignore-case on'
# search history with arrow keys
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# enable fuzzy search
if [[ $EN_FUZZY -eq 1 ]]; then
  complete -o nosort -o nospace -o filenames -o bashdefault -F _fuzzypath cd mkdir rmdir du pushd popd dirs tree
  complete -o nosort -o nospace -o filenames -o bashdefault -F _fuzzyfiles ls cat less more tail head cp mv rm vi vim nvim grep find diff tar gzip gunzip zip unzip scp rsync chmod chown ln touch nano stat file wc

fi

# https://github.com/dvorka/hstr
# if this is interactive shell, then bind hstr to Ctrl-r (for Vi mode check doc)
# [[ -x $(command -v hstr) ]] && { if [[ $- =~ .*i.* ]]; then bind '"\C-r": "\C-a hstr -- \C-j"'; fi }

# faster find
# https://github.com/sharkdp/fd
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Auto-activate latest Python virtual environment
if [[ -d ~/venv ]]; then
  # Find and activate the latest Python venv
  for venv_dir in $(find ~/venv -maxdepth 1 -type d -name '[0-9]*' -printf '%f\n' 2>/dev/null | sort -V -r); do
    if [[ -f ~/venv/$venv_dir/bin/activate ]]; then
      source ~/venv/"$venv_dir"/bin/activate
      break
    fi
  done
fi

export NVM_DIR="$HOME/.nvm"
[[ -s $NVM_DIR/nvm.sh ]] && source "$NVM_DIR/nvm.sh"                   # This loads nvm
[[ -s $NVM_DIR/bash_completion ]] && source "$NVM_DIR/bash_completion" # This loads nvm bash_completion

[[ -f $HOME/.cargo/env ]] && source "$HOME/.cargo/env"

if [ -d "$HOME/go/bin/" ]; then
  PATH="$HOME/go/bin/:$PATH"
fi

if [[ -d $HOME/bin ]]; then
  PATH="$HOME/bin:$PATH"
fi

# remove duplicate entries
PATH="$(awk -v RS=: '!a[$1]++{if(NR>1)printf ":";printf $1}' <<<"$PATH")"
export PATH
export EDITOR=vim
export PAGER=less

# trap every command
trap 'timer_start' DEBUG
umask 022
