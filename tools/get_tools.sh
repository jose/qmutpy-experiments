#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script downloads and sets up the following tools:
#   - [Simple Python Version Management: pyenv](https://github.com/pyenv/pyenv)
#   - [QMutPy](https://github.com/danielfobooss/mutpy/tree/all_gates)
#   - [Qiskit Aqua](https://github.com/Qiskit/qiskit-aqua/tree/stable/0.9)
#   - [R](https://www.r-project.org)
#
# Usage:
# get_tools.sh
#
# ------------------------------------------------------------------------------

SCRIPT_DIR=$(cd `dirname $0` && pwd)
source "$SCRIPT_DIR/../experiments/utils.sh" || exit 1

# ------------------------------------------------------------------------- Deps

# Check whether 'wget' is available
wget --version > /dev/null 2>&1 || die "[ERROR] Could not find 'wget' to download all dependencies. Please install 'wget' and re-run the script."

# Check whether 'git' is available
git --version > /dev/null 2>&1 || die "[ERROR] Could not find 'git' to clone git repositories. Please install 'git' and re-run the script."

# Check whether 'Rscript' is available
Rscript --version > /dev/null 2>&1 || die "[ERROR] Could not find 'Rscript' to perform, e.g., statistical analysis. Please install 'Rscript' and re-run the script."

# ------------------------------------------------------------------------- Main

#
# Get PyEnv
#

echo ""
echo "Setting up pyenv..."

PYENV_DIR="$SCRIPT_DIR/pyenv"

if [ ! -d "$PYENV_DIR" ]; then
  # pyenv requires some time to install and build, therefore do it if it is required

  git clone https://github.com/pyenv/pyenv.git "$PYENV_DIR"
  if [ "$?" -ne "0" ] || [ ! -d "$PYENV_DIR" ]; then
    die "[ERROR] Clone of 'pyenv' failed!"
  fi

  export PYENV_ROOT="$PYENV_DIR"
  export PATH="$PYENV_ROOT/bin:$PATH"

  git clone https://github.com/pyenv/pyenv-virtualenv.git "$PYENV_ROOT/plugins/pyenv-virtualenv"
  if [ "$?" -ne "0" ] || [ ! -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]; then
    die "[ERROR] Clone of 'pyenv-virtualenv' failed!"
  fi

  # Check whether 'pyenv' is (now) available
  pyenv --version > /dev/null 2>&1 || die "[ERROR] Could not find 'pyenv' to setup Python's virtual environment."

  eval "$(pyenv init --path)" || die "[ERROR] Failed to init pyenv!"
  eval "$(pyenv virtualenv-init -)" || die "[ERROR] Failed to init pyenv-virtualenv!"

  # Install Python v3.7.0
  pyenv install -v 3.7.0

  if [ "$?" -ne "0" ]; then
    echo "[ERROR] Failed to install Python v3.7.0 with pyenv.  Most likely reason is due to OS depends not being installed/available." >&2

    echo "" >&2
    echo "On Ubuntu/Debian please install the following dependencies:" >&2
    echo "sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl" >&2

    echo "" >&2
    echo "On Fedora/CentOS/RHEL please install the following dependencies:" >&2
    echo "sudo yum install zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel xz xz-devel libffi-devel" >&2

    echo "" >&2
    echo "On openSUSE please install the following dependencies:" >&2
    echo "zypper in zlib-devel bzip2 libbz2-devel libffi-devel libopenssl-devel readline-devel sqlite3 sqlite3-devel xz xz-devel" >&2

    echo "" >&2
    echo "On MacOS please install the following dependencies using the [homebrew package management system](https://brew.sh):" >&2
    echo "brew install openssl readline sqlite3 xz zlib" >&2
    echo "When running Mojave or higher (10.14+) you will also need to install the additional [SDK headers](https://developer.apple.com/documentation/xcode_release_notes/xcode_10_release_notes#3035624):" >&2
    echo "sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /" >&2

    die
  fi

  # Switch to the version just installed
  pyenv local 3.7.0 || die "[ERROR] The version just installed is not available to pyenv!"

  python_version=$(python --version)
  if [ "$python_version" != "Python 3.7.0" ]; then
    die "[ERROR] System is still using '$python_version' install of v3.7.0!"
  fi

  # Check whether the version just installed is working properly
  python -m test || die "[ERROR] The version just installed is not working properly!"

  # Disable/Unload the version just installed
  rm "$SCRIPT_DIR/.python-version" || die "[ERROR] Failed to remove '$SCRIPT_DIR/.python-version!'"

  # Create a virtual environment based on the version just installed
  pyenv virtualenv 3.7.0 3.7.0-qmutpy-and-qiskit-aqua || die "[ERROR] Failed to create virtual environment based on the version just installed!"
  # Check whether the virtual environment was correctly created it by loading it
  pyenv activate 3.7.0-qmutpy-and-qiskit-aqua || die "[ERROR] Failed to activate the just created virtual environment!"
  pyenv deactivate || die "[ERROR] Failed to deactivate the just created virtual environment!"
fi

#
# Get QMutPy
#

echo ""
echo "Setting up QMutPy..."

QMUTPY_DIR="$SCRIPT_DIR/qmutpy"

# Remove any previous file and directory
rm -rf "$QMUTPY_DIR"

git clone https://github.com/danielfobooss/mutpy "$QMUTPY_DIR"
if [ "$?" -ne "0" ] || [ ! -d "$QMUTPY_DIR" ]; then
  die "[ERROR] Clone of 'QMutPy' failed!"
fi

pushd . > /dev/null 2>&1
cd "$QMUTPY_DIR"
  # Switch to 'all_gates' branch
  git checkout all_gates || die "[ERROR] Branch 'all_gates' not found!"
  # Switch to lastest commit
  git checkout a2882cce2652743e449e6bbdc34f25d9c68566cc || die "[ERROR] Commit 'a2882cce2652743e449e6bbdc34f25d9c68566cc' not found!"
  # Install it
  python3 setup.py install || die "[ERROR] Failed to install QMutPy!"
popd > /dev/null 2>&1

#
# Get qiskit-aqua
#

echo ""
echo "Setting up Qiskit Aqua..."

QISKIT_AQUA_DIR="$SCRIPT_DIR/qiskit-aqua"

# Remove any previous file and directory
rm -rf "$QISKIT_AQUA_DIR"

git clone https://github.com/Qiskit/qiskit-aqua "$QISKIT_AQUA_DIR"
if [ "$?" -ne "0" ] || [ ! -d "$QISKIT_AQUA_DIR" ]; then
  die "[ERROR] Clone of 'Qiskit Aqua' failed!"
fi

pushd . > /dev/null 2>&1
cd "$QISKIT_AQUA_DIR"
  # Switch to 'stable/0.9' branch
  git checkout stable/0.9 || die "[ERROR] Branch 'stable/0.9' not found!"
  # Switch to lastest commit
  git checkout 49dab4892691d207aacc3d27ce33c11e9ac08777 || die "[ERROR] Commit '49dab4892691d207aacc3d27ce33c11e9ac08777' not found!"
popd > /dev/null 2>&1

echo ""
echo "DONE! All tools have been successfully prepared."

# EOF
