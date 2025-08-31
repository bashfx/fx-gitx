#!/usr/bin/env bash
#===============================================================================
#              _ _
#   __  ____ _(_) |_
#   \ \/ / _` | | __|
#    >  < (_| | | |_
#   /_/\_\__, |_|\__|
#        |___/
# 
#-------------------------------------------------------------------------------
#$ name:xgit|gitx
#$ author:qodeninja
#$ autobuild: 00002
#$ date:

#-------------------------------------------------------------------------------
#=====================================code!=====================================
#-------------------------------------------------------------------------------


  # defaults and options
  opt_debug=1
  opt_default=1
  opt_yes=1
  opt_quiet=0
  opt_trace=1

  FX_GITX_HOME="$MY_FX/gitx"
  FX_GITX_CONFIG="$FX_GITX_HOME/config"
  FX_GITX_RC="$FX_GITX_HOME/gitx.rc"

  GITX_USER=
  GITX_REPO=
  GITX_BRANCH=
  GITX_TAG=
  GITX_VERS=
  GITX_EMAIL=
  GITX_HOST=

#-------------------------------------------------------------------------------
# Term
#-------------------------------------------------------------------------------

  red=$(tput setaf 1)
  green=$(tput setaf 2)
  blue=$(tput setaf 39)
  blue2=$(tput setaf 27)
  cyan=$(tput setaf 14)
  orange=$(tput setaf 214)
  yellow=$(tput setaf 226)
  purple=$(tput setaf 213)
  white=$(tput setaf 248)
  white2=$(tput setaf 15)
  grey=$(tput setaf 244)
  grey2=$(tput setaf 245)
  revc=$(tput rev)
  x=$(tput sgr0)
  eol="$(tput el)"
  bld="$(tput bold)"
  line="##---------------$nl"
  tab=$'\\t'
  nl=$'\\n'

  delta="\xE2\x96\xB3"
  pass="\xE2\x9C\x93"
  fail="${red}\xE2\x9C\x97"
  star="\xE2\x98\x85"
  lambda="\xCE\xBB"
  

#-------------------------------------------------------------------------------
# Printers
#-------------------------------------------------------------------------------
  stderr(){ printf "${@}${x}\n" 1>&2; }

  __logo(){
    if [ "${opt_quiet:-0}" -eq 0 ]; then
      local logo
      logo=$(sed -n '3,9 p' "$BASH_SOURCE")
      printf "\n$blue${logo//#/ }$x\n" 1>&2;
    fi
  }

  __printf(){
    local text color prefix
    text=${1:-}; color=${2:-white2}; prefix=${!3:-};
    [ -n "$text" ] && printf "${prefix}${!color}%b${x}" "${text}" 1>&2 || :
  }

  __confirm() {
    local ret=1 answer src
    opt_yes=${opt_yes:-1}
    __printf "${1}? > " "white2"
    [ $opt_yes -eq 0 ] && { __printf "${bld}${green}auto yes${x}\n"; return 0; }
    src=${BASH_SOURCE:+/dev/stdin} || src='/dev/tty'

    while read -r -n 1 -s answer < $src; do
      [[ $? -eq 1 ]] && exit 1
      [[ $answer = [YyNn10tf+\-q] ]] || continue
      case $answer in
        [Yyt1+]) __printf "${bld}${green}yes${x}"; val='yes'; ret=0 ;;
        [Nnf0\-]) __printf "${bld}${red}no${x}"; val='no'; ret=1 ;;
        [q]) __printf "${bld}${purple}quit${x}\n"; val='quit'; ret=1; exit 1;;
      esac
      break
    done
    echo "$val"
    __printf "\n"
    return $ret
  }

force=1
  warn(){ local text=${1:-} force=${2:-1}; [ "${opt_quiet:-0}" -eq 0 ] && __printf "$delta $text$x\n" "orange"; }
  okay(){ local text=${1:-} force=${2:-1}; [ "${opt_quiet:-0}" -eq 0 ] && __printf "$pass $text$x\n" "green"; }
  info(){ local text=${1:-} force=${2:-1}; [ "${opt_quiet:-0}" -eq 0 ] && __printf "$lambda $text\n" "blue"; }

  trace(){ local text=${1:-}; [ "${opt_trace:-1}" -eq 0 ] && __printf "$idots $text\n" "grey"; }
  error(){ local text=${1:-}; __printf " $text\n" "fail"; }
  fatal(){ trap - EXIT; __printf "\n$red$fail $1 $2 \n"; exit 1; }

