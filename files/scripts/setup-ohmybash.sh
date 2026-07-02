#!/usr/bin/env bash
# =============================================================================
#  setup-ohmybash.sh
# -----------------------------------------------------------------------------
#  Ships the modern CLI shell stack into /etc/skel so every new user lands on:
#    * Oh My Bash (lazy-loaded, theme "font")
#    * Starship prompt (also wired into zsh and fish)
#    * Fastfetch on first interactive shell open (one-shot, not every shell)
#      — config detects KDE/Plasma/KWin automatically
#    * Modern CLI toolbelt aliases (eza, bat, fd, rg, fzf, zoxide, delta)
#    * tmux + zoxide + fzf integration
#
#  The actual clone of oh-my-bash and starship install happens on FIRST BOOT
#  (no network at build time). A user-side runner lives at
#  /usr/share/anubis-os/scripts/user-shell-setup.sh, fired by
#  anubis-setup-user.service. The same script is re-runnable via
#  `ujust setup-shell` so users can refresh or migrate without reinstalling.
#
#  Idempotent. Runs at BUILD TIME.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-ohmybash] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[setup-ohmybash] %s\n' "$*"; }

ANUBIS_LIB=/usr/share/anubis-os/scripts
mkdir -p "$ANUBIS_LIB" /etc/skel/.config

# =============================================================================
#  1. User-side runner — runs on first boot AND on `ujust setup-shell`
# =============================================================================
LOG "Shipping user-shell-setup.sh ..."
cat > "$ANUBIS_LIB/user-shell-setup.sh" <<'USERSCRIPT'
#!/usr/bin/env bash
# Anubis OS — user-side shell setup. Idempotent. Re-run any time via
#   ujust setup-shell
set -euo pipefail
trap 'echo "[user-shell-setup] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[user-shell-setup] %s\n' "$*"; }

mkdir -p "$HOME/.local/bin" "$HOME/.config"

# --- Oh My Bash -------------------------------------------------------------
OSH="$HOME/.oh-my-bash"
if [[ ! -d "$OSH" ]]; then
    LOG "Cloning Oh My Bash ..."
    git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git "$OSH"
else
    LOG "Oh My Bash already present — refreshing ..."
    git -C "$OSH" pull --quiet --rebase || true
fi

# --- Starship ---------------------------------------------------------------
if ! command -v starship &>/dev/null && [[ ! -x "$HOME/.local/bin/starship" ]]; then
    LOG "Installing Starship to ~/.local/bin ..."
    curl -fsSL https://starship.rs/install.sh | \
        sh -s -- --bin-dir "$HOME/.local/bin" --yes
else
    LOG "Starship already installed."
fi

# --- bashrc -----------------------------------------------------------------
if ! grep -q 'oh-my-bash' "$HOME/.bashrc" 2>/dev/null; then
    LOG "Seeding ~/.bashrc from /etc/skel ..."
    cp /etc/skel/.bashrc "$HOME/.bashrc"
fi

# --- zshrc (optional — only if zsh is the login shell) ----------------------
if ! grep -q 'starship init zsh' "$HOME/.zshrc" 2>/dev/null; then
    LOG "Seeding ~/.zshrc from /etc/skel ..."
    cp /etc/skel/.zshrc "$HOME/.zshrc" 2>/dev/null || true
fi

# --- starship config --------------------------------------------------------
if [[ ! -f "$HOME/.config/starship.toml" ]]; then
    LOG "Seeding ~/.config/starship.toml ..."
    cp /etc/skel/.config/starship.toml "$HOME/.config/starship.toml"
fi

# --- fastfetch config + one-shot marker -------------------------------------
mkdir -p "$HOME/.config/fastfetch"
if [[ ! -f "$HOME/.config/fastfetch/config.jsonc" ]]; then
    LOG "Seeding fastfetch config ..."
    cp /etc/skel/.config/fastfetch/config.jsonc "$HOME/.config/fastfetch/config.jsonc"
fi

LOG "Done. Open a new shell to see the result."
USERSCRIPT
chmod 0755 "$ANUBIS_LIB/user-shell-setup.sh"

# =============================================================================
#  2. /etc/skel/.bashrc — default for every new user
# =============================================================================
LOG "Writing /etc/skel/.bashrc ..."
cat > /etc/skel/.bashrc <<'BASHRC'
# =============================================================================
#  Anubis OS - ~/.bashrc
#  Beautiful, fast, no-emoji Powerline-style shell. Starship takes over the
#  prompt; this file sets up PATH, history, aliases, completions, and the
#  modern CLI toolbelt.
# =============================================================================

