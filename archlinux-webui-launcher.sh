#!/bin/bash

# Konfiguračné premenné
WEBUI_DIR="$HOME/AI/apps/stable-diffusion-webui-forge"
BASE_DIR="$HOME/AI/models"

# Farby pre výpis
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Vymazanie starého virtuálneho prostredia pre čistú inštaláciu
if [ -d "$WEBUI_DIR/venv_py310" ]; then
    echo -e "${YELLOW}Odstraňujem staré virtuálne prostredie pre čistú inštaláciu...${NC}"
    rm -rf "$WEBUI_DIR/venv_py310"
fi

echo -e "${YELLOW}================================================================"
echo -e "Spúšťam Stable Diffusion WebUI Forge s Python 3.10.14 (pyenv)"
echo -e "================================================================${NC}"

# Kontrola, či je pyenv nainštalovaný a Python 3.10.14 dostupný
if ! command -v pyenv &> /dev/null; then
    echo -e "${RED}Pyenv nie je nainštalovaný. Prosím, nainštalujte pyenv.${NC}"
    exit 1
fi

# Overenie, či je Python 3.10.14 nainštalovaný cez pyenv
if ! pyenv versions | grep -q "3.10.14"; then
    echo -e "${RED}Python 3.10.14 nie je nainštalovaný cez pyenv.${NC}"
    echo -e "${YELLOW}Inštalujte ho príkazom: pyenv install 3.10.14${NC}"
    exit 1
fi

# Presunúť sa do adresára projektu
cd "$WEBUI_DIR"

# Preklopiť lokálnu verziu Pythonu na 3.10.14 len pre tento adresár
echo -e "${BLUE}Nastavujem lokálnu verziu Python na 3.10.14 pre adresár projektu...${NC}"
pyenv local 3.10.14

# Kontrola, či existuje virtuálne prostredie
if [ ! -d "$WEBUI_DIR/venv_py310" ]; then
    echo -e "${YELLOW}Virtuálne prostredie neexistuje, vytváram nové...${NC}"

    # Použitie Python 3.10.14 z pyenv na vytvorenie venv
    pyenv exec python -m venv venv_py310
    source venv_py310/bin/activate
    pip install --upgrade pip setuptools wheel
    pip install torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 --index-url https://download.pytorch.org/whl/cu121

    # Kontrola, ktorý requirements súbor existuje
    if [ -f "$WEBUI_DIR/requirements.txt" ]; then
        echo -e "${GREEN}Inštalujem z requirements.txt${NC}"
        pip install -r requirements.txt
    elif [ -f "$WEBUI_DIR/requirements_versions.txt" ]; then
        echo -e "${GREEN}Inštalujem z requirements_versions.txt${NC}"
        pip install -r requirements_versions.txt
    else
        echo -e "${YELLOW}Nenájdený štandardný súbor s requirements!${NC}"
        echo -e "${YELLOW}Skúsim spustiť launch.py s parametrom pre inštaláciu...${NC}"
        python launch.py --skip-torch-cuda-test --exit-after-install
    fi
else
    echo -e "${GREEN}Virtuálne prostredie nájdené.${NC}"
fi

# Aktivácia virtuálneho prostredia
source venv_py310/bin/activate

# Kontrola verzie Pythonu
PYTHON_VERSION=$(python --version 2>&1)
echo -e "${BLUE}Používam: $PYTHON_VERSION${NC}"

# Spustenie WebUI
echo -e "${YELLOW}Spúšťam WebUI Forge...${NC}"
python launch.py \
    --xformers \
    --cuda-malloc \
    --ckpt-dir "$BASE_DIR/checkpoints" \
    --lora-dir "$BASE_DIR/loras" \
    --vae-path "$BASE_DIR/vae" \
    --embeddings-dir "$BASE_DIR/embeddings"
