# ------------------
# Shell Variables
# ------------------

export EDITOR=code
export NVM_DIR="$HOME/.nvm"
export PG_CONFIG=/Applications/Postgres.app/Contents/Versions/latest/bin/pg_config

# ------------------
# PATH Manipulations
# ------------------

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

# chruby
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)"
source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
source /opt/homebrew/opt/chruby/share/chruby/auto.sh

export LDFLAGS="-L/opt/homebrew/opt/openssl@3.0/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3.0/include"
export CPPFLAGS="-I/usr/local/opt/libpq/include"

chruby ruby-3.3.6

# Lazy-load NVM — defers sourcing until first use of nvm/node/npm/npx
_nvm_load() {
  unset -f nvm node npm npx
  [ -s "$(brew --prefix nvm)/nvm.sh" ] && source "$(brew --prefix nvm)/nvm.sh"
}
nvm()  { _nvm_load; nvm  "$@"; }
node() { _nvm_load; node "$@"; }
npm()  { _nvm_load; npm  "$@"; }
npx()  { _nvm_load; npx  "$@"; }

export PATH="$PATH:/Library/Frameworks/Python.framework/Versions/3.7/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH="$PATH:/usr/local/opt/libpq/bin:/usr/local/opt/gnu-sed/libexec/gnubin:/opt/homebrew/opt/openssl@3.0/bin"
export PATH="$PATH:/Users/bradley.bergeron/Project-VA/install-binaries/apache-maven-3.6.3/bin"
export CALVARY_PROJ_ROOT=/Users/bradley.bergeron/Project-VA
export ODM_HOME=/Applications/IBM/ODM89
export LOCAL_RULE_APP_JAR=/Users/bradley.bergeron/Project-VA/ch33-lts-app/Product/Production/Services/jRules/Ch33RuleApp/target/Ch33RuleApp.jar
export PATH="$PATH:/Applications/Fortify/Fortify_SCA_and_Apps_20.1.1/bin"
export BUNDLE_ENTERPRISE__CONTRIBSYS__COM=REMOVED_FROM_HISTORY

# ------------------
# Zsh hooks
# ------------------

autoload -U add-zsh-hook

load-nvmrc() {
  # Walk up dirs to find .nvmrc without eagerly loading NVM
  local dir="$PWD" nvmrc_path=""
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/.nvmrc" ]] && { nvmrc_path="$dir/.nvmrc"; break; }
    dir="${dir:h}"
  done

  if [[ -n "$nvmrc_path" ]]; then
    _nvm_load
    local nvmrc_node_version node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")") 
    node_version=$(nvm version)
    if [[ "$nvmrc_node_version" == "N/A" ]]; then
      echo "Installing Node version from .nvmrc..."
      nvm install
    elif [[ "$nvmrc_node_version" != "$node_version" ]]; then
      echo "Switching to Node version $nvmrc_node_version..."
      nvm use
    fi
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

function tabTitle() {
  echo -ne "\033]0;${PWD##*/}\007"
}
add-zsh-hook precmd tabTitle

# ------------------
# Aliases
# ------------------

alias gcm="git commit -m"
alias gcam='git commit -a -m'
alias gca="git commit --amend --no-edit"
alias gcae="git commit --amend"
alias gcaa="git add --all && git commit --amend --no-edit"
alias gcaae="git add --all && git commit --amend"
alias gap="git add -p"
alias gnope="git checkout ."
alias gwait="git reset HEAD"
alias gundo="git reset --soft HEAD^"
alias greset="git clean -f && git reset --hard HEAD"
alias gl="git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias glb='git log --oneline --decorate --graph --all'
alias gst='git status -s'
alias gpl="git pull --rebase"
alias gps="git push"
alias gpsf="git push --force-with-lease"
alias grb="git rebase"
alias grbi='git rebase -i'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias gcmb="git branch --merged | grep -Ev '(^\\*|master)' | xargs git branch -d"
alias gset='git branch --set-upstream-to=origin/`git symbolic-ref --short HEAD`'
grn() { git rebase -i HEAD~"$1"; }
grbic() { git rebase -i "$1"; }

alias gp='git pull'
alias gco='git checkout'
alias gst='git status'
alias glog='git log --oneline --decorate --color --graph'

alias src='source ~/.zshrc'
alias c='clear'
alias pj='cd ~/Project-VA'
alias deploy='cd ~/Project-VA/ch33-deploy-artifacts'
alias basevm='cd ~/Project-VA/afs-base-vms'
alias stack='cd ~/Project-VA/ch33-lts-afs-stack'
alias ch33='cd ~/Project-VA/ch33-lts-app'
alias editbash='nano ~/.bash_profile'
alias edithost='sudo nano /etc/hosts'
alias mci='mvn clean install'
alias mvninstall='mvn clean install -Dmaven.test.skip=true'
alias mvnt='mvn clean test'

alias ..='../..'
alias ...='../../..'
alias ....='../../../..'
alias .....='../../../../..'
alias la='ls -Ah'
alias l='colorls --group-directories-first --almost-all'
alias ll='colorls --group-directories-first --almost-all --long'
alias lc='colorls -lA --sd'
alias ls='colorls -h --group-directories-first -1'
alias change="code ~/.zshrc"
alias update="source ~/.zshrc"
alias history='history 0'

alias setjdk8='export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_261.jdk/Contents/Home; java -version'
alias setjdk11='export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-11.0.12.jdk/Contents/Home; java -version'

eval "$(starship init zsh)"
test -f ~/afs_localprops.sh && source ~/afs_localprops.sh

# colorls completion (guarded)
if command -v colorls >/dev/null 2>&1; then
  colorls_gem_path=$(dirname $(gem which colorls 2>/dev/null) 2>/dev/null)
  if [[ -n "$colorls_gem_path" ]]; then
    if [[ -d "$colorls_gem_path/zsh" ]]; then
      fpath=("$colorls_gem_path/zsh" $fpath)
    fi
  fi
fi

# Optional plugins if installed
if [ -f "$HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]; then
  source "$HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
fi

if [ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Enable enhanced menu selection in completions
zmodload -i zsh/complist 2>/dev/null || true

autoload -Uz compinit
compinit

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Angular CLI autocompletion
if command -v node &>/dev/null && command -v ng &>/dev/null; then
  CURRENT_NODE_VERSION=$(node -v 2>/dev/null)
  if [[ -n "$CURRENT_NODE_VERSION" && "$CURRENT_NODE_VERSION" != "v0."* ]]; then
    source <(ng completion script)
  fi
fi

# rbenv and pyenv if installed
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi
# Java Version Management
export JAVA_8_HOME="/Library/Java/JavaVirtualMachines/amazon-corretto-8.jdk/Contents/Home"
export JAVA_17_HOME="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"

# Function to switch Java versions
function use-java() {
    if [[ "$1" == "8" ]]; then
        export JAVA_HOME=$JAVA_8_HOME
        echo "Switched to Java 8: $(java -version)"
    elif [[ "$1" == "17" ]]; then
        export JAVA_HOME=$JAVA_17_HOME
        echo "Switched to Java 17: $(java -version)"
    else
        echo "Usage: use-java [8|17]"
        echo "Current Java version: $(java -version | head -1)"
    fi
}

# Set Java 8 as default for this project
if [[ "$PWD" == *"dgi-java-vets-service"* ]]; then
    export JAVA_HOME=$JAVA_8_HOME
fi


. "$HOME/.local/bin/env"
