#!/usr/bin/env bash
# =============================================================================
#  mint-mac.sh — Script ÚNICO: deixa o Linux Mint (Cinnamon) com visual de macOS
#
#   • Barra de menus no TOPO (maçã à esquerda; ícones e relógio à direita)
#   • Dock no RODAPÉ (Plank centralizado, com zoom, só aparece quando precisa)
#   • Tema WhiteSur (janelas, painel, ícones, cursor), botões à esquerda,
#     fonte Inter, papel de parede 4K, busca estilo Spotlight (Ctrl+Espaço)
#
#  Uso (SEM sudo, dentro da sessão Cinnamon):
#     chmod +x mint-mac.sh
#     ./mint-mac.sh          → modo ESCURO (padrão)
#     ./mint-mac.sh light    → modo CLARO
#  Pode rodar de novo quantas vezes quiser (também serve para trocar o modo).
#
#  Voltar ao visual original do Mint:
#     dconf load /org/cinnamon/ < ~/mac-look-backup/cinnamon.dconf
#     pkill plank; rm ~/.config/autostart/plank.desktop
# =============================================================================
set -uo pipefail

# ---------------------------- CONFIGURAÇÃO -----------------------------------
MODO="${1:-dark}"        # dark | light
INSTALAR_ULAUNCHER=1     # 1 = instala busca estilo Spotlight; 0 = pula
TAMANHO_ICONES_DOCK=48
ALTURA_PAINEL=28
# Papéis de parede: Sonoma | Ventura | Monterey | WhiteSur  (+ -dark / -light)
PAPEL_BASE="Sonoma"
# -----------------------------------------------------------------------------

VERDE='\e[32m'; AMARELO='\e[33m'; VERMELHO='\e[31m'; NC='\e[0m'
info() { echo -e "${VERDE}==>${NC} $*"; }
warn() { echo -e "${AMARELO}[aviso]${NC} $*"; }
erro() { echo -e "${VERMELHO}[erro]${NC} $*"; exit 1; }

case "$MODO" in
  dark)  GTK="WhiteSur-Dark";  ICONES="WhiteSur-dark";  PLANK="WhiteSur-Dark"
         MACA="activities" ;;          # maçã branca na barra escura
  light) GTK="WhiteSur-Light"; ICONES="WhiteSur-light"; PLANK="WhiteSur-Light"
         MACA="activities-black" ;;    # maçã preta na barra clara
  *) erro "Modo inválido. Use: $0 dark   ou   $0 light" ;;
esac
CURSOR="WhiteSur-cursors"

[[ $EUID -eq 0 ]] && erro "Não use sudo. Rode assim: ./mint-mac.sh"
command -v apt >/dev/null || erro "Este script é para Linux Mint / Ubuntu."
[[ "${XDG_CURRENT_DESKTOP:-}" == *Cinnamon* ]] \
  || warn "Ambiente '${XDG_CURRENT_DESKTOP:-?}' não é Cinnamon: barra e dock podem não ser ajustados."

TMP="$(mktemp -d)"
sudo -v || erro "Precisa da senha de administrador."
( while true; do sudo -n true; sleep 50; done ) 2>/dev/null &
SUDO_KEEP=$!
trap 'kill $SUDO_KEEP 2>/dev/null; rm -rf "$TMP"' EXIT

# ----------------------------- 0. BACKUP (só na 1ª vez) ----------------------
mkdir -p ~/mac-look-backup
if [[ ! -s ~/mac-look-backup/cinnamon.dconf ]]; then
  info "Backup do visual original em ~/mac-look-backup"
  dconf dump /org/cinnamon/ > ~/mac-look-backup/cinnamon.dconf 2>/dev/null || true
fi

# ----------------------------- 1. PACOTES ------------------------------------
info "Instalando dependências (apt)"
sudo apt update -y
sudo apt install -y git curl wget unzip dconf-cli sassc libglib2.0-dev-bin \
  libxml2-utils gtk2-engines-murrine gnome-themes-extra plank python3 \
  || erro "Falha ao instalar dependências."
