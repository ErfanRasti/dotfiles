##### source
# `source ~/.config/fish/config.fish` to apply changes here.
# The config is appended an the previous keybindings stays.
# Restart terminal for full fresh reload.

# stratup tmux
# if command -q tmux && set -q DISPLAY && ! set -q TMUX
#     exec tmux new-session -A -s $USER >/dev/null 2>&1
#     # exec tmux new
# end
#
# Enable Vim mode key bindings
fish_vi_key_bindings

# To activate sudope reliably:
# https://fishshell.com/docs/current/language.html#envvar-fish_escape_delay_ms
set -gx fish_escape_delay_ms 200

if status is-interactive
    # Commands to run in interactive sessions can go here
    # function fish_user_key_bindingssudope_sequence
    # Accept suggestion with Ctrl+Space
    bind -M insert ctrl-space accept-autosuggestion
    bind -M default ctrl-space accept-autosuggestion

    # Define a custom function that runs the cd command with fzf
    function fzf-cd-widget
        set -l selected_dir (ls -A | fzf --height 50% --layout=reverse)
        if test -n "$selected_dir"
            cd -- "$selected_dir"
        end
        # Clear the prompt and accept the line
        commandline -f repaint
        commandline -f execute
    end

    bind -M insert ctrl-f fzf-cd-widget
    bind -M default ctrl-f fzf-cd-widget

    # This great plugin hands a lot: https://github.com/PatrickF1/fzf.fish
    # Ctrl+Alt+F: Search Directory
    # Ctrl+Alt+L: Search Git Log
    # Ctrl+Alt+S: Search Git Status
    # Ctrl+H: Search History
    # Ctrl+V: Search Variables
    # fzf_configure_bindings --help for more info

    # Clipboard managing in vi mode
    bind -M visual y fish_clipboard_copy
    # bind -M default yy fish_clipboard_copy
    bind -M default yy 'commandline -f beginning-of-line end-of-line; fish_clipboard_copy; sleep 0.1;commandline -f repaint repaint'
    bind p fish_clipboard_paste

    # Or use Ctrl+E
    bind -M insert ctrl-e 'commandline -f accept-autosuggestion;commandline -f execute'

    # sudope binds
    # The default bind is ESC+ESC
    # remove sudope defaults here ~/.config/fish/conf.d/plugin-sudope.fish
    # bind -M insert alt-w sudope

    # Also alt+s is the built in sudo prefixifer.
    # https://fishshell.com/docs/current/faq.html#why-doesn-t-history-substitution-etc-work

end

# Set default editor
# export EDITOR=nvim

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f ~/anaconda3/bin/conda
    status is-interactive &&
        eval ~/anaconda3/bin/conda "shell.fish" hook $argv | source
else
    if test -f "~/anaconda3/etc/fish/conf.d/conda.fish"
        . "~/anaconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH ~/anaconda3/bin $PATH
    end
end
# <<< conda initialize <<<

# init zoxide
zoxide init fish | source

# Welcome page with ascii
# ascii-image-converter ~/Pictures/MyImages/(ls ~/Pictures/MyImages/ | grep -E '\.(jpg|png)$' | shuf -n 1) -C -c
# fastfetch
# gitfetch

# Supress fish welcoming message
set fish_greeting

# Setup yazi to change the CWD
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

# Set EDITOR
export EDITOR=nvim

# Import the envvars from ~/set_proxy
bass "source ~/set-proxy ''"

# Ascii art
figlet -t -c -f ANSI\ Shadow I use Arch btw. | lolcat
