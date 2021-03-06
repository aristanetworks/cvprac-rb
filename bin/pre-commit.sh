#!/bin/sh
set -u -o pipefail
#
# Called by "git commit".  The hook will run several checks on the
# source-code.  If it exits with a non-zero status, the commit will
# be halted.
#
# To enable this hook, link this file to ".git/hooks/pre-commit":
#   bin/install-hooks.sh
#
RVM=$(rvm env --path --)
if [ $? ]; then
    # shellcheck source=/dev/null
    . "${RVM}"
fi


if git rev-parse --verify HEAD >/dev/null 2>&1
then
	against=HEAD
else
	# Initial commit: diff against an empty tree object
	against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi

# If you want to allow non-ASCII filenames set this variable to true.
allownonascii=$(git config --bool hooks.allownonascii)

# Redirect output to stderr.
exec 1>&2

# Cross platform projects tend to avoid non-ASCII filenames; prevent
# them from being added to the repository. We exploit the fact that the
# printable range starts at the space character and ends with tilde.

# shellcheck disable=SC2046
if [ "$allownonascii" != "true" ] &&
	# Note that the use of brackets around a tr range is ok here, (it's
	# even required, for portability to Solaris 10's /usr/bin/tr), since
	# the square bracket bytes happen to fall in the designated range.
	test $(git diff --cached --name-only --diff-filter=A -z $against |
	  LC_ALL=C tr -d '[ -~]\0' | wc -c) != 0
then
	cat <<\EOF
Error: Attempt to add a non-ASCII file name.

This can cause problems if you want to work with people on other platforms.

To be portable it is advisable to rename the file.

If you know what you are doing you can disable this check using:

  git config hooks.allownonascii true
EOF
	exit 1
fi

# If there are whitespace errors, print the offending file names and fail.
git diff-index --check --cached $against --

err=0

bundle exec rubocop
#let "err = $err + $?"
err=$((err + $?))

bundle exec rake spec:unit
err=$((err + $?))

bundle exec rake yard
err=$((err + $?))

echo

if [ ${err} != 0 ]; then
    echo "\033[31mERROR: Some checks failed.  Commit halted.\033[0m"
fi
exit ${err}
