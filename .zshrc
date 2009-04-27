# README! {{{
# Filename     : $HOME/.zshrc
# Purpose      : setup file for the shell 'zsh'
# Author       : Michael Prokop / www.michael-prokop.at / www.grml.org
# Availability : http://www.michael-prokop.at/computer/config/.zshzrc
#                http://www.michael-prokop.at/computer/config/.zsh/
# Latest change: Sam Aug 07 10:46:03 CEST 2004
##############################################################################
# Structure of this file:
#  Lines starting with '#' are comments.
#  Open this file with 'vim -c 'set foldmethod=marker' thisfile' or - if Vim
#  is already runnig - type ':foldmethod=marker' for a /better/ oversight ;)
#
# This file is...
#  based on zsh-file of Sven Guckes                        -->
#    http://www.guckes.net/setup/zshrc
#  and on the zsh-files of Stephen Rüger (caphuso on #zsh) -->
#    http://caphuso.dyndns.org/~caphuso/zsh-dotfiles.tar.gz
#  and on the zshrc of Christian Schneider                 -->
#    http://strcat.neessen.net/zsh.html
#  and on the zshrc of Marijan Peh                         -->
#    http://free-po.hinet.hr/MarijanPeh/files/zshrc
#  and on the zshrc of Sven Wischnowsky                    -->
#    http://www.w9y.de/zsh/zshrc
#  and on the zshrc of Adam Spiers                         -->
#    http://www.adamspiers.org/computing/zsh/files/
#  and have a look at the prompt of Phil Gregory           -->
#    http://aperiodic.net/phil/prompt/
#
# Take a quick (haha) look on zshbuiltins(1), zshcompwid(1),
# zshcompsys(1), zshcompctl(1), zshexpn(1), zshmisc(1), zshmodules(1),
# zshoptions(1), zshparam(1), zshzle(1) or - for hardliner -
# zshall(1).
#
# Need to debug zsh?
#  $ source $ZSHSOURCES/Util/reporter > /tmp/zsh-config
#  $ setopt
#
# Want a current '~/.zsh/zsh_help'?
#  $ man zshall | colcrt - | $DIR_TO_ZSH_SOURCE/zsh/zsh-4.2.0/Util/helpfiles
#
#  Functions/Misc/zmv
#  StartupFiles/zshrc
#  ,----[ Overview (Zsh 4.2.0) ]
#  |  zsh          Zsh overview (384 Lines)
#  |  zshbuiltins  Zsh built-in functions (1660 Lines)
#  |  zshcompctl   Zsh completion control (593 Lines)
#  |  zshcompsys   Zsh completion system (4091 Lines)
#  |  zshcompwid   Zsh completion widgets (1026 Lines)
#  |  zshcontrib   User contributions to zsh (1340 Lines)
#  |  zshexpn      Zsh command and parameter expansion (1590 Lines)
#  |  zshmisc      Anything not fitting into the other sections (1386 Lines)
#  |  zshmodules   Zsh loadable modules (2381 Lines)
#  |  zshoptions   Zsh options (1025 Lines)
#  |  zshparam     Zsh parameters (978 Lines)
#  |  zshtcpsys    Zsh tcp system (720 Lines)
#  |  zshzftpsys   Zftp function front-end (614 Lines)
#  |  zshzle       Zsh command line editing (1520 Lines)
#  |  zshall       Meta-man page containing all of the above (19267 Lines)
#  `----
#
# Some stats on the Zsh:
# $ cat (*/)#*.c | wc -l
# 98292
# $ cat (*/)#*.h | wc -l
# 3707
# $ pwd | sed 's/.*zsh/zsh/'
# zsh-4.2.0/Src
# $ cat (*/)#*.[ch] | wc -l
# 101999
#
# English:
# http://zsh.sunsite.dk/Doc/
# http://www.guckes.net/zsh/lover.html
#
# German:
# http://www.infodrom.north.de/~matthi/zsh/
# http://www.michael-prokop.at/computer/tools_zsh.html
#
# Zsh start up sequence (in this order):
#  1) /etc/zshenv   (login + interactive + other)
#  2)   ~/.zshenv   (login + interactive + other) [always, unless -f is specified]
#  3) /etc/zprofile (login)
#  4)   ~/.zprofile (login)
#  5) /etc/zshrc    (login + interactive) [interactive shells, unless -f is specified]
#  6)   ~/.zshrc    (login + interactive)
#  7) /etc/zlogin   (login)
#  8)   ~/.zlogin   (login)
# Upon termination:
#     .zlogout      (login)
#
# Tested and used under Debian, FreeBSD, SunOS and QNX with
# Zsh 4.0.7, 4.0.9, 4.1.1, 4.2.0 and 4.2.1-test-A
# }}}

