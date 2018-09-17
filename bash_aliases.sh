#!/usr/bin/env bash

export __LS_OPTIONS='--color=auto -h'

alias ls='ls $__LS_OPTIONS'
alias ll='ls $__LS_OPTIONS -l'
alias la='ls $__LS_OPTIONS -la'
alias l='ls $__LS_OPTIONS -CF'
# alias crontab='/usr/bin/crontab -u www-data'
alias sudo='sudo '   # use aliasses when using sudo

alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias s='cd ~/Notebooks/scripts/se_scripts'

alias bc='bc -l'
alias gh='history | grep '

alias mkdir='mkdir -p -v'
alias mv='mv -v'
#alias rm='rm -Iv --one-file-system --preserve-root'

alias less0='LESSOPEN= /usr/bin/less'

# function checks if the application is installed
function __add_command_replace_alias() {
    if [ -x "$(which $2 2>&1)" ]; then
        alias $1="$2"
    fi
}

__add_command_replace_alias less 'less -R'
__add_command_replace_alias tail 'multitail'
__add_command_replace_alias df 'pydf'
__add_command_replace_alias traceroute 'mtr'
__add_command_replace_alias tracepath 'mtr'
__add_command_replace_alias top 'htop'

# alias goaccess 'goaccess -o report.html --real-time-html'
alias unityrestart='DISPLAY=:0 unity --replace'
alias hosts="gksudo gedit /etc/hosts &"
alias hosts="sudo -E vi /etc/hosts"
# alias hosts="gedit admin:///etc/hosts &"
alias ap="ansible-playbook -s -k"
alias wget='wget -c'    #Resume wget by default


if [ -x "$(which highlight 2>&1)" ]; then
    export LESSOPEN='| highlight -O xterm256 --style=solarized-dark %s'
fi

if [ -x "$(which pygmentize 2>&1)" ]; then
    export LESSOPEN='| pygmentize -gf console %s'
fi




function allcolors() {
    # credit to http://askubuntu.com/a/279014
    for x in 0 1 4 5 7 8; do
        for i in $(seq 30 37); do
            for a in $(seq 40 47); do
                echo -ne "\e[$x;$i;$a""m\\\e[$x;$i;$a""m\e[0;37;40m "
            done
            echo
        done
    done
    echo ""
}

function genpwd() {
    X=${1:-16}
    apg -a 1 -n 5 -m "$X" -x "$X" -E \'\"\^\`
}


function weather() {
    curl http://wttr.in/"$1"
}

function cheat() {
    curl http://cheat.sh/"$1"
}

function qr() {
    curl http://qrenco.de/"$1"
}

function transfer() {
    if [ $# -eq 0  ]; then
        echo -e "No arguments specified. Usage:\ntransfer /tmp/test.md\ncat /tmp/test.md | transfer test.md\ntransfer <dir>"
        return 1
    fi
    tmpfile=$( mktemp -t transferXXX  )
    file=$1

    # upload stdin or file
    if tty -s; then
        basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g')

        if [ ! -e $file ]; then
            echo "File $file doesn't exists."
            return 1
        fi

        if [ -d $file ]; then
            # tar directory and transfer tar
            zipfile=$( mktemp -t transferXXX.tgz )
            cd $(dirname $file) && tar cfz $zipfile $(basename $file)
            curl --progress-bar --upload-file "$zipfile" "https://transfer.sh/$basefile.tgz" >> $tmpfile
            rm -f $zipfile
        else
            # transfer file
            curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile
        fi
    else
        # transfer pipe
        curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile
    fi

    cat $tmpfile
    echo
    rm -f $tmpfile
}



function transfer_encrypt() {
    if [ $# -eq 0  ]; then
        echo -e "No arguments specified. Usage:\ntransfer /tmp/test.md\ncat /tmp/test.md | transfer test.md\ntransfer <dir>"
        return 1
    fi
    tmpfile=$( mktemp -t transferXXX  )
    file=$1

    # upload stdin or file
    if tty -s; then
        basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g')

        if [ ! -e $file ]; then
            echo "File $file doesn't exists."
            return 1
        fi

        if [ -d $file ]; then
            # tar directory and transfer tar
            zipfile=$( mktemp -t transferXXX.tgz )
            cd $(dirname $file) && tar cfz $zipfile $(basename $file)
            cat "$zipfile" | gpg -ac -o- | curl -X PUT --progress-bar --upload-file "-" "https://transfer.sh/encrypted_$basefile.tgz" >> $tmpfile
            rm -f $zipfile
        else
            # transfer file
            cat "$file" | gpg -ac -o- | curl -X PUT --progress-bar --upload-file "-" "https://transfer.sh/encrypted_$basefile" >> $tmpfile
        fi
    else
        # transfer pipe
        cat "$file" | gpg -ac -o- | curl -X PUT --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile
    fi

    cat $tmpfile
    echo
    rm -f $tmpfile
}

function transfer_decrypt() {
    if [ $# -eq 0  ]; then
        echo -e "No arguments specified. Usage:\ntransfer_decrypt Downloads/test.md"
        return 1
    fi
    FILE="$1"
    gpg --yes --output "$(dirname $FILE)/decrypted_$(basename $FILE | sed 's/encrypted_//g')" --decrypt "$FILE"
}
