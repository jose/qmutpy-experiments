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
# Init [Simple Python Version Management: pyenv](https://github.com/pyenv/pyenv)
# and [pyenv-virtualenv](https://github.com/pyenv/pyenv-virtualenv).
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
# Load a specific Python version and activate a virtual environment.
#
_load_pyenv() {
  local USAGE="Usage: ${FUNCNAME[0]} <env name>"
  if [ "$#" != 1 ] ; then
    echo "$USAGE" >&2
    return 1
  fi

  local env_name="$1"

  source env/bin/activate || die "[ERROR] Failed to activate virtual environment!"
  pyenv local "$env_name" || die "[ERROR] Failed to load the Python virtual environment '$env_name'!"
  python --version >&2

  return 0
}

#
# Unload the loaded Python version and deactivate a virtual environment.
#
_unload_pyenv() {
  local USAGE="Usage: ${FUNCNAME[0]}"
  if [ "$#" != 0 ] ; then
    echo "$USAGE" >&2
    return 1
  fi

  deactivate           || die "[ERROR] Failed to deactivate virtual environment!"
  rm ".python-version" || die "[ERROR] Failed to unload the loaded Python virtual environment!"

  return 0
}

# EOF