#-------------------------------------------------------------------------------
# Sig / Flow
#-------------------------------------------------------------------------------
    
  command_exists(){ type "$1" &> /dev/null; }

  handle_interupt(){ E="$?"; printf "Interrupted!"; kill 0; exit $E; }
  handle_stop(){ kill -s SIGSTOP $$; }
  handle_input(){ [ -t 0 ] && stty -echo -icanon time 0 min 0; }
  cleanup(){ [ -t 0 ] && stty sane; }

  fin(){
    local E="$?"; cleanup
    if [ $opt_quiet -eq 1 ]; then
       [ $E -eq 0 ] && __printf "${green}${pass} ${1:-Done}." \
                    || __printf "$red$fail ${1:-${err:-Cancelled}}."
    fi
    return $E
  }

  trap handle_interupt INT
  trap handle_stop SIGTSTP
  trap handle_input CONT
  trap fin EXIT
  #trap 'echo "An unhandled error occurred!"; exit 1' ERR

  __options(){
    local this next opts=("${@}");

    for ((i=0; i<${#opts[@]}; i++)); do
      this=${opts[i]}
      next=${opts[i+1]}
      case "$this" in
        --yes|-y)
          opt_yes=0
          ;;
        --quiet|-q)
          opt_quiet=1
          ;;
        --tra*|-t)
          opt_trace=0
          ;;
        --debug|-v)
          opt_debug=0
          ;;
        --default|-m)
          opt_default=0
          ;;
        #-*) err="Invalid flag [$this].";;
      esac
    done
    [ -n "$err" ] && fatal "$err";
  }


#-------------------------------------------------------------------------------
# Old Dispatch
#-------------------------------------------------------------------------------


  old_dispatch(){


    if [[ $@ =~ "--remote" ]]; then

      if [ -z "$2" ]; then
        read -p "GitHub repository (e.g. username/repo): " repo
      else
        repo="$2"
      fi

      if [ -z "$3" ]; then
        read -p "Branch name (default: local-master): " branch
        branch=${branch:-local-main}
      else
        branch="$3"
      fi

      echo "Initializing local git repository for $user..."
      git init
      echo "Adding files to git..."
      git add .
      echo "Creating initial commit..."
      git commit -m "Initial local commit"
      echo "Adding remote origin: git@$user:$repo.git..."
      git remote add origin "git@$user:$repo.git"
      echo "Fetching from origin..."
      git fetch origin
      echo "Creating new branch $branch..."
      git checkout -b "$branch"
      echo "Pushing branch $branch to origin..."
      git push -u origin "$branch"
      echo "Done."

    fi

    # fix upstream prob > git push --set-upstream origin master
    if [[ $@ =~ "--global" ]]; then
      #git config --global user.name "xxx"
      #git config --global user.email "1111043235+xxx@users.noreply.github.com"
      git config --global core.editor nano
      git config --global color.ui auto
      #git config --global excludesfile ~/.gitignore
      #git config --global autocrlf input
    elif [[ $@ =~ "--local" ]]; then
      git config user.name xxx
      git config user.email 111+xxx@users.noreply.github.com
    fi

    if [[ $@ =~ "--test" ]]; then
      ssh -T git@$user

    fi

    if [[ $@ =~ "--author" ]]; then
     git commit --amend --author="$user <$email@users.noreply.github.com>"
    fi

  }