# --- PATH --------------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.krew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# --- Bash options ------------------------------------------------------------
# History: append immediately, no duplicates, no leading-space commands, verify
# expansions, share history across sessions, ignore trivial 1-char commands.
shopt -s histappend checkwinsize cdspell dirspell globstar no_empty_cmd_completion
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=50000
HISTFILESIZE=50000
HISTTIMEFORMAT='%F %T  '
PROMPT_COMMAND='history -a; history -n'

# --- Terminal title ----------------------------------------------------------
case "$TERM" in
    xterm*|rxvt*|alacritty*|kitty*|foot*|tmux*)
        PS1='\[\033]0;\u@\h:\w\007\]'
        ;;
esac

# --- Oh My Bash --------------------------------------------------------------
# Optional: provides completions + a few plugins. Starship overrides the
# prompt below, so the OSH_THEME is irrelevant; we just want the completions.
export OSH="$HOME/.oh-my-bash"
if [[ -f "$OSH/oh-my-bash.sh" ]]; then
    OSH_THEME=""
    DISABLE_AUTO_UPDATE="true"
    DISABLE_AUTO_CD="true"
    completions=(git)
    aliases=()
    plugins=(git basher progress)
    source "$OSH/oh-my-bash.sh"
fi

# --- Color palette (Anubis purple, no emojis) --------------------------------
# Used by custom prompt fallback if Starship is not installed.
if [[ -z "${ANUBIS_COLORS:-}" ]]; then
    export ANUBIS_COLORS=1
    # Standard ANSI colors, but tuned for the Anubis dark palette.
    export ANUBIS_FG0='\[\033[38;2;229;231;235m\]'     # near-white
    export ANUBIS_FG1='\[\033[38;2;167;139;250m\]'     # light purple
    export ANUBIS_FG2='\[\033[38;2;139;92;246m\]'      # purple
    export ANUBIS_FG3='\[\033[38;2;109;40;217\]'       # deep purple
    export ANUBIS_RED='\[\033[38;2;239;68;68m\]'
    export ANUBIS_GREEN='\[\033[38;2;34;197;94m\]'
    export ANUBIS_YELLOW='\[\033[38;2;245;158;11m\]'
    export ANUBIS_BLUE='\[\033[38;2;59;130;246m\]'
    export ANUBIS_CYAN='\[\033[38;2;34;211;238m\]'
    export ANUBIS_RESET='\[\033[0m\]'
    export ANUBIS_BOLD='\[\033[1m\]'
    export ANUBIS_DIM='\[\033[2m\]'
fi

# --- Prompt ------------------------------------------------------------------
# Starship is the primary prompt; if it's not installed, fall back to a
# custom Powerline-style bash prompt (still no emojis - just unicode blocks).
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
else
    # Fallback: a two-line prompt with Powerline-style separators.
    #   Line 1: <user>@<host> <cwd> (<git branch>)
    #   Line 2: ->
    __anubis_git_branch() {
        local b
        b=$(git symbolic-ref --short HEAD 2>/dev/null) || \
        b=$(git rev-parse --short HEAD 2>/dev/null) || return 0
        local dirty=""
        [[ -n $(git status --porcelain 2>/dev/null) ]] && dirty="*"
        printf ' (%s%s)' "$b" "$dirty"
    }
    PS1="${ANUBIS_FG2}${ANUBIS_BOLD}\\u${ANUBIS_RESET}"
    PS1+="${ANUBIS_FG0}@${ANUBIS_FG1}\\h${ANUBIS_RESET} "
    PS1+="${ANUBIS_FG3}\\w${ANUBIS_RESET}"
    PS1+="${ANUBIS_CYAN}\$(__anubis_git_branch)${ANUBIS_RESET}"
    PS1+="\n${ANUBIS_FG2}${ANUBIS_BOLD}>${ANUBIS_RESET} "
fi

# --- Modern CLI toolbelt aliases --------------------------------------------
if command -v eza &>/dev/null; then
    alias ls='eza --group-directories-first'
    alias ll='eza -lah --group-directories-first --git --git-status'
    alias la='eza -a --group-directories-first'
    alias lt='eza --tree --level=2'
    alias lr='eza -lah --reverse --sort=modified'
    alias lh='eza -lah --sort=size'
else
    alias ls='ls --color=auto'
    alias ll='ls -lah --color=auto'
    alias la='ls -a --color=auto'
    alias lt='find . -maxdepth 2 -type d | sort'
fi

