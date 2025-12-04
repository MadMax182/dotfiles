#!/bin/bash

# Main installation script with selective script execution

cd "$(dirname "$0" | cut -d'/' -f1-4)"

source "./paths/paths.conf" || { echo "Error: paths.conf not found"; exit 1; }

# Colors
B='\033[0;34m' G='\033[0;32m' Y='\033[1;33m' R='\033[0;31m' N='\033[0m'

echo -e "${B}=== Dotfiles Installation Suite ===${N}\n"

[ ! -d "$INSTALL_SCRIPTS_DIR" ] && echo -e "${R}Error: $INSTALL_SCRIPTS_DIR not found${N}" && exit 1

# Get sorted scripts
mapfile -t scripts < <(find "$INSTALL_SCRIPTS_DIR" -maxdepth 1 -name "*.sh" -type f | sort)

[ ${#scripts[@]} -eq 0 ] && echo -e "${Y}No scripts found${N}" && exit 0

# Display scripts
echo "Found ${#scripts[@]} script(s):"
for i in "${!scripts[@]}"; do
  printf "  %d. %s\n" $((i+1)) "${scripts[i]##*/}"
done

echo -e "\n${Y}Select scripts to run:${N}"
echo "  Enter = all | Selection: 1 3 5 | Range: 1-3 | Combined: 1 3-5 7"
read -p "Selection: " selection

# Parse selection
selected=()

if [ -z "$selection" ]; then
  selected=("${!scripts[@]}")
else
  for part in ${selection//,/ }; do
    if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      for ((i=${BASH_REMATCH[1]}; i<=${BASH_REMATCH[2]}; i++)); do
        idx=$((i-1))
        [ $idx -ge 0 ] && [ $idx -lt ${#scripts[@]} ] && selected+=($idx)
      done
    elif [[ "$part" =~ ^[0-9]+$ ]]; then
      idx=$((part-1))
      [ $idx -ge 0 ] && [ $idx -lt ${#scripts[@]} ] && selected+=($idx)
    fi
  done
fi

# Remove duplicates and sort
selected=($(printf "%s\n" "${selected[@]}" | sort -nu))

[ ${#selected[@]} -eq 0 ] && echo "No valid scripts selected." && exit 0

# Confirm
echo -e "\n${G}Scripts to run:${N}"
for idx in "${selected[@]}"; do echo "  - ${scripts[idx]##*/}"; done

read -p $'\nProceed? (Y/n): ' -n 1 -r
echo
[[ $REPLY =~ ^[Nn]$ ]] && echo "Cancelled." && exit 0

echo

# Run scripts
for idx in "${selected[@]}"; do
  name="${scripts[idx]##*/}"
  echo -e "${B}=== Running: $name ===${N}"
  chmod +x "${scripts[idx]}" 2>/dev/null
  bash "${scripts[idx]}" || echo -e "${Y}Warning: $name had errors${N}"
  echo -e "${G}=== Completed: $name ===${N}\n"
done

echo -e "${G}=== Installation Complete! ===${N}"
exit 0
