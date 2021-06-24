#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script finds all algorithms available in the Qiskit Aqua's framework
# for which there is a correspondent test suite and then it populates the
# `subjects.csv` file with the following information:
#   - algorithm_name
#   - algorithm_full_name
#   - test_suite_full_name
#
# For example:
# grover,qiskit.aqua.algorithms.amplitude_amplifiers.grover,test.aqua.test_grover
#
# Usage:
# get-subjects.sh
#
# Requirements:
#   Execution of tools/get-tools.sh script.
# ------------------------------------------------------------------------------

SCRIPT_DIR=$(cd `dirname $0` && pwd)
source "$SCRIPT_DIR/../experiments/utils.sh" || exit 1

# ------------------------------------------------------------------------- Args

QISKIT_AQUA_FRAMEWORK_DIR="$SCRIPT_DIR/../tools/qiskit-aqua"
# Check whether QISKIT_AQUA_FRAMEWORK_DIR exits
[ -d "$QISKIT_AQUA_FRAMEWORK_DIR" ] || die "[ERROR] $QISKIT_AQUA_FRAMEWORK_DIR does not exist!"

OUTPUT_FILE="$SCRIPT_DIR/subjects.csv"
echo "algorithm_name,algorithm_full_name,test_suite_full_name" > "$OUTPUT_FILE"

pushd . > /dev/null 2>&1
cd "$QISKIT_AQUA_DIR"
  find qiskit/ -type f -name "*.py" ! -name "__init__.py" ! -name "*utils*" | grep "/algorithms/" | while read -r algorithm_path_file; do
    algorithm_name=$(basename "$algorithm_path_file" | sed 's|.py$||')
    algorithm_py_file=$(basename "$algorithm_path_file")
    find test/ -type f -name "test_$algorithm_py_file" | while read -r test_path_file; do
      echo "$algorithm_name,$(echo $algorithm_path_file | tr '/' '.' | sed 's|.py$||'),$(echo $test_path_file | tr '/' '.' | sed 's|.py$||')" >> "$OUTPUT_FILE"
    done
  done
popd > /dev/null 2>&1

echo "DONE!"
exit 0

# EOF
