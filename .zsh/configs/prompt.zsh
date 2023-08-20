function shortened_pwd() {
    local max_length=36
    local current_dir=$(pwd)
    local dir_length=${#current_dir}

    if (( dir_length <= max_length )); then
        echo "$current_dir"
    else
        local cut_length=$((dir_length - max_length + 3))
        local prefix_length=$(( (dir_length - cut_length) / 2 ))
        local suffix_length=$(( dir_length - prefix_length - cut_length ))

        local prefix=${current_dir[1,prefix_length]}
        local suffix=${current_dir[-suffix_length,-1]}

        echo "${prefix}...${suffix}"
    fi
}


PROMPT='%{$fg_bold[green]%}%n@%m %{$fg_bold[magenta]%}%* %{$fg_bold[blue]%}$(shortened_pwd) %{$reset_color%}$ '
