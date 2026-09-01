# Themed by apply-starship-theme.py from the active family's palette --
# this file is generated, edits here get overwritten on the next theme
# switch. Change the source template at
# ~/.dotfiles/config/starship/starship.toml.tpl instead.
#
# Layout inspired by the Jetpack preset: directory pinned left, everything
# else pushed to the right edge via $fill, prompt input on its own line.
"$schema" = 'https://starship.rs/config-schema.json'

add_newline = true

format = """
$directory\
$fill\
$git_branch\
$git_status\
$aws\
$cmd_duration\
$hostname\
$line_break\
$character"""

[fill]
symbol = " "

[character]
success_symbol = "[❯](bold {{ bright_green }})"
error_symbol = "[❯](bold {{ bright_red }})"
vimcmd_symbol = "[❮](bold {{ bright_yellow }})"

[directory]
style = "bold {{ bright_cyan }}"
truncation_length = 0
truncate_to_repo = false
format = "[$path]($style)[$read_only]($read_only_style) "
read_only = " 󰌾"
read_only_style = "{{ bright_red }}"

[git_branch]
symbol = " "
style = "bold {{ bright_magenta }}"
format = "[$symbol$branch]($style) "

[git_status]
style = "{{ orange }}"
format = "([$all_status$ahead_behind]($style)) "
conflicted = ""
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕⇡${a}⇣${b}"
untracked = "?${count}"
stashed = "*${count}"
modified = "!${count}"
staged = "+${count}"
renamed = "»${count}"
deleted = "✘${count}"

[cmd_duration]
min_time = 2000
style = "{{ dark_foreground }}"
format = "took [$duration]($style) "

[hostname]
ssh_only = true
style = "bold {{ bright_blue }}"
format = "[$hostname]($style) "
trim_at = "."

[aws]
symbol = "  "
style = "bold {{ bright_yellow }}"
format = '[$symbol($profile )]($style)'
disabled = false
