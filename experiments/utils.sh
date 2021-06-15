#!/usr/bin/env bash

PWD=`pwd`
USER_HOME_DIR=$(cd ~ && pwd)

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

#
# Print error message to the stdout and exit.
#
die() {
  echo "$@" >&2
  exit 1
}

#
# Init [Simple Python Version Management: pyenv](https://github.com/pyenv/pyenv).
#
_init_pyenv() {
  export PYENV_ROOT="$PWD/../tools/pyenv"
  [ -d "$PYENV_ROOT" ] || die "[ERROR] $PYENV_ROOT does not exist!"
  export PATH="$PYENV_ROOT/bin:$PATH"

  # Check whether `pyenv` is available
  pyenv --version > /dev/null 2>&1 || die "[ERROR] Could not find 'pyenv'!"

  # Init it
  eval "$(pyenv init --path)" || die "[ERROR] Failed to init pyenv!"

  return 0
}

#
# Activate virtual environment.
#
_activate_virtual_environment() {
  local USAGE="Usage: ${FUNCNAME[0]}"
  if [ "$#" != 0 ] ; then
    echo "$USAGE" >&2
    return 1
  fi

  source env/bin/activate || die "[ERROR] Failed to activate virtual environment!"
  python --version >&2

  return 0
}

#
# Deactivate virtual environment.
#
_deactivate_virtual_environment() {
  local USAGE="Usage: ${FUNCNAME[0]}"
  if [ "$#" != 0 ] ; then
    echo "$USAGE" >&2
    return 1
  fi

  deactivate || die "[ERROR] Failed to deactivate virtual environment!"

  return 0
}

# EOF