#-------------------------------------------------------------------------------
# API
#-------------------------------------------------------------------------------
  
  get_meta(){
    local query="$1" this="$2" ret=1 q ref alt

    case "$query" in
      user)    q='provide username';             ref=GITX_USER;   alt=$(git config --get user.name 2>/dev/null);;
      email)   q='provide email (sans @domain)'; ref=GITX_EMAIL;  alt=$(git config --get user.email 2>/dev/null | sed 's/@.*//' );;
      branch)  q='provide branch name';          ref=GITX_BRANCH; alt="main";;
      repo)    q='provide repo name';            ref=GITX_REPO;   alt="${GITX_REPO:-}";;
      tag)     q='provide tag id';               ref=GITX_TAG;    alt="${GITX_TAG:-}";;
      vers)    q='provide version';              ref=GITX_VERS;   alt="${GITX_VERS:-}";;
      host)    q='provide host (e.g. github.com or ssh Host)'; ref=GITX_HOST; alt="github.com";;
      *) fatal "invalid inquiry: $query";;
    esac

    alt="${this:-${alt:-${!ref}}}"

    if [ ${opt_yes:-1} -eq 0 ]; then
      if [ -n "$alt" ]; then
        this="$alt"; ret=0
      else
        fatal "Error: missing required argument: $query"
      fi
    else
      while [ -z "$this" ]; do
        read -r -p "-> $q (${alt:-none}) ? " this
        [ -z "$this" ] && this="$alt"
        [ -n "$this" ] && ret=0
      done
    fi

    if [ -n "$this" ]; then
      eval "$ref=\"$this\""
      trace "set $ref => ${!ref}"
      printf '%s\n' "$this"
    fi
    return $ret
  }


  do_x(){
   echo "doing x..."
  }

  do_clone(){
    local ret=1 host user repo
    host=$(get_meta "host" "$1") || return 1
    user=$(get_meta "user" "$2") || return 1
    repo=$(get_meta "repo" "$3") || return 1
    info "Cloning git@${host}:${user}/${repo}.git"
    git clone "git@${host}:${user}/${repo}.git"
    ret=$?
    return $ret
  }


  # this_host=$(get_meta "host" $1)
  # this_user=$(get_meta "user" $2)
  # this_repo=$(get_meta "repo" $3)



  do_vers(){
   echo "doing version..."
   ret=$(get_meta "vers" $1)
   [ $? -eq 0 ] && echo "user set to $ret"
  }

  do_user(){
   echo "doing user..."
   ret=$(get_meta "user" $1)
   [ $? -eq 0 ] && echo "user set to $ret"
  }

  do_config_global(){
    git config --global core.editor nano
    git config --global color.ui auto
  }

  do_config_local(){
    local u e
    u=$(get_meta "user" "$1") || return 1
    e=$(get_meta "email" "$2") || return 1
    info "Setting git config user.name=${u} user.email=${e}@users.noreply.github.com"
    git config user.name "${u}"
    git config user.email "${e}@users.noreply.github.com"
  }

  do_author(){
    info "Amend last commit author"
    local u e
    u=$(get_meta "user" "$1") || return 1
    e=$(get_meta "email" "$2") || return 1
    if __confirm "${blue}${lambda} Amend author to [$u <$e@users.noreply.github.com>] ?"; then
      git commit --amend --author="${u} <${e}@users.noreply.github.com>"
    fi
  }


  do_config(){
   git config --list | cat
  }

  do_tag(){
   echo "doing tag..."
  }


  #branch master, tag stable

  do_retag(){
    local branch tagname
    branch=${1:-main}
    tagname=${2:-dev}
    warn "Retag: ${branch} -> ${tagname} (force)"
    if __confirm "${orange}${delta} Create commit, force-retag '${tagname}', and push tags?"; then
      git add .
      git commit -m "chore(gitx): auto tag update"
      git push origin "$branch"
      git tag -f -a "$tagname" -m "auto update"
      git push --tags --force
    fi
  }



  do_shorts(){
   echo "doing shorts..."
  }

  do_init(){
   echo "doing local init..."

    if [ -z "$2" ]; then
      read -p "GitHub repository (e.g. username/repo): " repo
    else
      repo="$2"
    fi

    if [ -z "$3" ]; then
      read -p "Branch name (default: local-master): " branch
      branch=${branch:-local-main}
    else
      branch="$3"
    fi

    echo "Initializing local git repository for $user..."
    git init
    echo "Adding files to git..."
    git add .
    echo "Creating initial commit..."
    git commit -m "Initial local commit"
    echo "Adding remote origin: git@$user:$repo.git..."
    git remote add origin "git@$user:$repo.git"
    echo "Fetching from origin..."
    git fetch origin
    echo "Creating new branch $branch..."
    git checkout -b "$branch"
    echo "Pushing branch $branch to origin..."
    git push -u origin "$branch"
    echo "Done."


  }

  do_test(){
    info "[host] -> map to ssh user"
    this=$(get_meta "user" $1)
    info "[$this] selected"
    ssh -T git@${this}
  }

  do_sshls(){
    awk '/^Host / && !/^#/ {for (i=2; i<=NF; i++) print $i}' "$HOME/.ssh/config"
  }

  do_remote_init(){
   echo "doing remote init..."
  }

  do_branch_ls(){
    git branch -a | cat  
  }

  do_pretty_log(){
    git log --pretty=oneline
  }

	# do_gen_vers(){
	# 	src="$1"
	# 	dest="$src/build.inf"
	# 	echo "Generating build information from Git... ($src)"
	# 	bvers="$(cd $src;git describe --abbrev=0 --tags)"
	# 	binc="$(cd $src;git rev-list HEAD --count)"
	# 	branch="$(cd $src;git rev-parse --abbrev-ref HEAD)"
	# 	printf "DEV_VERS=%s\\n" "$bvers" > $dest
	# 	printf "DEV_BUILD=%s\\n" "$binc" >> $dest
	# 	printf "DEV_BRANCH=%s\\n" "$branch" >> $dest
	# 	printf "DEV_DATE=%s\\n" "$(date +%y)" >> $dest
  #   cat $dest
  #   #git describe --tags --long --dirty --always
	# }


  do_inspect(){
    declare -F | grep 'do_' | awk '{print $3}'
    _content=$(sed -n -E "s/[[:space:]]+([^)]+)\)[[:space:]]+cmd[[:space:]]*=[\'\"]([^\'\"]+)[\'\"].*/\1 \2/p" "$0")
    echo ""
    while IFS= read -r line; do
      info "$line"
    done <<< "$_content"
 }



