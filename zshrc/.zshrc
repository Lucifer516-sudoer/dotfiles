# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH # Back prop to BaShs

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell" # OMZ Theme, just a place holder

zstyle ':omz:update' mode reminder  # just remind me to update when it's time

zstyle ':omz:update' frequency 14
plugins=(
    git
    python
    zsh-navigation-tools
)

source $ZSH/oh-my-zsh.sh
source /home/lucifer/.zshenv

# load Starship
eval "$(starship init zsh)"
eval "$(ty generate-shell-completion zsh)"

fpath+=~/.zfunc; autoload -Uz compinit; compinit

# Turso
export PATH="$PATH:/home/lucifer/.turso"

alias mkdchd="mkdir  $(date +"%B-%d-%Y") && cd $(date +"%B-%d-%Y")"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# opencode
export PATH=/home/lucifer/.opencode/bin:$PATH