sudo apt install -y fonts-inter >/dev/null 2>&1 || warn "Fonte Inter indisponível; mantendo a atual."

clonar() { git clone --depth=1 -q "https://github.com/vinceliuice/$1.git" "$TMP/$1" \
           || { warn "Não consegui baixar $1 (verifique a internet)."; return 1; }; }

# ----------------------------- 2. TEMAS --------------------------------------
info "Instalando tema WhiteSur (janelas + painel Cinnamon, claro e escuro)"
clonar WhiteSur-gtk-theme || erro "Sem o tema não dá para continuar."
( cd "$TMP/WhiteSur-gtk-theme" && yes | ./install.sh -c dark -c light ) >/dev/null 2>&1
( cd "$TMP/WhiteSur-gtk-theme" && yes | ./install.sh -l -c "$MODO" ) >/dev/null 2>&1   # apps GTK4
[[ -d ~/.themes/$GTK ]] || erro "Tema $GTK não foi instalado em ~/.themes."

# Temas do dock (CORREÇÃO: ficam em other/plank, não em src/other/plank)
mkdir -p ~/.local/share/plank/themes
for v in Dark Light; do
  rm -rf ~/.local/share/plank/themes/WhiteSur-$v
  cp -r "$TMP/WhiteSur-gtk-theme/other/plank/theme-$v" ~/.local/share/plank/themes/WhiteSur-$v
done

info "Instalando ícones WhiteSur"
if [[ ! -d ~/.local/share/icons/$ICONES ]]; then
  clonar WhiteSur-icon-theme && ( cd "$TMP/WhiteSur-icon-theme" && ./install.sh >/dev/null 2>&1 ) \
    || warn "Ícones não instalados."
fi

info "Instalando cursor WhiteSur"
if [[ ! -d ~/.local/share/icons/$CURSOR ]]; then
  clonar WhiteSur-cursors && ( cd "$TMP/WhiteSur-cursors" && ./install.sh >/dev/null 2>&1 ) \
    || warn "Cursor não instalado."
fi

info "Baixando papéis de parede 4K"
WDIR="$( [[ -d ~/Imagens ]] && echo ~/Imagens || echo ~/Pictures )/Wallpapers-Mac"
mkdir -p "$WDIR"
if [[ ! -f "$WDIR/${PAPEL_BASE}-${MODO}.jpg" ]] && clonar WhiteSur-wallpapers; then
  cp -f "$TMP/WhiteSur-wallpapers/4k/"*.jpg "$WDIR"/
fi
WALL="$WDIR/${PAPEL_BASE}-${MODO}.jpg"
[[ -f "$WALL" ]] || WALL="$(find "$WDIR" -iname "*${MODO}*" | head -n1)"

# ----------------------------- 3. APARÊNCIA ----------------------------------
info "Aplicando tema $MODO, ícones, cursor e fontes"
gsettings set org.cinnamon.desktop.interface gtk-theme    "$GTK"
gsettings set org.cinnamon.desktop.interface icon-theme   "$ICONES"
gsettings set org.cinnamon.desktop.interface cursor-theme "$CURSOR"
gsettings set org.cinnamon.desktop.wm.preferences theme   "$GTK"
gsettings set org.cinnamon.theme name                     "$GTK"
gsettings set org.gnome.desktop.interface gtk-theme       "$GTK"          2>/dev/null
gsettings set org.gnome.desktop.interface icon-theme      "$ICONES"       2>/dev/null
gsettings set org.gnome.desktop.interface cursor-theme    "$CURSOR"       2>/dev/null
gsettings set org.gnome.desktop.interface color-scheme    "prefer-$MODO"  2>/dev/null
gsettings set org.x.apps.portal color-scheme              "prefer-$MODO"  2>/dev/null

# Botões da janela à esquerda (fechar, minimizar, maximizar) — igual ao Mac
gsettings set org.cinnamon.desktop.wm.preferences button-layout 'close,minimize,maximize:'
gsettings set org.gnome.desktop.wm.preferences   button-layout 'close,minimize,maximize:' 2>/dev/null

