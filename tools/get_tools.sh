#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script downloads and sets up the following tools:
#   - Python 3.7
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

# Check whether 'python3' and 'pip3' is available
_check_python_requirements || die "[ERROR] Python is not properly configured!"

# Check whether 'Rscript' is available
Rscript --version > /dev/null 2>&1 || die "[ERROR] Could not find 'Rscript' to perform, e.g., statistical analysis. Please install 'Rscript' and re-run the script."

# ------------------------------------------------------------------------- Main

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
