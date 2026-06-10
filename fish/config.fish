# No greeting
    set fish_greeting

alias cmatrix='cmatrix -C cyan -B'

if status is-interactive
    fastfetch
    starship init fish | source
    fnm env --use-on-cd --shell fish | source
end
