if status is-interactive
    set -g fish_greeting
    fastfetch
end
fish_add_path ~/.local/bin

set -gx SSH_AUTH_SOCK ~/.1password/agent.sock
set -gx EDITOR nvim