#-------------------------------------------------------------------------------
# New Dispatch
#-------------------------------------------------------------------------------


  wrap_dispatch(){
    local ret=1
    if [ $opt_default -eq 1 ]; then
      info "Running gitx in new mode $opt_debug"
      dispatch "${args[@]}";ret=$?
    else
      if __confirm "${orange}${delta} OOPS! Running in (default) mode! Continue"; then
        old_dispatch "${orig_args[@]}";ret=$?;
      fi
    fi
  }


  debug_run(){
   echo "running..."

  }

  dispatch(){
    local call="$1" arg="$2" cmd= ret;
    shift; shift; 
    case $call in
      run)    cmd='debug_run';;
      init)   cmd='do_init';;
      local)  cmd='do_config_local';;
      config) cmd='do_config';;
      author) cmd='do_author';;
      retag)  cmd='do_retag';;
      sshls)  cmd='do_sshls';;
      clone)  cmd='do_clone';;
      branch) cmd='do_branch';;
      brls)   cmd='do_branch_ls';;
      plog)   cmd='do_pretty_log';;
      tag)    cmd='do_tag';;
      vers)   cmd='do_vers';;
      user)   cmd='do_user';;
      test)   cmd='do_test';;
      inspect) cmd='do_inspect';;
      help|\?) cmd="usage";;
      *)
        if [ ! -z "$call" ]; then
          err="Invalid command => $call";
        else
          err="Missing command!";
        fi
      ;;
    esac
    

    if [ -n "$cmd" ]; then
      trace "< $call | $cmd [$arg] [$*] >";
      "$cmd" "$arg" $@  # Pass all extra arguments if cmd is defined
      ret=$?
    fi

    [ -n "$err" ] && fatal "$err";
    return $ret;
  }


#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------


  usage(){
    if command_exists 'docx'; then
      docx "$BASH_SOURCE" "doc:help"; 
    else
      cat <<EOF 1>&2
gitx <cmd> [args]

Commands:
  clone <host> <user> <repo>   SSH clone repo (interactive if missing)
  retag <branch> <tag>         Commit, force tag, push tags
  author [user] [email]        Amend last commit author
  local                        Set repo git config (name/email)
  config                       Show git config (list)
  brls                         List branches
  plog                         Pretty one-line log
  sshls                        List SSH hosts from ~/.ssh/config
  inspect                      List do_* handlers and hints
  help                         Show this help

Flags:
  --yes/-y   Auto-confirm prompts
  --quiet/-q Minimal output
  --trace/-t Verbose traces
  --debug/-v Debug output
EOF
    fi
  }


  main(){
    __logo
    wrap_dispatch "${args[@]}";ret=$?
    [ -n "$err" ] && return 1;
  }

#-------------------------------------------------------------------------------


  if [ "$0" = "-bash" ]; then
    :
  else

    orig_args=("${@}")
    args=( "${orig_args[@]/\-*}" ); #delete anything that looks like an option
    __options "${orig_args[@]}";
    main "${args[@]}";ret=$?
    #[ -n "$err" ] && fatal "$err" || stderr "$out";

  fi


#-------------------------------------------------------------------------------
#=====================================!code=====================================
#====================================doc:help!==================================
#  \n\tgitx <cmd> [args]
#
#  Commands:
#    clone <host> <user> <repo>   SSH clone repo (interactive if missing)
#    retag <branch> <tag>         Commit, force tag, push tags
#    author [user] [email]        Amend last commit author
#    local                        Set repo git config (name/email)
#    config                       Show git config (list)
#    brls                         List branches
#    plog                         Pretty one-line log
#    sshls                        List SSH hosts from ~/.ssh/config
#    inspect                      List do_* handlers and hints
#    help                         Show this help
#
#  Flags:
#    --yes/-y   Auto-confirm prompts
#    --quiet/-q Minimal output
#    --trace/-t Verbose traces
#    --debug/-v Debug output
#=================================!doc:help=====================================
