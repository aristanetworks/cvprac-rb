#!/usr/bin/env bash
set -eu -o pipefail

# USAGE: bin/install-hooks.sh

# install-hooks.sh will setup or repair (in many cases) symlinks from your
# .git/hooks/ directory to the git hook scripts in this repo.  These scripts
# ensure certain checks succeed before the git action is completed.  The most
# common example is the pre-commit hook which usually checks syntax and style
# before a commit can continue.

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
