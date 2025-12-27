if status is-interactive
    set -g fish_greeting
    fastfetch
end
fish_add_path ~/.local/bin

set -gx SSH_AUTH_SOCK ~/.1password/agent.sock
set -gx EDITOR nvim

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/mmzim/.lmstudio/bin
# End of LM Studio CLI section