if command -v bat &>/dev/null; then
    alias bat='bat --paging=never --style="header,grid,changes"'
    alias cat='bat --plain --paging=never'
    alias less='bat --paging=always'
    export MANPAGER="sh -c 'col -bx | bat -l man -p --paging=always'"
    export PAGER="bat --paging=always"
fi

if command -v rg &>/dev/null; then
    alias grep='rg --color=always'
    alias fgrep='rg -F --color=always'
fi
if command -v fd &>/dev/null; then
    alias find='fd'
fi
if command -v delta &>/dev/null; then
    alias diff='delta'
    export GIT_PAGER='delta'
fi
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash --cmd cd)"
    alias cd='z'
fi
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash)"
    # Ctrl+R: fuzzy history search; Ctrl+T: fuzzy file paste; Alt+C: fuzzy cd.
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi
if command -v direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi

# --- Convenience aliases (no emojis, just clean text) -----------------------
alias :q='exit'
alias :x='exit'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ports='ss -tulanp'
alias listening='ss -tunlp | grep LISTEN'
alias myip='curl -s ifconfig.me; echo'
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'
alias reload='source ~/.bashrc'
alias cls='clear'
alias h='history'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
alias timer='echo "Timer started at $(date +%T)"; time read; echo "Ended at $(date +%T)"'

# --- Git aliases -------------------------------------------------------------
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit -v'
alias gp='git push'
alias gpl='git pull --rebase'
alias gd='git diff'
alias gdc='git diff --cached'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --all --oneline --graph --decorate -20'
alias gb='git branch -vv'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gm='git merge --no-ff'
alias gr='git rebase'
alias grh='git reset --hard'
alias gcl='git clone'
alias gx='git clean -fdx'

# --- Systemd aliases ---------------------------------------------------------
alias sc='systemctl'
alias scu='systemctl --user'
alias jc='journalctl'
alias jcu='journalctl --user'
alias jce='journalctl -p err -b'
alias scu-restart='systemctl --user restart'

# --- Podman / Docker aliases (podman-docker is installed) -------------------
alias p='podman'
alias pc='podman-compose'
alias docker='podman'
alias dps='podman ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"'
alias di='podman images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"'

# --- Flatpak aliases ---------------------------------------------------------
alias fp='flatpak'
alias fpl='flatpak list --columns=application,name,version'
alias fpu='flatpak update -y'
alias fpr='flatpak uninstall --unused -y'

# --- rpm-ostree aliases ------------------------------------------------------
alias ro='rpm-ostree'
alias ros='rpm-ostree status'
alias rou='rpm-ostree upgrade'
alias rol='rpm-ostree upgrade --preview'

# --- ujust aliases -----------------------------------------------------------
alias uj='ujust'
alias ujh='ujust help'
alias uji='ujust info'
alias uju='ujust upgrade-system'

# --- Distrobox aliases -------------------------------------------------------
alias db='distrobox'
alias dbl='distrobox list'
alias dbe='distrobox enter'

# --- Disk / memory aliases ---------------------------------------------------
alias dfh='df -h --type=ext4 --type=btrfs --type=xfs --type=f2fs 2>/dev/null || df -h'
alias duh='du -h --max-depth=1 | sort -rh | head -20'
alias freeh='free -h'
alias mem='ps -eo pid,rss,comm --sort=-rss | head -15'

# --- Network aliases ---------------------------------------------------------
alias ping5='ping -c 5'
alias ports='ss -tulanp'
alias cons='ss -t state established'
alias gateway='ip route | grep default'

# --- File operations ---------------------------------------------------------
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -I --preserve-root'
alias ln='ln -i'
alias chmod='chmod -c --preserve-root'
alias chown='chown -c --preserve-root'
alias chattr='chattr -V'

# --- Archive operations ------------------------------------------------------
alias tarls='tar -tvf'
alias tarx='tar -xvf'
alias tarc='tar -czvf'

# --- Misc --------------------------------------------------------------------
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'
alias dmesg='dmesg --color=always'
alias watch='watch --color'

# --- Bash completion ---------------------------------------------------------
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        source /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        source /etc/bash_completion
    fi
fi

# --- Fastfetch on first interactive login (one-shot per shell session) ------
if [[ $- == *i* ]] && [[ -z "${ANUBIS_FF_SHOWN:-}" ]] && command -v fastfetch &>/dev/null; then
    export ANUBIS_FF_SHOWN=1
    fastfetch
fi

