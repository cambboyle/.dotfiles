#!/bin/bash
tmux has-session -t dev 2>/dev/null && exit 0

tmux new-session -d -s dev -n shell

# Split 65/35
tmux split-window -t dev:shell -h -p 35

# Split right column: 30% rain, 70% spotify
tmux split-window -t dev:shell.2 -v -p 70
tmux send-keys -t dev:shell.2 'rain' Enter
tmux send-keys -t dev:shell.3 'spotify_player' Enter

tmux select-pane -t dev:shell.1

tmux new-window -t dev -n lazydocker
tmux send-keys -t dev:lazydocker 'lazydocker' Enter

tmux new-window -t dev -n btop
tmux send-keys -t dev:btop 'btop' Enter

tmux new-window -t dev -n aws

# AFK window — split into cmatrix and genact
tmux new-window -t dev -n afk
tmux split-window -t dev:afk -h -p 50
tmux send-keys -t dev:afk.1 'cmatrix -C white' Enter
tmux send-keys -t dev:afk.2 'genact' Enter

tmux select-window -t dev:shell
