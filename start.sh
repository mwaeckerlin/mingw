#!/bin/bash -e

##########################################################################################
#### template for bash scripts #### START BELOW ##########################################
##########################################################################################

############################################################################ begin logging
# check if stdout is a terminal...
if test -t 1; then

    # see if it supports colors...
    ncolors=$(tput colors)

    if test -n "$ncolors" && test $ncolors -ge 8; then
        bold="$(tput bold)"
        underline="$(tput smul)"
        standout="$(tput smso)"
        normal="$(tput sgr0)"
        black="$(tput setaf 0)"
        red="$(tput setaf 1)"
        green="$(tput setaf 2)"
        yellow="$(tput setaf 3)"
        blue="$(tput setaf 4)"
        magenta="$(tput setaf 5)"
        cyan="$(tput setaf 6)"
        white="$(tput setaf 7)"
    fi
fi

append_msg() {
    if test $# -ne 0; then
        echo -n ": ${bold}$*"
    fi
    echo "${normal}"
}

# write a message
message() {
    if test $# -eq 0; then
        return
    fi
    echo "${bold}${white}$*${normal}" 1>&2
}

# write a success message
success() {
    echo -n "${bold}${green}success" 1>&2
    append_msg $* 1>&2
}

# write a notice
notice() {
    echo -n "${bold}${yellow}notice" 1>&2
    append_msg $* 1>&2
}

# write a warning message
warning() {
    echo -en "${bold}${red}warning" 1>&2
    append_msg $* 1>&2
}

# write error message
error() {
    echo -en "${bold}${red}error" 1>&2
    append_msg $* 1>&2
}

# run a command, print the result and abort in case of error
# option: --ignore: ignore the result, continue in case of error
run() {
    ignore=1
    while test $# -gt 0; do
        case "$1" in
            (--ignore) ignore=0;;
            (*) break;;
        esac
        shift;
    done
    echo -n "${bold}${yellow}running:${white} $*${normal} … "
    set +e
    result=$($* 2>&1)
    res=$?
    set -e
    if test $res -ne 0; then
        if test $ignore -eq 1; then
            error "failed with return code: $res"
            if test -n "$result"; then
                echo "$result"
            fi
            exit 1
        else
            warning "ignored return code: $res"
        fi
    else
        success
    fi
}

############################################################################ error handler
function traperror() {
    set +x
    local err=($1) # error status
    local line="$2" # LINENO
    local linecallfunc="$3"
    local command="$4"
    local funcstack="$5"
    IFS=" "
    for e in ${err[@]}; do
        if test -n "$e" -a "$e" != "0"; then
            error "line $line - command '$command' exited with status: $e (${err[@]})"
            if [ "${funcstack}" != "main" -o "$linecallfunc" != "0" ]; then
                echo -n "   ... error at ${funcstack} " 1>&2
                if [ "$linecallfunc" != "" ]; then
                    echo -n "called at line $linecallfunc" 1>&2
                fi
                echo
            fi
            exit $e
        fi
    done
    success
    exit 0
}

# catch errors
trap 'traperror "$? ${PIPESTATUS[@]}" $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[@]}" "${FUNCTION}"' ERR SIGINT INT TERM EXIT



##########################################################################################
#### START HERE ##########################################################################
##########################################################################################

######################################################### commandline parameter evaluation
while test $# -gt 0; do
    case "$1" in
        (--help|-h) less <<EOF
SYNOPSIS

  docker run --rm -it mwaeckerlin/mingw [OPTIONS] [build script]

OPTIONS

  --help, -h                 show this help
  --list, -l                 list all build scripts
  --readme, -r               show README file

DESCRIPTION

$(</README.md)

EOF
                    exit;;
        (--list|-l)
            ls -1 /build*.sh
            exit;;
        (--readme|-r)
            less /README.md
            exit;;
        (*) $*
            exit;;
    esac
    if test $# -eq 0; then
        error "missing parameter, try: docker run --rm -it mwaeckerlin/mingw --help"; exit 1
    fi
    shift;
done

##################################################################################### Main