# --- Local customisations ----------------------------------------------------
[[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
BASHRC

# =============================================================================
#  3. /etc/skel/.zshrc — for users who `chsh -s /usr/bin/zsh`
# =============================================================================
LOG "Writing /etc/skel/.zshrc ..."
cat > /etc/skel/.zshrc <<'ZSHRC'
# =============================================================================
#  Anubis OS — ~/.zshrc
# =============================================================================
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.krew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_VERIFY
setopt EXTENDED_HISTORY INC_APPEND_HISTORY

bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

autoload -Uz compinit && compinit -d "$HOME/.cache/zsh/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

if command -v eza &>/dev/null; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -lah --group-directories-first --icons=auto --git'
fi
if command -v bat &>/dev/null; then alias cat='bat --plain'; fi
if command -v zoxide &>/dev/null; then eval "$(zoxide init zsh)"; fi
if command -v fzf    &>/dev/null; then eval "$(fzf --zsh)"; fi
if command -v direnv &>/dev/null; then eval "$(direnv hook zsh)"; fi

if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

if [[ -o interactive ]] && [[ -z "${ANUBIS_FF_SHOWN:-}" ]] && command -v fastfetch &>/dev/null; then
    export ANUBIS_FF_SHOWN=1
    fastfetch
fi
ZSHRC

# =============================================================================
#  4. /etc/skel/.config/fastfetch/config.jsonc
#     Uses the custom Anubis ASCII art logo (shipped by `files` module at
#     /usr/share/fastfetch/anubis-ascii.txt) + privacy-conscious module list.
# =============================================================================
LOG "Writing /etc/skel/.config/fastfetch/config.jsonc ..."
mkdir -p /etc/skel/.config/fastfetch
cat > /etc/skel/.config/fastfetch/config.jsonc <<'FFCONF'
// Anubis Linux fastfetch configuration
// Custom ASCII branding + a privacy-conscious module list.
//
// Privacy notes (intentional choices, do not "complete" this list by adding
// the commented-out modules back in):
//   - No "localip"   -> does not print LAN/VPN IP addresses.
//   - No "publicip"  -> does not make an outbound network request to an
//                       IP-lookup service just to render a fetch banner.
//   - No "weather"   -> same reason: avoids a silent outbound request and
//                       avoids leaking the user's approximate location.
//   - No "bluetooth"/"wifi" device modules -> avoid printing hardware MAC
//                       addresses, which are stable cross-session identifiers.
//   - "title" uses a generic label instead of "{user-name}@{host-name}" so
//                       screenshots/recordings shared online don't casually
//                       leak your real Linux username or machine hostname.
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",

  "logo": {
    "type": "file",
    "source": "/usr/share/fastfetch/anubis-ascii.txt",
    "width": 67,
    "height": 33,
    "padding": {
      "top": 1,
      "right": 4
    },
    "color": {
      "1": "yellow"
    }
  },

  "display": {
    "separator": " > ",
    "color": {
      "keys": "magenta",
      "title": "yellow"
    },
    "key": {
      "width": 14
    },
    "size": {
      "binaryPrefix": "si"
    }
  },

  "modules": [
    {
      "type": "custom",
      "format": "+------------------------------------+"
    },
    {
      "type": "title",
      "key": "   ",
      "format": "Anubis Linux session"
    },
    {
      "type": "custom",
      "format": "+------------------------------------+"
    },
    {
      "type": "os",
      "key": " OS"
    },
    {
      "type": "kernel",
      "key": " Kernel"
    },
    {
      "type": "uptime",
      "key": " Uptime"
    },
    {
      "type": "packages",
      "key": " Packages"
    },
    {
      "type": "de",
      "key": " Desktop"
    },
    {
      "type": "wm",
      "key": " WM"
    },
    {
      "type": "shell",
      "key": " Shell"
    },
    {
      "type": "terminal",
      "key": "  Terminal"
    },
    "break",
    {
      "type": "cpu",
      "key": "  CPU"
    },
    {
      "type": "gpu",
      "key": " GPU"
    },
    {
      "type": "memory",
      "key": " Memory"
    },
    {
      "type": "disk",
      "key": " Disk",
      "folders": "/"
    },
    "break",
    {
      "type": "colors",
      "symbol": "circle"
    }

    // Deliberately omitted for privacy - see header note:
    // "localip", "publicip", "weather", "bluetooth", "wifi"
  ]
}
FFCONF

# =============================================================================
#  5. /etc/skel/.config/starship.toml — purple Anubis palette
# =============================================================================
LOG "Writing /etc/skel/.config/starship.toml ..."
cat > /etc/skel/.config/starship.toml <<'STARSHIP'
# =============================================================================
#  Anubis OS - Starship prompt
#  Powerline-style, no emojis, no nerd-font glyphs. Uses only standard Unicode
#  block characters so it renders correctly in any terminal with any font.
# =============================================================================
"$schema" = 'https://starship.rs/config-schema.json'

format = """
[](color_orange)\
[ $os ](bg:color_orange fg:color_fg0)\
[](bg:color_yellow fg:color_orange)\
[ $directory ](bg:color_yellow fg:color_fg0)\
[](fg:color_yellow bg:color_aqua)\
[ $git_branch$git_status ](bg:color_aqua fg:color_fg0)\
[](fg:color_aqua)\
$fill\
$cmd_duration\
[ $time ](fg:color_purple)\
\n$character"""

palette = 'anubis'

[palettes.anubis]
color_fg0     = '#1a0a2e'
color_fg1     = '#e5e7eb'
color_orange  = '#8b5cf6'
color_yellow  = '#6d28d9'
color_aqua    = '#4c1d95'
color_purple  = '#a78bfa'
color_red     = '#ef4444'
color_green   = '#22c55e'
color_blue    = '#3b82f6'
color_cyan    = '#22d3ee'
color_yellow_bright = '#fbbf24'

[os]
disabled = false
style = "bg:color_orange fg:color_fg0"

[os.symbols]
Fedora = "fedora"
Macos = "macos"
Linux = "linux"
Windows = "windows"
Ubuntu = "ubuntu"
Arch = "arch"
Debian = "debian"

[directory]
style = "fg:color_fg0 bg:color_yellow"
truncation_length = 3
truncate_to_repo = true
read_only = " ro"
read_only_style = "fg:color_red bg:color_yellow"
home_symbol = "~"

[git_branch]
symbol = "git:"
style = "bg:color_aqua fg:color_fg0"
format = "[$symbol$branch]($style) "

[git_status]
style = "bg:color_aqua fg:color_fg0"
ahead = "up${count}"
behind = "down${count}"
diverged = "up${ahead_count}down${behind_count}"
conflicted = "conflict"
untracked = "?${count}"
stashed = "stash"
modified = "!${count}"
staged = "+${count}"
renamed = "renamed"
deleted = "del"
format = '([$all_status$ahead_behind]($style) )'

[cmd_duration]
min_time = 1_000
format = "[ took $duration ](fg:color_yellow_bright)"
show_milliseconds = false

[time]
disabled = false
format = '[$time ](fg:color_purple)'
time_format = "%H:%M"

[fill]
symbol = ' '

[character]
success_symbol = '[>](bold color_purple)'
error_symbol = '[>](bold color_red)'
vimcmd_symbol = '[<](bold color_green)'

[username]
show_always = false
style_user = "bg:color_orange fg:color_fg0"
format = '[$user]($style) '

[hostname]
ssh_only = true
style = "bg:color_orange fg:color_fg0"
format = '[$hostname]($style) '

[python]
symbol = "py:"
format = '[${symbol}${pyenv_prefix}(${version})(\($virtualenv\))]($style) '
style = "fg:color_blue"

[nodejs]
symbol = "node:"
format = '[$symbol($version)]($style) '
style = "fg:color_green"

[rust]
symbol = "rs:"
format = '[$symbol($version)]($style) '
style = "fg:color_red"

[golang]
symbol = "go:"
format = '[$symbol($version)]($style) '
style = "fg:color_cyan"

[lua]
symbol = "lua:"
format = '[$symbol($version)]($style) '
style = "fg:color_blue"

[java]
symbol = "java:"
format = '[$symbol($version)]($style) '
style = "fg:color_red"

[docker_context]
symbol = "docker:"
format = '[$symbol$context]($style) '
style = "fg:color_blue"

[package]
symbol = "pkg:"
format = '[$symbol$version]($style) '
style = "fg:color_yellow_bright"
disabled = true
STARSHIP

# =============================================================================
#  6. /etc/skel/.tmux.conf — minimal, mouse-on, true-color
# =============================================================================
LOG "Writing /etc/skel/.tmux.conf ..."
cat > /etc/skel/.tmux.conf <<'TMUX'
# Anubis OS — tmux defaults
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -g mouse on
set -g history-limit 50000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -sg escape-time 0
setw -g mode-keys vi
bind-key -T copy-mode-vi v send -X begin-selection
bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel "wl-copy"
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind r source-file ~/.tmux.conf \; display "Reloaded"
TMUX

LOG "Done."
