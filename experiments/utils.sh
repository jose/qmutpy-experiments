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
# Check whether an expected Python version is installed
#
_check_python_requirements() {
  # Check whether 'python3' is available
  python3 --version > /dev/null 2>&1
  if [ "$?" -ne "0" ]; then
    echo "[ERROR] Could not find 'python3' to, e.g., run any Python script. Please install 'Python 3.6' and re-run the script!" >&2
    return 1
  fi

  # Check whether Python 3.6 is available
  python3 << END
import sys
if not (sys.version_info.major == 3 and sys.version_info.minor == 6):
  print("You are using Python {}.{}.".format(sys.version_info.major, sys.version_info.minor))
  print("This script requires Python 3.6!")
  sys.exit(1)
sys.exit(0)
END
  if [ "$?" -ne "0" ]; then
    die
  fi

  # Check whether 'pip3' is available
  pip3 --version > /dev/null 2>&1
  if [ "$?" -ne "0" ]; then
    echo "[ERROR] Could not find 'pip3' to, e.g., install any Python dependencies. Please install 'pip3' and re-run the script!" >&2
    return 1
  fi

  return 0
}

# EOF