if fc-list | grep -qi "Inter"; then
  gsettings set org.cinnamon.desktop.interface font-name         'Inter 10'
  gsettings set org.gnome.desktop.interface   font-name          'Inter 10' 2>/dev/null
  gsettings set org.nemo.desktop              font               'Inter 10' 2>/dev/null
  gsettings set org.cinnamon.desktop.wm.preferences titlebar-font 'Inter Bold 10'
fi

if [[ -n "$WALL" && -f "$WALL" ]]; then
  gsettings set org.cinnamon.desktop.background picture-uri "file://$WALL"
  gsettings set org.cinnamon.desktop.background picture-options 'zoom'
fi

# ----------------------------- 4. BARRA NO TOPO ------------------------------
info "Barra de menus no topo (sem lista de janelas — elas vão para o dock)"
gsettings set org.cinnamon panels-enabled  "['1:0:top']"
gsettings set org.cinnamon panels-height   "['1:${ALTURA_PAINEL}']"
gsettings set org.cinnamon panels-autohide "['1:false']"
gsettings set org.cinnamon enabled-applets "[
 'panel1:left:0:menu@cinnamon.org:0',
 'panel1:right:0:systray@cinnamon.org:3',
 'panel1:right:1:xapp-status@cinnamon.org:4',
 'panel1:right:2:notifications@cinnamon.org:5',
 'panel1:right:3:removable-drives@cinnamon.org:7',
 'panel1:right:4:keyboard@cinnamon.org:8',
 'panel1:right:5:network@cinnamon.org:10',
 'panel1:right:6:sound@cinnamon.org:11',
 'panel1:right:7:power@cinnamon.org:12',
 'panel1:right:8:calendar@cinnamon.org:13'
]"

info "Barra translúcida"
EXT="transparent-panels@germanfr"
if [[ ! -d ~/.local/share/cinnamon/extensions/$EXT ]] && \
   wget -q -O "$TMP/ext.zip" "https://cinnamon-spices.linuxmint.com/files/extensions/${EXT}.zip"; then
  mkdir -p ~/.local/share/cinnamon/extensions
  unzip -oq "$TMP/ext.zip" -d ~/.local/share/cinnamon/extensions/
fi
if [[ -d ~/.local/share/cinnamon/extensions/$EXT ]]; then
  ATUAIS="$(gsettings get org.cinnamon enabled-extensions)"
  if [[ "$ATUAIS" != *"$EXT"* ]]; then
    if [[ "$ATUAIS" == "@as []" || "$ATUAIS" == "[]" ]]; then
      gsettings set org.cinnamon enabled-extensions "['$EXT']"
    else
      gsettings set org.cinnamon enabled-extensions "${ATUAIS%]}, '$EXT']"
    fi
  fi
fi

