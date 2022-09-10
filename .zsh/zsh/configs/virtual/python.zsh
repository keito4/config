echo "okay"
export PYENV_ROOT="${HOME}/.pyenv"

if [ -d "${PYENV_ROOT}" ]; then
    export PATH=${PYENV_ROOT}/bin:$PATH
    eval "$(pyenv init --path)"
    # eval "$(pyenv virtualenv-init -)"
fi

# export PIP_RESPECT_VIRTUALENV=true
# WORKON_HOME=$HOME/.virtualenvs
# source /Users/keito/.pyenv/versions/3.5.2/bin/virtualenvwrapper.sh

# PATH="$HOME/.poetry/bin:$PATH"
# source $HOME/.poetry/env

# export CLOUDSDK_PYTHON=~/.pyenv/shims/python
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

