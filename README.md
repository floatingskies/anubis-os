<div align="center">

<img src="https://github.com/user-attachments/assets/14a4ad1b-5c09-4f65-b186-6b246e2f88e3" width="140" alt="anubis-os logo" />

# anubis-os

**Uma imagem imutável baseada em Fedora Silverblue, feita por hobby pra rodar jogo, trabalhar e dormir tranquilo.**

[![build](https://github.com/floatingskies/anubis-os/actions/workflows/build.yml/badge.svg)](https://github.com/floatingskies/anubis-os/actions/workflows/build.yml)
[![Fedora 44](https://img.shields.io/badge/Fedora-44-51a2da?logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![Base: Silverblue](https://img.shields.io/badge/Base-Silverblue_Main-3584e4?logo=gnome&logoColor=white)](https://silverblue.fedoraproject.org/)
[![Stars](https://img.shields.io/github/stars/floatingskies/anubis-os?style=social)](https://github.com/floatingskies/anubis-os/stargazers)

</div>

---

## O que é isso?

O **anubis-os** começou como um projeto de fim de semana em cima do [Universal Blue](https://universal-blue.org/) — o mesmo projeto base do Bazzite e do Aurora — e foi crescendo até virar o sistema que uso todo dia. A ideia é ter uma imagem que joga bem, trabalha bem e não dá dor de cabeça com segurança básica, sem precisar de VM, partição extra ou ficar remendando o sistema toda semana.

A base é atômica e imutável: o que você instala via Flatpak ou Brew fica separado do OS, e as atualizações são transacionais — se algo quebrar, você volta com um comando e segue a vida.

Não é distro de empresa nem promete ser a próxima Bazzite. É um recipe.yml mantido por uma pessoa só que gosta de mexer nisso.

---

## Variantes

| Imagem | Para quem |
|--------|-----------|
| `anubis-os` | Hardware genérico x86_64 |
| `anubis-os-macbook` | MacBook Air Intel 2013–2017 (Wi-Fi Broadcom) |

---

## O que vem incluso

### Gaming e produtividade, sem escolher um dos dois

A ideia aqui não é "PC de jogo" de um lado e "PC de trabalho" do outro — é a mesma máquina fazendo as duas coisas bem. Steam e Lutris já vêm prontos, o sistema ajusta prioridade de processo e energia automaticamente quando um jogo abre (`gamemode` + `ananicy-cpp`), e quando você fecha o jogo e abre o LibreOffice ou o VS Code, ninguém percebe diferença — não tem nenhum modo especial pra ligar e desligar.

O Wine não fica na imagem base: tudo de Proton/Wine roda via Flatpak (Steam, Lutris, Bottles), o que mantém o sistema base limpo e fácil de fazer rollback se algo bugar.

| Pacote | Função |
|--------|--------|
| Steam, Lutris, Bottles (Flatpak) | Lojas, Proton e compatibilidade com Windows |
| ProtonUp-Qt | Instala e gerencia versões do Proton-GE/Wine-GE |
| `gamemode` | Otimização de CPU/GPU automática enquanto o jogo roda |
| `gamescope` | Compositor dedicado para jogos |
| `mangohud` + GOverlay | Overlay de performance e a GUI pra configurar ele |
| `ananicy-cpp` | Prioriza automaticamente processos pesados (jogos, compilação etc.) |
| `steam-devices` | Regras de udev pra controle funcionar de primeira |
| `zram-generator-defaults` + `thermald` | Ajuda em máquina com pouca RAM ou mais velha a aquecer/travar menos |

E pro dia a dia "sério", já vem LibreOffice, VS Code e GIMP pré-instalados via Flatpak.

### Pentesting leve, sem virar Kali

Ferramentas básicas de rede e auditoria direto no terminal, sem mexer nas dependências do sistema:

```
nmap  nmap-ncat  whois  curl  wget  traceroute  net-tools
```

Pra ferramenta mais pesada (`sqlmap`, `hydra`, `hashcat` etc.), a recomendação é container via **Toolbox** ou **Distrobox** — mantém isolado e não suja a base.

### Segurança do dia a dia

Nada de ferramenta de auditoria pensada pra servidor — só o básico que faz sentido numa máquina pessoal:

| Ferramenta | O que faz |
|------------|-----------|
| `firewalld` | Firewall com controle por zona |
| `firejail` | Sandboxing de aplicações |
| `clamav` | Antivírus |

### GNOME já configurado

Extensões ativas por padrão via dconf, sem precisar abrir o Extension Manager no primeiro boot:

- **Dash to Dock** — dock sempre visível
- **Blur my Shell** — fundo desfocado no launcher e no dash
- **PaperWM** — janelas em scroll horizontal (bom pra quem usa ultrawide)
- **AppIndicator** — ícone de bandeja pra Discord, Telegram etc.
- **Logo Menu** — menu de sistema com a logo do anubis-os
- **Caffeine** — impede o bloqueio de tela quando precisa

### Terminal

- **fastfetch** — informação do sistema ao abrir o terminal
- **Oh My Bash** — instalado no primeiro boot, sem depender de internet na hora do rebase
- **Starship** — prompt customizado, instalado no primeiro boot ou via `brew install starship`
- **Homebrew** — pra tudo que não faz sentido ir pro rpm-ostree

---

## Instalação

### Rebase a partir de qualquer sistema Universal Blue ou Silverblue

```bash
# Imagem genérica
rpm-ostree rebase ostree-unverified-registry:ghcr.io/floatingskies/anubis-os:44

# Imagem para MacBook Air Intel 2013–2017
rpm-ostree rebase ostree-unverified-registry:ghcr.io/floatingskies/anubis-os-macbook:44
```

Reinicie após o rebase. No próximo boot, o sistema roda o setup de primeiro uso (Oh My Bash, Starship, permissões).

### Verificar a assinatura da imagem

```bash
cosign verify ghcr.io/floatingskies/anubis-os \
  --certificate-identity-regexp=https://github.com/floatingskies \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

---

## Primeiro boot

O serviço `anubis-setup-user` roda automaticamente e:

1. Clona o **Oh My Bash** em `~/.oh-my-bash`
2. Instala o **Starship** em `~/.local/bin` via instalador oficial
3. Aplica o `.bashrc` e as configs de fastfetch e Starship

Se quiser rodar manualmente depois:

```bash
/usr/share/anubis-os/scripts/setup-ohmybash-user.sh
```

---

## Customização

### Adicionar pacotes ao sistema base

Edite `recipe.yml` (ou `recipe-macbook.yml`) e faça rebuild via GitHub Actions.

### Instalar algo pontualmente sem rebuild

```bash
# Persistente no sistema base (use com moderação)
rpm-ostree install <pacote>

# Via Homebrew (sem sudo, não toca no OS)
brew install <pacote>

# Via Flatpak (apps com sandbox)
flatpak install flathub <app-id>
```

### Ferramentas de pentesting num container isolado

```bash
# Criar um container Fedora com acesso à rede do host
distrobox create --name pentest --image fedora:latest
distrobox enter pentest
sudo dnf install nmap hydra sqlmap hashcat
```

---

## Estrutura do repositório

```
anubis-os/
├── recipes/
│   ├── recipe.yml              # imagem genérica
│   └── recipe-macbook.yml      # variante MacBook
├── files/
│   └── system/                 # arquivos copiados para / na imagem
│       ├── usr/share/backgrounds/anubis-os/
│       ├── usr/share/pixmaps/
│       └── usr/share/plymouth/themes/anubis/
└── scripts/
    ├── set-permissions.sh
    ├── setup-hostname.sh
    ├── setup-os-release.sh
    ├── setup-logo.sh
    ├── setup-plymouth.sh
    ├── setup-wallpaper.sh
    ├── setup-ohmybash.sh
    ├── enable-gnome-extensions-defaults.sh
    └── enable-first-boot-units.sh
```

---

## Build local

```bash
# Instalar o BlueBuild CLI
brew install blue-build/tap/bluebuild
# ou
cargo install blue-build

# Build
bluebuild build recipes/recipe.yml
```

---

## Contribuindo

Isso aqui é projeto de hobby, então vai no ritmo que dá — mas issues e PRs são bem-vindos. Achou um Flatpak com ID errado, um script quebrando no build ou uma extensão com UUID desatualizado? Abre uma issue.

---

<div align="center">

Feito com [Universal Blue](https://universal-blue.org/) · Baseado em [Fedora Silverblue](https://silverblue.fedoraproject.org/)

</div>
