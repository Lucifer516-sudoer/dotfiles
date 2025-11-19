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


# load Starship
eval "$(starship init zsh)"
