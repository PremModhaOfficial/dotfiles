# ~/.config/fish/config.fish

set -g fish_greeting

# Aliases
alias e nvim
alias bat batcat
alias t 'tmux a|tmux'

# Environment
set -gx JAVA_HOME /usr/lib/jvm/jdk-24.0.2-oracle-x64
set -gx EDITOR nvim

# PATH (fish_add_path is the documented way to manage PATH; order = priority, front wins)
fish_add_path --move \
    $HOME/.bun/bin \
    $HOME/.npm-global/bin \
    $HOME/.local/bin \
    $HOME/.local/share/JetBrains/Toolbox/scripts \
    $HOME/.config/emacs/bin \
    $HOME/.local/share/mise/shims \
    $HOME/.brv-cli/bin \
    $HOME/.opencode/bin \
    $HOME/.bin \
    $HOME/.local/scripts \
    $HOME/.cargo/bin \
    $HOME/go/bin \
    $JAVA_HOME/bin

# Initialization
zoxide init fish | source
# carapace completions (cache; regenerate with: carapace _carapace > ~/.cache/fish/carapace.fish)
if command -q carapace
    if test -f ~/.cache/fish/carapace.fish
        source ~/.cache/fish/carapace.fish
    else
        carapace _carapace | source
    end
end
atuin init fish --disable-up-arrow | source

# Other settings
set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
source "$HOME/.config/fish/tokens.fish"
# set -x WAYLAND_DISPLAY wayland-0 # Hardcoding this breaks session switching between GNOME and Niri

# Aliases (ls family)
alias fd=fdfind
alias cat=batcat
alias cd=z
alias ls='exa -l'
alias ll='exa -l'
alias la='exa -la'
alias jjs='jj status'
alias jjl="jj log -r 'all()'"
alias k=kubectl

# Functions
function oc
    set -l base_name (path basename (pwd) | string collect | string sub -l 20)
    set -l path_hash (pwd | md5sum | string sub -l 4)
    # Use a unique identifier to avoid session name collisions
    set -l session_name "$base_name-$path_hash"

    function __oc_find_port
        set -l port 4096
        while test $port -lt 5096
            if not lsof -i :$port >/dev/null 2>&1
                echo $port
                return 0
            end
            set port (math $port + 1)
        end
        echo 4096
    end

    set -l oc_port (__oc_find_port)
    set -gx OPENCODE_PORT $oc_port

    if set -q TMUX; and tmux info >/dev/null 2>&1
        # Inside tmux: always create a fresh window with a unique name
        set -l window_name "oc-$path_hash"
        set -l counter 1
        while tmux list-windows -t "$TMUX_PANE" -F "#W" | string match -q -- "^$window_name\$"
            set window_name "oc-$path_hash-$counter"
            set counter (math $counter + 1)
        end
        tmux new-window -n "$window_name" -c (pwd) "env OPENCODE_PORT=$oc_port /home/prem-modha/.opencode/bin/opencode --port $oc_port $argv; exec fish"
    else
        # Outside tmux: ensure a truly unique session name
        set -l final_session_name "$session_name"
        set -l counter 1
        while tmux has-session -t "$final_session_name" 2>/dev/null
            set final_session_name "$session_name-$counter"
            set counter (math $counter + 1)
        end

        set -l oc_cmd "env OPENCODE_DISABLE_TERMINAL_TITLE=1 CLAUDE_CODE_THEME=dark OPENCODE_PORT=$oc_port /home/prem-modha/.opencode/bin/opencode --port $oc_port $argv; exec fish"
        tmux new-session -s "$final_session_name" -c (pwd) "$oc_cmd"
    end
    functions -e __oc_find_port

    notify-send OC "opencode ready"
end

function ai
    opencode run "$argv" -m opencode/minimax-m2.5-free && notify-send done "$argv"
end

# Starship (transient prompt is enabled by default in fish 4)
function starship_transient_prompt_func
    starship module character
end

starship init fish | source

# mise
mise activate fish | source
mise completions fish | source

# Generated for envman. Do not edit.
# test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish  # ponytail: 12ms startup, uncomment if you use envman
