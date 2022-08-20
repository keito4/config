export ZSH="$HOME/.oh-my-zsh"

plugins=(
  git
)

source $ZSH/oh-my-zsh.sh


# load custom executable functions
for function in ~/.zsh/functions/*; do
  source $function
done

# extra files in ~/.zsh/configs/pre , ~/.zsh/configs , and ~/.zsh/configs/post
# these are loaded first, second, and third, respectively.
_load_settings() {
  _dir="$1"
  if [ -d "$_dir" ]; then
    if [ -d "$_dir/pre" ]; then
      for config in "$_dir"/pre/*(N-.); do
        . $config
      done
    fi

    for config in "$_dir"/**/*(N-.); do
      case "$config" in
        "$_dir"/(pre|post)/*|*.zwc)
          :
          ;;
        *)
          . $config
          ;;
      esac
    done
    if [ -d "$_dir/post" ]; then
      for config in "$_dir"/post/*; do
        . $config
      done
    fi
  fi
}

_load_settings "$HOME/.zsh/configs"

export PATH="$HOME/.poetry/bin:$PATH"