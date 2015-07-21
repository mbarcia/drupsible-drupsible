# history search with arrow up-down, fx type "cd" and press arrow up
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Previous/next word shortcut with Ctrl + Left Ctrl + Right
bind '"\eOC": forward-word'
bind '"\eOD": backward-word'

# better dir colours
LS_COLORS='di=0;32' ; export LS_COLORS

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=50000
HISTFILESIZE=500000
