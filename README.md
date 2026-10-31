# mint-mac

Script único em Bash que deixa o **Linux Mint (Cinnamon)** com visual de **macOS**:

- **Barra de menus no topo**: maçã à esquerda; bandeja, rede, som e relógio à direita
- **Dock no rodapé** (Plank): centralizado, com zoom e ocultação inteligente
- Tema **WhiteSur** (janelas, painel, ícones e cursor), modo **escuro** ou **claro**
- Botões das janelas à esquerda (fechar, minimizar, maximizar)
- Fonte **Inter** e papéis de parede **4K** (Sonoma, Ventura, Monterey, Big Sur)
- Barra translúcida
- Busca estilo **Spotlight** com Ulauncher (`Ctrl + Espaço`)

## Como usar

Rode **sem `sudo`**, dentro da sessão Cinnamon. A senha de administrador é pedida só para instalar os pacotes.

```bash
git clone https://github.com/sauloprado/mint-mac.git
cd mint-mac
chmod +x mint-mac.sh
./mint-mac.sh          # modo escuro (padrão)
./mint-mac.sh light    # modo claro
```

Você pode rodar o script de novo quando quiser, inclusive para trocar entre claro e escuro. Se alguma parte não mudar na hora, faça logout e login.

## Personalização

No topo do script:

| Variável | Padrão | O que faz |
|---|---|---|
| `INSTALAR_ULAUNCHER` | `1` | `0` não instala a busca estilo Spotlight |
| `TAMANHO_ICONES_DOCK` | `48` | Tamanho dos ícones do dock |
| `ALTURA_PAINEL` | `28` | Altura da barra do topo |
| `PAPEL_BASE` | `Sonoma` | `Sonoma`, `Ventura`, `Monterey` ou `WhiteSur` |

## Voltar ao visual original

Na primeira execução, o script salva um backup em `~/mac-look-backup`. Para restaurar:

```bash
dconf load /org/cinnamon/ < ~/mac-look-backup/cinnamon.dconf
pkill plank; rm ~/.config/autostart/plank.desktop
```

## Créditos

Temas, ícones, cursores e papéis de parede de [vinceliuice/WhiteSur](https://github.com/vinceliuice). Dock: [Plank](https://launchpad.net/plank). Busca: [Ulauncher](https://ulauncher.io).
