export ZSH="$HOME/.oh-my-zsh"
export PATH="$PATH:$HOME/fvm/default/bin"
export PATH="$PATH":"$HOME/fvm/versions/stable/bin/cache/dart-sdk/bin"
export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$PATH":"$HOME/Library/Android/sdk/platform-tools"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/google-cloud-sdk/bin/:$PATH"
# Flutter
export FVM_HOME="$HOME/fvm/versions/stable/bin"
export PATH="$FVM_HOME:$PATH"
export PATH="$HOME/flutter/bin:$PATH"

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
zoxide
)

source $ZSH/oh-my-zsh.sh

alias gen="dart run build_runner build -d"
alias genrm="dart run build_runner clean"
alias i18n="dart run slang"
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
alias ff="flutter format ./lib"
alias fget="flutter pub get"
alias fclean="flutter clean && fget"
alias bclean="dart run build_runner clean"
alias fup="flutter pub upgrade --major-versions"
alias fadd="flutter pub add $1"
alias lg="lazygit"

export PATH="/usr/local/opt/ruby/bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env" # ghcup-env

# eval "$(oh-my-posh init zsh)"
# eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/marcduiker.omp.json)"
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh-theme.json)"
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --no-user --group-directories-first --time-style long-iso'
alias la='eza -la --icons --no-user --group-directories-first --time-style long-iso'

# Taken from https://gist.github.com/lukepighetti/393845a6751c0b00c20d5cfbac1f8bd1
function flutter-watch(){
  tmux new-session \;\
  send-keys 'flutter run --pid-file=/tmp/tf1.pid' Enter \;\
  split-window -v \;\
  send-keys 'npx -y nodemon -e dart -x "cat /tmp/tf1.pid | xargs kill -s USR1"' Enter \;\
  resize-pane -y 5 -t 1 \;\
  select-pane -t 0 \;
}

function hx-find(){
  hx $(ag . | fzf | cut -d : -f 1,2)
}

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
# automatically installs cwebp via Homebrew if not already installed
function webp() {
  # Check if cwebp is installed, install if not
  if ! command -v cwebp &> /dev/null; then
    echo "cwebp not found. Installing via Homebrew..."
    brew install webp
  fi

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
source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

function virtualenv_info { 
    [ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Helix config for running Dart & Flutter
function flutter-watch(){
  local PID_FILE="/tmp/tf$$.pid"
  tmux new-session \;\
  send-keys "flutter run --pid-file=$PID_FILE" Enter \;\
  split-window -v \;\
  send-keys "npx -y nodemon -e dart -x \"cat $PID_FILE | xargs kill -s USR1\"" Enter \;\
  resize-pane -y 5 -t 1 \;\
  select-pane -t 0 \;
  rm $PID_FILE;
}

function hx-find(){
  hx $(ag . | fzf | cut -d : -f 1,2)
}

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
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
# Just alias
alias j=just

# Added by Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"
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

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# Source secrets (API keys etc.) - not tracked in git
[ -f "$HOME/.zshrc.secrets" ] && source "$HOME/.zshrc.secrets"
# trash - safe rm that moves files to Mac Trash
alias rm='trash'

# Set Ghostty tab title to current directory (shortened)
precmd() { print -Pn "\e]2;%~\a" }
