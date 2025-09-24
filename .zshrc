# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Flutter config
export PATH="$PATH:$HOME/fvm/default/bin"
export PATH="$PATH":"$HOME/fvm/versions/stable/bin/cache/dart-sdk/bin"
export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$PATH":"$HOME/Library/Android/sdk/platform-tools"
export PATH="$HOME/.local/bin:$PATH"

# Google Cloud SDK
export PATH="$HOME/google-cloud-sdk/bin/:$PATH"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

plugins=(
git
zsh-syntax-highlighting
zsh-autosuggestions
zsh-z
brew
virtualenv
fzf
zsh-vi-mode
)

source $ZSH/oh-my-zsh.sh

alias fgen="dart run build_runner build --delete-conflicting-outputs"
alias frun="flutter run"
alias flutter_localize="flutter pub run intl_translation:extract_to_arb --output-dir=lib/l10n ./lib/l10n/app_copy.dart"
alias flutter_easy_localization="flutter pub run easy_localization:generate --source-dir=assets/translations"
# Custom vim function to handle directories and files differently
vim() {
  # Check if the first argument is a directory
  if [[ -d "$1" ]]; then
    # If it's a directory, change into it and open nvim in that directory
    cd "$1"
    nvim .
  else
    # If it's not a directory (e.g., a file or no argument), open nvim with the argument
    nvim "$1"
  fi
}
alias oldvim="\vim"
alias fformat="flutter format ./lib"
alias fget="flutter pub get"
alias fclean="flutter clean && fget"
alias fup="flutter pub upgrade --major-versions"
alias fadd="flutter pub add $1"
alias lg="lazygit"

export PATH="/usr/local/opt/ruby/bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env" # ghcup-env

eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh-theme.json)"
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --no-user --group-directories-first --time-style long-iso'
alias la='eza -la --icons --no-user --group-directories-first --time-style long-iso'

## [Completion] 
## Completion scripts setup. Remove the following line to uninstall
[[ -f $HOME/.dart-cli-completion/zsh-config.zsh ]] && . $HOME/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

## Fast git push
gitpush() {
    git stash
    git pull
    git stash apply
    git add -A
    git commit -a -m "$*"
    git push
}
alias gp=gitpush

# a function that takes a file with extension and uses the `cwebp` command to convert it to webp.
# applies the flag -o to specify the output file name, which consists of the original file name with the extension replaced with .webp
function webp() {
  cwebp "$1" -o "${1%.*}.webp"
}

# uses the `webp` function to convert all files in the current directory to webp.
# accepts a flag --del to delete the original files after conversion.
function webpall() {
    for file in *; do
        if [[ $file == *".png" || $file == *".jpg" || $file == *".jpeg" ]]; then
        webp "$file"
        if [[ $1 == "--del" ]]; then
            rm "$file"
        fi
        fi
    done
}

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
source $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

function virtualenv_info { 
    [ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}
export VIRTUAL_ENV_DISABLE_PROMPT=1

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# nvm for multiple node versions
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh
export GEM_HOME="$HOME/.gem"

alias deletevenvs="rm -rf \`find . -type d -name '.venv'\`"
# enable thefuck
eval $(thefuck --alias)

# The next line updates PATH for the Google Cloud SDK.
if [ -f '$HOME/google-cloud-sdk/path.zsh.inc' ]; then . '$HOME/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '$HOME/google-cloud-sdk/completion.zsh.inc' ]; then . '$HOME/google-cloud-sdk/completion.zsh.inc'; fi
# Just alias
alias j=just

# asdf: setup
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
# asdf: append completions to fpath
fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)
# asdf: initialise completions with ZSH's compinit
autoload -Uz compinit && compinit

# Task Master aliases added on 9/8/2025
alias tm='task-master'
alias taskmaster='task-master'

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
