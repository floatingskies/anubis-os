#!/usr/bin/env bash
set -euo pipefail

# Oh My Bash não pode ser clonado em tempo de build porque o ostree image build
# não tem acesso à rede (sem rede durante `rpm-ostree` / BlueBuild build).
#
# Starship não está disponível no repositório do Fedora. A instalação é feita
# no primeiro boot via o instalador oficial (curl | sh), que o usuário pode
# disparar manualmente, ou via `brew install starship` (Homebrew já incluso
# na imagem). O .bashrc verifica `command -v starship` antes de inicializar,
# então funciona com ou sem o prompt instalado.
#
# Estratégia: instalar um script de configuração de usuário que será executado
# no primeiro boot via anubis-setup-user.service (já habilitado por
# enable-first-boot-units.sh). O script clona OMB e aplica as configs na
# home do usuário real.

# Script de setup de usuário (executado no primeiro boot como o usuário real)
install -Dm755 /dev/stdin \
    /usr/share/anubis-os/scripts/setup-ohmybash-user.sh << 'USERSCRIPT'
#!/usr/bin/env bash
set -euo pipefail

OH_MY_BASH_DIR="$HOME/.oh-my-bash"

# Instalar Oh My Bash na home do usuário se ainda não existir
if [[ ! -d "$OH_MY_BASH_DIR" ]]; then
    git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git \
        "$OH_MY_BASH_DIR"
fi

# Instalar Starship via instalador oficial se ainda não estiver disponível.
# O binário vai para ~/.local/bin, que já está no PATH do .bashrc abaixo.
if ! command -v starship &>/dev/null && [[ ! -x "$HOME/.local/bin/starship" ]]; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- \
        --bin-dir "$HOME/.local/bin" --yes
fi

# Só sobrescreve o .bashrc se ainda não tiver sido customizado
if ! grep -q 'oh-my-bash' "$HOME/.bashrc" 2>/dev/null; then
    cp /etc/skel/.bashrc "$HOME/.bashrc"
fi
USERSCRIPT

# .bashrc padrão colocado no skel para novos usuários
cat > /etc/skel/.bashrc << 'BASHRC'
# Anubis OS — .bashrc padrão

# ~/.local/bin no PATH para Starship e outros binários instalados pelo usuário
export PATH="$HOME/.local/bin:$PATH"

export OSH="$HOME/.oh-my-bash"

# Oh My Bash — só carrega se já estiver instalado
if [[ -f "$OSH/oh-my-bash.sh" ]]; then
    OSH_THEME="font"
    DISABLE_AUTO_UPDATE="true"
    completions=(git)
    aliases=(general)
    plugins=(git)
    source "$OSH/oh-my-bash.sh"
fi

# Starship prompt — instalado via `curl | sh` no primeiro boot
# ou manualmente com `brew install starship`
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# Fastfetch ao abrir terminal interativo
if [[ $- == *i* ]] && command -v fastfetch &>/dev/null; then
    fastfetch
fi
BASHRC

# Fastfetch config padrão
mkdir -p /etc/skel/.config/fastfetch
cat > /etc/skel/.config/fastfetch/config.jsonc << 'FFCONF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "/usr/share/pixmaps/anubis-logo.png",
        "type": "kitty",
        "width": 24,
        "height": 12
    },
    "display": {
        "color": {
            "keys": "magenta",
            "title": "magenta"
        }
    },
    "modules": [
        "title",
        "separator",
        "os",
        "host",
        "kernel",
        "uptime",
        "shell",
        "display",
        "de",
        "wm",
        "terminal",
        "cpu",
        "gpu",
        "memory",
        "disk",
        "battery",
        "break",
        "colors"
    ]
}
FFCONF

# Starship config padrão (em /etc/skel para novos usuários)
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/starship.toml << 'STARSHIP'
"$schema" = 'https://starship.rs/config-schema.json'

format = """
[░▒▓](color_orange)\
[ 🐺 $os ](bg:color_orange fg:color_fg0)\
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
color_fg0 = '#1a0a2e'
color_orange = '#8b5cf6'
color_yellow = '#6d28d9'
color_aqua = '#4c1d95'
color_purple = '#a78bfa'

[os]
disabled = false
style = "bg:color_orange fg:color_fg0"

[directory]
style = "fg:color_fg0 bg:color_yellow"
truncation_length = 3

[git_branch]
symbol = " "
style = "bg:color_aqua fg:color_fg0"

[git_status]
style = "bg:color_aqua fg:color_fg0"

[time]
disabled = false
format = '[ $time ]'
time_format = "%H:%M"

[fill]
symbol = ' '

[character]
success_symbol = '[❯](bold color_purple)'
error_symbol = '[❯](bold red)'
STARSHIP
