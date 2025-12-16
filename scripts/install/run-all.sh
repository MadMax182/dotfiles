#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Find all .sh scripts except this one
# Sort: numbered scripts first (by number), then alphabetically for the rest
mapfile -t scripts < <(
    find "$SCRIPT_DIR" -maxdepth 1 -name "*.sh" -type f ! -name "$SCRIPT_NAME" -printf "%f\n" | \
    awk '
        /^[0-9]/ { numbered[NR] = $0; next }
        { other[NR] = $0 }
        END {
            n = asorti(numbered, sorted_n)
            for (i = 1; i <= n; i++) print numbered[sorted_n[i]]
            n = asorti(other, sorted_o)
            for (i = 1; i <= n; i++) print other[sorted_o[i]]
        }
    ' | while read -r f; do echo "$SCRIPT_DIR/$f"; done
)

if [[ ${#scripts[@]} -eq 0 ]]; then
    echo "No scripts found in $SCRIPT_DIR"
    exit 1
fi

# Display scripts
echo "Scripts to execute:"
for i in "${!scripts[@]}"; do
    printf "  %d) %s\n" "$((i + 1))" "$(basename "${scripts[$i]}")"
done
echo
echo "Enter numbers to run (e.g., 1 3 or 1-3), or press Enter to run all"
read -r -p "==> " input

# Collect scripts to run
to_run=()
if [[ -z "$input" ]]; then
    # No input = run all
    to_run=("${scripts[@]}")
else
    # Parse input (supports single numbers and ranges like 1-3)
    declare -A selected
    for part in $input; do
        if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            # Range (e.g., 1-3)
            start="${BASH_REMATCH[1]}"
            end="${BASH_REMATCH[2]}"
            for ((num=start; num<=end; num++)); do
                idx=$((num - 1))
                if [[ $idx -ge 0 && $idx -lt ${#scripts[@]} ]]; then
                    selected[$idx]=1
                fi
            done
        elif [[ "$part" =~ ^[0-9]+$ ]]; then
            # Single number
            idx=$((part - 1))
            if [[ $idx -ge 0 && $idx -lt ${#scripts[@]} ]]; then
                selected[$idx]=1
            fi
        fi
    done
    # Add selected scripts in order
    for i in "${!scripts[@]}"; do
        if [[ -n "${selected[$i]}" ]]; then
            to_run+=("${scripts[$i]}")
        fi
    done
fi

if [[ ${#to_run[@]} -eq 0 ]]; then
    echo "No scripts selected."
    exit 0
fi

# Show selected scripts
echo
echo "Selected scripts:"
for script in "${to_run[@]}"; do
    echo "  - $(basename "$script")"
done
echo
read -r -p "Proceed? [Y/n] " confirm
if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo "Cancelled."
    exit 0
fi
echo
echo "Executing ${#to_run[@]} script(s)..."
echo "=========================="

for script in "${to_run[@]}"; do
    echo
    echo -e "\e[1;34m>>> Running: $(basename "$script")\e[0m"
    echo "----------------------------"

    bash "$script"

    exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo
        echo -e "\e[1;31m>>> $(basename "$script") exited with code $exit_code\e[0m"
        read -r -p "Continue with remaining scripts? [Y/n] " continue_choice
        if [[ "$continue_choice" =~ ^[Nn]$ ]]; then
            echo "Stopped."
            exit $exit_code
        fi
    else
        echo -e "\e[1;32m>>> $(basename "$script") completed successfully\e[0m"
    fi
done

echo
echo -e "\e[1;32mAll selected scripts completed.\e[0m"
