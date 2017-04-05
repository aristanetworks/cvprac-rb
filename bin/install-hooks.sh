#!/usr/bin/env bash
set -eu -o pipefail

HOOKS=('pre-commit.sh')

for script in "${HOOKS[@]}"; do
    hook="$(basename -s '.sh' "${script}")"
    echo -n "    Linking ${hook} hook..."
    if [ -L ".git/hooks/${hook}" ]; then
        echo "already linked."
    elif [ -f ".git/hooks/${hook}" ]; then
        echo -e "\033[31mERROR: exists but is not a link.\033[0m"
    else
        ln -s "../../bin/${script}" ".git/hooks/${hook}"
        echo "complete."
    fi
done
