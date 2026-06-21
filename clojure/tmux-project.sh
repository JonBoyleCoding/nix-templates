#!/usr/bin/env bash

SESSION="$(basename "$PWD" | tr ' .:' '_')"

if tmux has-session -t "=$SESSION" 2>/dev/null; then
	tmux attach-session -t "$SESSION"
	exit 0
fi

tmux new-session -d -s "$SESSION"
tmux rename-window -t 0 "Code"
#tmux send-keys -t "$SESSION:Code" "fish" Enter
tmux send-keys -t "$SESSION:Code" "clear" Enter
tmux send-keys -t "$SESSION:Code" "nvim" Enter

tmux new-window -t "$SESSION:1" -n "Claude"
#tmux send-keys -t "$SESSION:Claude" "fish" Enter
tmux send-keys -t "$SESSION:Claude" "clear" Enter

tmux new-window -t "$SESSION:2" -n "Terminal"
#tmux send-keys -t "$SESSION:Terminal" "fish" Enter
tmux send-keys -t "$SESSION:Terminal" "clear" Enter

tmux new-window -t "$SESSION:8" -n "Git"
#tmux send-keys -t "$SESSION:Git" "fish" Enter
tmux send-keys -t "$SESSION:Git" "lg" Enter

tmux new-window -t "$SESSION:9" -n "REPL"
tmux send-keys -t "$SESSION:REPL" "clj -M:repl" Enter

tmux attach-session -t "$SESSION:0"
