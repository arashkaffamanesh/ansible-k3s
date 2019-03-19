source /etc/profile.d/colors.sh

__git_status () {

    mapfile -t status < <(git status --porcelain --branch 2>/dev/null)
    if [[ -z "${status}" ]]; then
        export GIT_PROMPT_STATUS=""
        return 1
    fi

    rx='##[^[]+\[ahead ([0-9]+)'
    [[ ${status[0]} =~ ${rx} ]] && local ahead=${BASH_REMATCH[1]}
    rx='##[^[]+\[behind ([0-9]+)'
    [[ ${status[0]} =~ ${rx} ]] && local behind=${BASH_REMATCH[1]}
    local out=""
    if [[ ${ahead} =~ [0-9] ]]; then
        out="⁞${green}↑${ahead}"
    fi
    if [[ ${behind} =~ [0-9] ]]; then
        out="${out}${yellow}↓${behind}"
    fi
    [[ ! -z "${out}" ]] && out="${out}${rst}${bold}⁞"
    export GIT_PROMPT_COMMITS="${out}"

    if [[ "${#status[@]}" == "1" ]]; then
        export GIT_PROMPT_STATUS=""
        return 0
    fi

    local staged=0; local modified=0; local untracked=0
    local line_num=1
    while [[ ${line_num} -lt ${#status[@]} ]]; do
        if [[ ${status[${line_num}]} =~ ^(M|A) ]]; then
            staged=$((staged+1))
        fi
        if [[ ${status[${line_num}]} =~ ^.(M|D) ]]; then
            modified=$((modified+1))
        fi
        if [[ ${status[${line_num}]} =~ ^\? ]]; then
            untracked=$((untracked+1))
        fi
        line_num=$((line_num+1))
    done
 
    local out="" 
    if [[ "${staged}" != "0" ]]; then
        out="${green}←${staged}"
    fi
    if [[ "${modified}" != "0" ]]; then
        out="${out}${yellow}←${modified}"
    fi
    if [[ "${untracked}" != "0" ]]; then
        out="${out}${red}←${untracked}"
    fi
    export GIT_PROMPT_STATUS="${out}"
    return 1
}

__git_branch () {
  if branch_info=$(git branch 2>/dev/null); then
    rx='\* ([a-zA-Z0-9-]+)|\(([^)]+)\)'
    if [[ ${branch_info} =~ ${rx} ]]; then
        if [[ -z "${BASH_REMATCH[1]}" ]]; then 
            echo ${BASH_REMATCH[2]}
        else
            echo ${BASH_REMATCH[1]}
        fi    
        return 0
    fi
  fi
  return 1
}

__git_tag () {
  git describe --tags 2>/dev/null
}

__git_prompt() {
    GIT_PROMPT=""
    if local branch="$(__git_branch)"; then
        local tag="$(__git_tag)"
        if [ "$branch" == " ((no branch))" ]; then
            branch="${tag}"
        fi
        if [[ ! -z "${branch}" ]]; then
            if [[ ${#branch} -gt 15 ]]; then
                branch="${branch:0:15}…"
            fi
            if __git_status; then 
              branch="${green}${branch}${rst}${bold}${GIT_PROMPT_COMMITS}"
            else
              branch="${blueish}${branch}${rst}${bold}${GIT_PROMPT_COMMITS}${GIT_PROMPT_STATUS}"
            fi 

            if [[ ! -z "${tag}" ]]; then 
                branch="${branch}${rst}${bold}@${rst}${brownish}${tag}"
            fi
            GIT_PROMPT="${rst}${bold}(${branch}${rst}${bold})${rst}"
        fi
    fi
    export GIT_PROMPT
    export PS1="${USER_PS1}${GIT_PROMPT}${rst}\$ "
}


if [[ ! ${PROMPT_COMMAND} =~ __git_prompt ]]; then
    export PROMPT_COMMAND="__git_prompt; ${PROMPT_COMMAND}"
fi

uid=$(/usr/bin/id -u)
if [[ "${uid}" == "0" ]]; then
    export USER_PS1="${red}\u${grey}@${yellow}\h:${rst}\w"
else
    export USER_PS1="${green}\u${grey}@${yellow}\h:${rst}\w"
fi
export PS1="${USER_PS1}${GIT_PROMPT}${rst}\$ "