# ----------------------------- 5. DOCK NO RODAPÉ -----------------------------
info "Dock no rodapé (Plank)"
pkill -x plank 2>/dev/null; sleep 1
LAUNCH=~/.config/plank/dock1/launchers
mkdir -p "$LAUNCH"; rm -f "$LAUNCH"/*.dockitem
ITENS=()
for app in nemo google-chrome firefox org.gnome.Terminal org.x.editor xed \
           org.gnome.Calculator libreoffice-writer libreoffice-calc \
           mintinstall cinnamon-settings; do
  f="/usr/share/applications/${app}.desktop"
  [[ -f "$f" ]] || continue
  printf '[PlankDockItemPreferences]\nLauncher=file://%s\n' "$f" > "$LAUNCH/${app}.dockitem"
  ITENS+=("'${app}.dockitem'")
done
P="net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/"
gsettings set "$P" dock-items     "[$(IFS=,; echo "${ITENS[*]}")]" 2>/dev/null
gsettings set "$P" theme          "$PLANK"
gsettings set "$P" position       'bottom'
gsettings set "$P" alignment      'center'
gsettings set "$P" icon-size      "$TAMANHO_ICONES_DOCK"
gsettings set "$P" zoom-enabled   true
gsettings set "$P" zoom-percent   150
gsettings set "$P" hide-mode      'intelligent'
gsettings set "$P" show-dock-item false

mkdir -p ~/.config/autostart
cat > ~/.config/autostart/plank.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
X-GNOME-Autostart-enabled=true
EOF
nohup plank >/dev/null 2>&1 &

# ----------------------------- 6. SPOTLIGHT ----------------------------------
if [[ "$INSTALAR_ULAUNCHER" == "1" ]] && ! command -v ulauncher >/dev/null; then
  info "Instalando Ulauncher (busca estilo Spotlight — Ctrl+Espaço)"
  if sudo add-apt-repository -y ppa:agornostal/ulauncher && sudo apt update -y \
     && sudo apt install -y ulauncher; then
    cat > ~/.config/autostart/ulauncher.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Ulauncher
Exec=ulauncher --hide-window
X-GNOME-Autostart-enabled=true
EOF
    nohup ulauncher --hide-window >/dev/null 2>&1 &
  else
    warn "Ulauncher não instalado."
  fi
fi

# ----------------------------- 7. RECARREGA A BARRA --------------------------
reiniciar_cinnamon() {
  dbus-send --session --dest=org.Cinnamon --type=method_call /org/Cinnamon \
    org.Cinnamon.RestartCinnamon boolean:false >/dev/null 2>&1 \
  || dbus-send --session --dest=org.Cinnamon --type=method_call /org/Cinnamon \
    org.Cinnamon.Eval string:'global.reexec_self()' >/dev/null 2>&1 || true
}
info "Recarregando o Cinnamon (a tela vai piscar)"
reiniciar_cinnamon
sleep 8

# ----------------------------- 8. MAÇÃ NO MENU -------------------------------
# CORREÇÃO: a config do menu só existe depois que a barra nova carrega,
# por isso a maçã é aplicada agora (ao vivo + no arquivo).
info "Trocando o ícone do Mint pela maçã"
mkdir -p ~/.local/share/icons/mac-menu
ICON=~/.local/share/icons/mac-menu/apple-menu-$MODO.svg
cp "$TMP/WhiteSur-gtk-theme/src/assets/gnome-shell/$MACA/activities-apple.svg" "$ICON"

# 1) ao vivo, pela própria interface do Cinnamon
for par in "menu-custom|true" "menu-icon|\"$ICON\"" "menu-label|\"\"" "menu-icon-size|18"; do
  dbus-send --session --dest=org.Cinnamon --type=method_call /org/Cinnamon \
    org.Cinnamon.updateSetting string:menu@cinnamon.org string:0 \
    string:"${par%%|*}" string:"${par#*|}" >/dev/null 2>&1 || true
done

# 2) no arquivo de configuração (garante que fica salvo)
DIR_MENU=~/.config/cinnamon/spices/menu@cinnamon.org
mkdir -p "$DIR_MENU"
python3 - "$DIR_MENU/0.json" "$ICON" <<'PY'
import json, os, sys
cfg, icon = sys.argv[1], sys.argv[2]
schema = "/usr/share/cinnamon/applets/menu@cinnamon.org/settings-schema.json"
if os.path.exists(cfg):
    d = json.load(open(cfg))
else:
    d = json.load(open(schema)) if os.path.exists(schema) else {}
    for v in d.values():
        if isinstance(v, dict) and "default" in v:
            v["value"] = v["default"]
def setv(k, val):
    if isinstance(d.get(k), dict): d[k]["value"] = val
    else: d[k] = {"type": "generic", "default": val, "value": val}
setv("menu-custom", True); setv("menu-icon", icon)
setv("menu-label", "");    setv("menu-icon-size", 18)
json.dump(d, open(cfg, "w"), indent=4)
PY

reiniciar_cinnamon

echo
info "Pronto! Visual Mac ($MODO): barra no topo + dock no rodapé."
echo "   • Se algo não mudou, faça logout e login."
echo "   • Trocar o modo:  ./mint-mac.sh light   ou   ./mint-mac.sh dark"
echo "   • Papéis de parede extras em: $WDIR"
echo "   • Voltar ao original: dconf load /org/cinnamon/ < ~/mac-look-backup/cinnamon.dconf"
