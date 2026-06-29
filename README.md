# 🌟 anubis-os

[![build-ublue](https://github.com/SEU_USUARIO/anubis-os/actions/workflows/build.yml/badge.svg)](https://github.com/SEU_USUARIO/anubis-os/actions/workflows/build.yml)
![GitHub stars](https://img.shields.io/github/stars/SEU_USUARIO/anubis-os?style=social)
![Image Version](https://img.shields.io/badge/Fedora_Version-44-blue?logo=fedora)
![Base](https://img.shields.io/badge/Base-Silverblue_Main-informational)

> **O canivete suíço definitivo para o dia a dia.** Uma imagem customizada e imutável baseada no Fedora Silverblue (via Universal Blue), projetada para quem quer jogar sem dor de cabeça, fazer pentesting leve de forma isolada e manter a máquina segura no uso diário.

---

## 🛠️ O que é o anubis-os?

O **anubis-os** nasceu daquela clássica vontade de *hobbyist* de não querer ter três sistemas operacionais ou VMs diferentes para tarefas do cotidiano. Em vez de quebrar o sistema instalando dezenas de pacotes de auditoria diretamente na base, esta imagem traz um ecossistema híbrido, limpo e atômico.

* **🕹️ Gaming:** Pronto para o play via Flatpak (Steam, Lutris, Heroic) e otimizado com `gamemode` e `gamescope`. Nada de Wine poluindo o sistema base.
* **🛡️ Pentesting Leve:** Ferramentas essenciais direto no terminal (`nmap`, `masscan`, `sqlmap`, `hydra`, `hashcat`) para auditorias rápidas sem quebrar as dependências do OS.
* **🔒 Segurança Hardened:** Camada extra de proteção diária com `firewalld`, `firejail` para sandboxing, além de `clamav` e `rkhunter`.
* **🎨 GNOME Moderno:** Visual refinado de fábrica usando extensões consagradas como *Blur my Shell*, *Dash to Dock* e *PaperWM* para produtividade máxima.

---

## 🚀 Como Instalar / Rebasear

Se você já está em um sistema baseado em Universal Blue ou Fedora Silverblue, pode rebasear diretamente para o **anubis-os** com o comando abaixo:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/SEU_USUARIO/anubis-os:44