# history of this file {{{
# 040807 added host-specific stuff
# 040725 set options nohashcmds and nohashdirs [more bash-like behaviour]
# 040703 added $CPU
# 040627 added color to root-prompt
# 040624 modified "MAIL"
# 040621 added prompt-handling
# 040619 fixed xkbd-handling for xterm
# 040617 tested setup on SunOS - no problems; new file: $ZSHDIR/zsh_sunos
# 040613 slightly improved README-section
# 040605 slightly improved root-stuff, renamed $ZDOTDIR to $ZSHDIR
# 040523 improved ZSH_VERSION-testing, changed ~/.zsh into variable
#        $ZSHDIR, some other *small* improvements
# 040515 added REPORTTIME, modified MAILCHECK and 'alias -s'
# 040509 tested setup on 'SunOS grex.cyberspace.org 4.1.4 16 sun4m unknown'
#        with zsh version 3.0.5. added check for is4() for 'histreduceblanks'
#        and removed error message for not existing $ZSHDIR/func-directory
# 040422 activating 'watch'-function
# 040418 small changes in $ZSHDIR/zsh_prompt_small; moving $ZSHDIR/zsh_alias
#        to $ZSHDIR/zsh_linux; giving 'headers' to all $ZSHDIR/*-files;
#        outsorced keybindings-stuff to $ZSHDIR/zsh_keybindings; do some
#        root-specific stuff; improve error-handling (check for non-existing
#        files and directories
# 040319 outsorcing "limits" to $ZSHDIR/zsh_limits and
#        source it on linux-systems
#        source $ZSHDIR/zsh_qnx on QNX-systems
# 040309 improving structure of this file with ideas taken from
#        http://strcat.neessen.net/zshrc
# 040229 creating folds in this file for vim (have a look at the three "{")
# 040229 initialising history in zsh-files
# }}}

# set some variables {{{
# 040523 set variable to be more debugging-friendly
  export ZSHDIR=$HOME/.zsh
# }}}

# autoload my personal functions {{{
# remove duplicate entries from path,cdpath,manpath & fpath
  typeset -U path cdpath manpath fpath
# cdpath=(.. ~)

