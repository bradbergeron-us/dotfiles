# aliases.zsh — command aliases.
# Git rebase helper functions (grn/grbic) live in functions.zsh.

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

alias gp='git pull'
alias gco='git checkout'
alias glog='git log --oneline --decorate --color --graph'

alias src='source ~/.zshrc'
alias dotstatus='bash ~/dotfiles/scripts/status.sh'  # dotfiles health: repo git state + last update
alias dotprofile='bash ~/dotfiles/scripts/profile.sh'  # show/set this machine's dotfiles profile
alias c='clear'
alias edithost='sudo nano /etc/hosts'

alias ..='../..'
alias ...='../../..'
alias ....='../../../..'
alias .....='../../../../..'
alias ls='lsd --group-dirs first'
alias la='lsd -A'
alias l='lsd -A --group-dirs first'
alias ll='lsd -lA --group-dirs first'
alias lc='lsd -lA --group-dirs first --sort date'
alias change="code ~/.zshrc"
alias update="source ~/.zshrc"
alias history='history 0'

# bat (syntax-highlighted cat)
command -v bat &>/dev/null && alias cat='bat --paging=never'

# VA.gov development shortcuts
alias vets-website-start='bash ~/dotfiles/scripts/vets-website/start-vets-website.sh'
alias vets-api-start='bash ~/dotfiles/scripts/vets-api/start-vets-api.sh'
