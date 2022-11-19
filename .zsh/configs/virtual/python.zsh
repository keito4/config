export PYENV_ROOT="${HOME}/.pyenv"

if [ -d "${PYENV_ROOT}" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    # >>> conda initialize >>>
    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
            . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
        else
            export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
        fi
    fi
    unset __conda_setup
    # <<< conda initialize <<<
fi

# export PIP_RESPECT_VIRTUALENV=true
# WORKON_HOME=$HOME/.virtualenvs
# source /Users/keito/.pyenv/versions/3.5.2/bin/virtualenvwrapper.sh

FILE="$HOME/.poetry/env"

if [ -e $FILE ]; then
    PATH="$HOME/.poetry/bin:$PATH"
    source $HOME/.poetry/env
fi


export CLOUDSDK_PYTHON=~/.pyenv/shims/python