# take the first element of the $fpath array (that's $ZSHDIR/func/ in my case),
# then strip off the path parts of the filename
# that means /foo/bar/baz would become just baz
# important: the functions have to be loaded *before* calling them
# zmodload -i zsh/complist && autoload -U compinit && compinit
  if (( EUID != 0 )); then
    if [[ -d $ZSHDIR/func/ ]]; then
      fpath=($ZSHDIR/func $fpath)
      autoload ${fpath[1]}/*(:t)
    fi
  fi
# }}}

# check zsh-version {{{
is4(){
    if [[ $ZSH_VERSION == 4.* ]]; then 
        return 0
    else
        return 1
    fi
}

if ! (( $+ZSH_VERSION_TYPE )); then
  if [[ $ZSH_VERSION == 3.0.<->* ]]; then ZSH_STABLE_VERSION=yes; fi
  if [[ $ZSH_VERSION == 3.1.<->* ]]; then ZSH_DEVEL_VERSION=yes;  fi

  ZSH_VERSION_TYPE=old
  if [[ $ZSH_VERSION == 3.1.<6->* ||
        $ZSH_VERSION == 3.<2->.<->*  ||
        $ZSH_VERSION == 4.<->* ]]
  then
    ZSH_VERSION_TYPE=new
  fi
fi

if is4; then
#    autoload -U checkmail            # needed for my prompt
    autoload -U colors && colors     # make ${f,b}g{,_{,no_}bold} available
    autoload -U compinit && compinit # load new completion system
    autoload -U edit-command-line    # later bound to C-z e or v in vi-cmd-mode
    autoload -U zed                  # what, your shell can't edit files? ["zed -f function"]
    autoload -U zmv                  # who needs mmv or rename? ["zmv '(*).lis' '\$1.txt"]
    autoload -Uz vcs_info
    zstyle ':vcs_info:*' disable bzr cdv darcs mtn svk tla
    bindkey -v                       # force keybindings no matter what $VISUAL and $EDITOR say
    zmodload -i zsh/complist         # e.g. menu-select widget, list-colors [color specifications]
    #zmodload -i zsh/stat
    # Autoload zsh modules when they are referenced
    zmodload -a zsh/stat stat
    zmodload -a zsh/zpty zpty
    zmodload -a zsh/zprof zprof
    zmodload -ap zsh/mapfile mapfile
else 
    bindkey() { }
    compdef() { }
    zle()     { }
    zstyle()  { }
fi

# 040523 test wheter zsh is version 4.1 or newer
# if [[ $ZSH_VERSION == 4.1.* ]]; then
if [[ $ZSH_VERSION > '4.1' ]]; then
    zmodload -i zsh/deltochar
    zmodload -i zsh/mathfunc
fi

# 040523 test wheter zsh is version 4.2 or newer
#if [[ $ZSH_VERSION == 4.2.* ]]; then
if [[ $ZSH_VERSION > '4.2' ]]; then
# Suffix aliases allow the shell to run a command on a file by suffix,
# e.g `alias -s ps=gv' makes `foo.ps' execute `gv foo.ps'.
    alias -s tex=$EDITOR        # '$ template.tex<CR>'
    alias -s txt="$PAGER -rE"   # '$ info.txt<CR>'
    alias -s html=$BROWSER      # '$ index.html<CR>'
    alias -s at=$BROWSER        # '$ www.michael-prokop.at<CR>'
    alias -s de=$BROWSER        # '$ www.heise.de<CR>'
# fix strange bug on one of my boxes:
  if [[ $PWD == '/' ]]; then 
     cd $HOME
  fi
fi
# }}}

# some terminal specific magic {{{
# look for the zkbd stuff in 'man zshcontrib'
if (( EUID != 0 )); then
  if [[ -f $ZSHDIR/zkbd/$TERM ]]; then
  case $TERM in
    linux)
        . $ZSHDIR/zkbd/$TERM
        ;;
    screen)
        . $ZSHDIR/zkbd/$TERM
        # 031123 fix <home>/<end>-bug
         bindkey '\e[1~' beginning-of-line       # Home
         bindkey '\e[4~' end-of-line             # End
         bindkey '\e[3~' delete-char             # Del
         bindkey '\e[2~' overwrite-mode          # Insert
        ;;
    gnome*)
        . $ZSHDIR/zkbd/$TERM
        ;;
    vt420*)
        . $ZSHDIR/zkbd/$TERM
        ;;
    rxvt)
        . $ZSHDIR/zkbd/$TERM
        ;;
    xterm*)
        . $ZSHDIR/zkbd/$TERM
        # 040619 fix <home>/<end>-bug
        bindkey "^[[F" end-of-line
        bindkey "^[[H" beginning-of-line
#         preexec () {
#           print -Pn "\e]0;$*\a"
#         }
        ;;      
  esac
  fi
fi
# }}}

# some os-dependant stuff {{{
  OS=${OSTYPE%%[0-9.]*}
  OSVERSION=${OSTYPE#$OS}
  OSMAJOR=${OSVERSION%%.*}
  export OS OSVERSION OSMAJOR
 
#if (( EUID != 0 )); then
  # load some external files
  case $OS in
    solaris)
      if [[ -d $ZSHDIR ]]; then
        source $ZSHDIR/zsh_solaris
        source $ZSHDIR/zsh_alias
        source $ZSHDIR/zsh_completition
        source $ZSHDIR/zsh_func
        source $ZSHDIR/zsh_keybindings
        source $ZSHDIR/zsh_limits
      fi
      ;;
    linux-gnu)
      if [[ -d $ZSHDIR ]]; then
        source $ZSHDIR/zsh_alias
        source $ZSHDIR/zsh_keybindings
        source $ZSHDIR/zsh_linux
        source $ZSHDIR/zsh_path
        source $ZSHDIR/zsh_func
        source $ZSHDIR/zsh_completition
        source $ZSHDIR/zsh_limits
      fi
      if [[ -f /etc/debian_version ]]; then
        source $ZSHDIR/zsh_debian # some debian-specials
      fi
      [[ -z $DISPLAY ]] && [[ -x `which setterm` ]] && setterm -bfreq 100 -blength 50 || resize > /dev/null 2>&1
    # some external commands
      [[ -x `which lesspipe 2> /dev/null`  ]] && eval $(lesspipe)  # set $LESS{OPEN,CLOSE}
      [[ -x `which lesspipe.sh 2> /dev/null`  ]] && eval $(lesspipe.sh)  # set $LESS{OPEN,CLOSE}
      [[ -x `which dircolors` ]] && eval $(dircolors) # set $LS_COLORS
    ;;
    freebsd)
      if [[ -d $ZSHDIR ]]; then
        source $ZSHDIR/zsh_alias
        source $ZSHDIR/zsh_keybindings
        source $ZSHDIR/zsh_bsd
        source $ZSHDIR/zsh_func
        source $ZSHDIR/zsh_completition
      fi
    ;;
    nto-qnx)
      if [[ -d $ZSHDIR ]]; then
        source $ZSHDIR/zsh_alias
        source $ZSHDIR/zsh_keybindings
        source $ZSHDIR/zsh_qnx
      fi
      ;;
    darwin)
      if [[ -d $ZSHDIR ]]; then
        source $ZSHDIR/zsh_alias
        source $ZSHDIR/zsh_keybindings
        source $ZSHDIR/zsh_path
        source $ZSHDIR/zsh_func
        source $ZSHDIR/zsh_completition
        source $ZSHDIR/zsh_limits
        source $ZSHDIR/zsh_darwin
      fi
    ;;
  esac
#fi
# }}}

# some host-specific stuff {{{
  case $HOST in
    tweety)
      if [[ -f $ZSHDIR/zsh_$HOST ]]; then
        source $ZSHDIR/zsh_$HOST
      fi
    ;;
    grml)
      if [[ -f $ZSHDIR/zsh_$HOST ]]; then
        source $ZSHDIR/zsh_$HOST
      fi
    ;;
  esac
# }}}

# set prompt {{{
# is4 &&  source $ZSHDIR/zsh_prompt || PROMPT='%n@%m %40<...<%B%~%b%<< $ '
  if (( EUID != 0 )); then
    if is4; then
       #setopt prompt_subst
       autoload -U promptinit && promptinit && prompt clint # load my prompt-theme
    else
      if [[ -f $ZSHDIR/zsh_prompt_small ]] && is4; then
        source $ZSHDIR/zsh_prompt_small
      else
        PROMPT='%n@%m %40<...<%B%~%b%<< $ '
      fi
    fi
  else
    local RED="%{[1;31m%}"
    local NO_COLOUR="%{[0m%}"
    PROMPT="$RED%n$NO_COLOUR@%m %40<...<%B%~%b%<< # "
  fi
# }}}

PROMPT_HOST=$(print -P "%m")

settitle() {
    case $TERM in
        xterm*)
        echo -ne "\033]0;$1\007"
        ;;
        screen*)
        echo -ne "\ek$1\e\\"
        ;;
    esac
}

precmd () {
# set the screen title to "zsh" when sitting at a command prompt:
  settitle "$PROMPT_HOST:zsh"
}

preexec() {
  local CMD=${1[(wr)^(*=*|sudo|ssh|-*)]}
  settitle "$PROMPT_HOST:$CMD"
}

# some root-stuff {{{
  if (( EUID == 0 )); then
# for root add sbin dirs to path
    path=($path /sbin /usr/sbin /usr/local/sbin)
# If user=root set unmask to 022 to prevent new files being
# created group and world writable
    umask 022
# locales

  # load some external files
   local ZSHDIR=~chrono/.zsh
   case $OS in
    solaris)
      if [[ -d $ZSHDIR ]]; then
        source $ZSHDIR/zsh_solaris
      fi
      ;;
    linux-gnu)
      if [[ -d $ZSHDIR ]]; then
        source $ZSHDIR/zsh_linux
      fi
    ;;
    freebsd)
      if [[ -d $ZSHDIR ]]; then
        source $ZSHDIR/zsh_bsd
      fi
    ;;
    nto-qnx)
      if [[ -d $ZSHDIR ]]; then
        source $ZSHDIR/zsh_qnx
      fi
      ;;
   esac
fi
# }}}

# some variables {{{
# 030909 format of process time reports with 'time'
# defaults: %E real  %U user  %S system  %P %J
#           %J  %U user %S system %P cpu %*E total
#  %%     A `%'.
#  %U     CPU seconds spent in user mode.
#  %S     CPU seconds spent in kernel mode.
#  %E     Elapsed time in seconds.
#  %P     The CPU percentage, computed as  (%U+%S)/%E.
#  %J     The name of this job.
# export TIMEFMT='%E real  %U user  %S system  %P cpu  %J'
# export TIMEFMT="Real: %E User: %U System: %S CPU-percent: %P Cmd: %J"
# export TIMEFMT='%J: %U [user] +%S [system], %P CPU -> %*E total'
  export TIMEFMT="%U user %S system %P cpu %*E total, running %J"
  export COLORTERM=yes
  export LINKS_XTERM=screen

# (( ${+*} )) = if variable is set don't set it anymore
(( ${+VISUAL} )) || export VISUAL="vim"

# define history-file and -options, the last 500 commands are saved
  HISTFILE="$HOME/.zsh_history"
  HISTSIZE=500
  SAVEHIST=500

# MailChecks
# unset MAILCHECK
  if [ -f $HOME/mail/inbox ]; then
    MAIL=$HOME/mail/inbox
  else
    MAIL=/var/mail/$USER
  fi
  MAILCHECK=30

# 040515 report about cpu-/system-/user-time of command if running
# longer than 5 secondes
  export REPORTTIME=5

## (( ${+*} )) = if variable is set don't set it anymore
# (( ${+USER} )) || export USER=$USERNAME
# (( ${+HOSTNAME} )) || export HOSTNAME=$HOST
# (( ${+EDITOR} )) || export EDITOR=`which vim`
# (( ${+VISUAL} )) || export VISUAL=`which vim`
# (( ${+FCEDIT} )) || export FCEDIT=`which vim`
# (( ${+PAGER} )) || export PAGER=`which less`
# (( ${+MAILCALL} )) || export MAILCALL='*** NEW MAIL ***' ## new mail warning
# (( ${+LESSCHARSET} )) || export LESSCHARSET='latin1' ## charset for pager
# (( ${+LESSOPEN} )) || export LESSOPEN='|lesspipe.sh %s'
# (( ${+MOZILLA_HOME} )) || export MOZILLA_HOME='/usr/lib/netscape' ## EDIT ##
# (( ${+MOZILLA_NO_ASYNC_DNS} )) || export MOZILLA_NO_ASYNC_DNS='True'
# (( ${+NNTPSERVER} )) || export NNTPSERVER=''  ## news server ## EDIT ##
# (( ${+CC} )) || export CC='gcc' ## or egcs or whatever
# }}}

# compiler opt. flags {{{
# use this with caution - or dont use them at all!
#
# see also:
# http://www.coyotegulch.com/acovea/
# http://ftp.ucr.ac.cr/solrhe/gen-optim.html
# http://klein.numerik.uni-kiel.de:8080/projects/cpuflags/cpuflags

# case "$uname" in
# AIX)
# *BSD|*bsd|Darwin)
# HP-UX)
# IRIX*) # IRIX, IRIX64
# Linux)
# OSF1|SunOS)

# run-time determination of $CPUTYPE
# notice: works since Zsh version 3.1
# from zsh-source: setsparam("CPUTYPE", machinebuf);
# check it on your own via `uname -m`
#case $CPUTYPE in
#   i686)
#      (( ${+CFLAGS} )) || export CFLAGS='-O9 -funroll-loops -ffast-math -malign-double -mcpu=pentiumpro -march=pentiumpro -fomit-frame-pointer -fno-exceptions'
#   ;;
#   i586)
#      (( ${+CFLAGS} )) || export CFLAGS='-O3 -march=pentium -mcpu=pentium -ffast-math -funroll-loops -fomit-frame-pointer -fforce-mem -fforce-addr -malign-double -fno-exceptions'
#   ;;
#   i486)
#      (( ${+CFLAGS} )) || export CFLAGS='-O3  -funroll-all-loops -malign-double -mcpu=i486 -march=i486 -fomit-frame-pointer -fno-exceptions'
#   ;;
#   *)
#      (( ${+CXXFLAGS} )) || export CXXFLAGS=$CFLAGS
#
## export CFLAGS="-O2 -fomit-frame-pointer -pipe" 
## export CFLAGS="-09 -march=pentium4"
## export CFLAGS="-march=pentium3 -mcpu=pentium3 -Os -fomit-frame-pointer -s -pipe -DNDEBUG -DG_DISABLE_ASSERT"
## export CXXFLAGS="-march=pentium3 -mcpu=pentium3 -Os -s -pipe -DNDEBUG -DG_DISABLE_ASSERT"
#esac

# 040703 try to set $CPU
  if [ -r /proc/cpuinfo ] ; then         # Linux
    CPU=`grep "model name" /proc/cpuinfo | cut -f2 -d":" | tr -d " "`
  elif [ -r /var/run/dmesg.boot ] ; then # FreeBSD
    CPU=`grep 'CPU:' /var/run/dmesg.boot | head -1`
  fi
# }}}

# some general options to set {{{
is4 &&  setopt NO_rm_star_wait
        setopt correct            #  try to correct the spelling of the first word
#        setopt NO_auto_menu
        setopt NO_menucomplete
        setopt autolist
        setopt NO_complete_in_word
        setopt complete_aliases
        setopt NO_mark_dirs
        #setopt NO_multios
        setopt multios            # multiple io redirection ('date > foo > bar')
        setopt notify
        setopt path_dirs
        setopt NO_singlelinezle
        setopt NO_hup
        setopt NO_beep
        setopt NO_nullglob
        setopt extended_glob      # grep word *~(*.gz|*.bz|*.bz2|*.zip|*.Z) -> 
                                  # -> searches for word not in compressed files
        setopt numeric_glob_sort
is4 &&  setopt NO_check_jobs 
is4 &&  setopt list_packed 
is4 &&  setopt NO_list_rows_first
is4 &&  setopt bare_glob_qual
        setopt NO_clobber         # warning if file exists ('cat /dev/null > ~/.zshrc')
        setopt histallowclobber
        setopt append_history
is4 &&  setopt histignorealldups
        setopt histignorespace
        setopt extended_history
is4 &&  setopt histreduceblanks   # not sure which versions support this option
        setopt hist_no_store
        setopt NO_hist_verify  
        setopt NO_auto_name_dirs
        setopt NO_hash_cmds       # bash-like behaviour FIXME TODO -> doesn't work as it should
        setopt NO_hash_dirs       # bash-like behaviour FIXME TODO
if [[ $VERSION == 4.1* ]]; then setopt auto_continue; fi
#        setopt NO_print_exit_value # don't print exit value if non-zero
        setopt glob_complete      # echo *<TAB> -> menu completion
        setopt rc_quotes          # print '''' -> '
        setopt ksh_option_print
        setopt rc_expand_param    # foo=(1 2);a${foo}b -> 'a1b a2b', not 'a1 b2'
        setopt no_flow_control
        setopt brace_ccl          # {a-c} -> 'a b c'
        setopt bsd_echo
        setopt always_last_prompt # necessary for menu selection
        unsetopt promptcr         # "normal" linefeed-behaviour 
        setopt completeinword     # Allow starting of X with 'X':
                                  # alias X="exec xinit"
        setopt nohup
        setopt csh_junkie_history
        setopt auto_cd            # simply type the directory name; zsh adds the 'cd' command
        # pushd-stuff
         setopt autopushd         # automatically append dirs to the push/pop list
        #setopt pushd_minus        # exchange meaning of + and -
        setopt pushd_silent       # don't tell me about automatic pushd
        setopt pushd_to_home      # use $HOME when no arguments specified
        setopt pushd_ignoredups   # ignore duplicates
        DIRSTACKSIZE=30           # depth of the directory history
        # now the important part
        alias -- +='pushd +1'
        alias -- -='pushd -0'
        alias  0="cd -"
        alias  1="cd +1"
        alias  2="cd +2"
        alias  3="cd +3"
        alias  4="cd +4"
        alias  5="cd +5"
        alias  6="cd +6"
        alias  7="cd +7"
        alias  7="cd +8"
        alias  9="cd +9"
        # pushd +1 will rotate the stack to left, pushd -0 - to right
        # With this you can simply type a directory name to cd into it. 
        # To move back to a previous directory use -, to move forward again use +.

#    setopt nobeep                  # i hate beeps
#    setopt noautomenu              # don't cycle completions
#    setopt autocd                  # change to dirs without cd
#    setopt pushdignoredups         # and don't duplicate them
#    setopt cdablevars              # avoid the need for an explicit $
#    setopt nocheckjobs             # don't warn me about bg processes when exiting
#    setopt nohup                   # and don't kill them, either
#    setopt listpacked              # compact completion lists
#    setopt nolisttypes             # show types in completion
#    setopt dvorak                  # with spelling correction, assume dvorak kb
#    setopt extendedglob            # weird & wacky pattern matching - yay zsh!
#    setopt completeinword          # not just at the end
#    setopt alwaystoend             # when complete from middle, move cursor
#    setopt correct                 # spelling correction
#    setopt nopromptcr              # don't add \r which overwrites output of cmds with no \n
#    setopt histverify              # when using ! cmds, confirm first
#    setopt interactivecomments     # escape commands so i can use them later
#    setopt recexact                # recognise exact, ambiguous matches
#    setopt printexitvalue          # alert me if something's failed
# }}}

# some zle stuff {{{
#  WORDCHARS=${WORDCHARS:s,/,,}     # important for e.g.  vi-backward-kill-word
#  WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
  autoload _history_complete_word
  autoload history-search-end
  autoload -U url-quote-magic
  zle -N self-insert url-quote-magic
  zle -N edit-command-line
  zle -N local-run-help
  zle -N run-as-root
  zle -N run-with-noglob
  zle -N run-as-command
  zle -N run-as-builtin
  zle -N run-without-completion
  zle -N show-history
  zle -N show-dirstack
  #zle -N silly-calc
  zle -N arith-eval-echo
  zle -N zsh-query-replace
  zle -N history-beginning-search-backward-end history-search-end
  zle -N history-beginning-search-forward-end history-search-end
  zle -C lamatch complete-word _generic
  zle -C lappr complete-word _generic
  zle -C lhist complete-word _generic
# }

## Watch for my friends
# An array (colon-separated list) of login/logout events to report.
# If it contains the single word `all', then all login/logout events
# are reported.  If it contains the single word `notme', then all
# events are reported as with `all' except $USERNAME.
# An entry in this list may consist of a username,
# an `@' followed by a remote hostname,
# and a `%' followed by a line (tty).
# watch=( $(<~/.friends) )           # watch for people in .friends file
  watch=notme                        # watch for everybody but me (tied to $USERNAME)
  LOGCHECK=60                        # check every ... seconds for login/logout activity

# The format of login/logout reports if the watch parameter is set.
# Default is `%n has %a %l from %m'.
# Recognizes the following escape sequences:
# %n = name of the user that logged in/out.
# %a = observed action, i.e. "logged on" or "logged off".
# %l = line (tty) the user is logged in on.
# %M = full hostname of the remote host.
# %m = hostname up to the first `.'.
# %t or %@ = time, in 12-hour, am/pm format.
# %w = date in `day-dd' format.
# %W = date in `mm/dd/yy' format.
# %D = date in `yy-mm-dd' format.
# WATCHFMT='%n %a %l from %m at %t.' # default
  WATCHFMT='%n %a %l from %m at %t.'

# colored completion output {{{
#  no = for normal text (i.e. when displaying something other than a matched file)
#  di = directory
#  fi = file
#  ln = symbolic link
#  pi = fifo file
#  so = socket file
#  bd = block (buffered) special file
#  cd = character (unbuffered) special file
#  or = symbolic link pointing to a non-existent file (orphan)
#  mi = non-existent file pointed to by a symbolic link (visible when you type ls -l)
#  ex = file which is executable (ie. has 'x' set in permissions).
#
# 0   = default colour
# 1   = bold
# 4   = underlined
# 5   = flashing text
# 7   = reverse field
# 31  = red
# 32  = green
# 33  = orange
# 34  = blue
# 35  = purple
# 36  = cyan
# 37  = grey
# 40  = black background
# 41  = red background
# 42  = green background
# 43  = orange background
# 44  = blue background
# 45  = purple background
# 46  = cyan background
# 47  = grey background
# 90  = dark grey
# 91  = light red
# 92  = light green
# 93  = yellow
# 94  = light blue
# 95  = light purple
# 96  = turquoise
# 100 = dark grey background
# 101 = light red background
# 102 = light green background
# 103 = yellow background
# 104 = light blue background
# 105 = light purple background
# 106 = turquoise background
#
#ZLS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.png=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:=(#b)(*_)(*)(_*.deb)=0=0=0;32:'

  LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;34;01:ex=01;32:*.tar=01;34:*.tgz=01;34:*.gz=01;34:*.bz2=01;34:*.jpg=01;35:*.sh=103;34:*.ogg=01;31:*.mp3=01;31:*.avi=01;34:*.mpg=01;34:*.mpeg=01;34:*.wmv=01;34:*.asf=01;34'
# }}}

# 'hash' some directories {{{
# 'hash' often visited directorys
#   Note: That's *not* variables or aliase!
#    ,----
#    | $ hash -d M=~/.mutt
#    | $ cd ~M
#    | ~M
#    | $ echo $M
#    |
#    | $ pwd
#    | /home/mika/.mutt
#    | $ hash -d doc=/usr/share/doc
#    | $ ls ~doc
#    | [...]
#    `----
  hash -d M=$HOME/.mutt
  hash -d V=$HOME/.vim
  hash -d Z=$HOME/.zsh
  hash -d W=/var/www
  hash -d P=$HOME/public_html
  hash -d doc=/usr/share/doc
  hash -d linux=/lib/modules/$(command uname -r)/build/
  hash -d log=/var/log
  hash -d rfc=/data/RFC
  hash -d deb=/var/cache/apt/archives

  if [ -d /usr/local/share/zsh/$ZSH_VERSION/functions ] ; then
    hash -d functions=/usr/local/share/zsh/$ZSH_VERSION/functions
  elif [ -d /usr/share/zsh/$ZSH_VERSION/functions ] ; then
    hash -d functions=/usr/share/zsh/$ZSH_VERSION/functions
  fi
# }}}

# source file:
  . $ZSHDIR/dpkg-info

################ END OF FILE ###################################################
# vim:foldmethod=marker
