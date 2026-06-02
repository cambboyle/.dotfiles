#!/bin/bash
PROJECT_PATH=$1
PROJECT_NAME=$(basename "$PROJECT_PATH")

tmux has-session -t "$PROJECT_NAME" 2>/dev/null && tmux switch-client -t "$PROJECT_NAME" && exit 0

# Create session with shell window
tmux new-session -d -s "$PROJECT_NAME" -n shell -c "$PROJECT_PATH"

# Split 70/30
tmux split-window -t "$PROJECT_NAME:shell" -h -p 30 -c "$PROJECT_PATH"

# Split right column: 60% claude, 40% cmatrix
tmux split-window -t "$PROJECT_NAME:shell.2" -v -p 40 -c "$PROJECT_PATH"
tmux send-keys -t "$PROJECT_NAME:shell.2" 'claude' Enter
tmux send-keys -t "$PROJECT_NAME:shell.3" 'cmatrix -C white' Enter

# Focus left shell pane
tmux select-pane -t "$PROJECT_NAME:shell.1"

# Lazygit window
tmux new-window -t "$PROJECT_NAME" -n lazygit -c "$PROJECT_PATH"
tmux send-keys -t "$PROJECT_NAME:lazygit" 'lazygit' Enter

# Switch to shell window
tmux select-window -t "$PROJECT_NAME:shell"
tmux switch-client -t "$PROJECT_NAME"
