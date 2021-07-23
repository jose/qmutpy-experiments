#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script perform an exploratory experiment to study whether more test
# assertions can indeed increase the mutation score of a test suite.
#
# Usage:
# run-exp.sh
#   [--quantum_framework_root_path <path, e.g., $(pwd)/../../tools/qiskit-aqua/>]
#   [--pyenv_root_path <path, e.g., $(pwd)/../../tools/pyenv/>]
#   --mutation_data_dir_path <path>
#   [help]
#
# Requirements:
#   Execution of tools/get-tools.sh script.
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/../../experiments/utils.sh" || exit 1

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} [--quantum_framework_root_path <path, e.g., \$(pwd)/../../tools/qiskit-aqua/>] [--pyenv_root_path <path, e.g., \$(pwd)/../../tools/pyenv/>] --mutation_data_dir_path <path> [help]"
if [ "$#" -ne "1" ] && [ "$#" -ne "2" ] && [ "$#" -ne "4" ] && [ "$#" -ne "6" ]; then
  die "$USAGE"
fi

QUANTUM_FRAMEWORK_ROOT_PATH="$(pwd)/../../tools/qiskit-aqua"
PYENV_ROOT_PATH="$(pwd)/../../tools/pyenv"
MUTATION_DATA_DIR_PATH=""

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--quantum_framework_root_path)
      QUANTUM_FRAMEWORK_ROOT_PATH=$1;
      shift;;
    (--pyenv_root_path)
      PYENV_ROOT_PATH=$1;
      shift;;
    (--mutation_data_dir_path)
      MUTATION_DATA_DIR_PATH=$1;
      shift;;
    (--help)
      echo "$USAGE"
      exit 0
    (*)
      die "$USAGE";;
  esac
done

# Check whether all arguments have been initialized
[ "$QUANTUM_FRAMEWORK_ROOT_PATH" != "" ] || die "[ERROR] Missing --quantum_framework_root_path argument!"
[ "$PYENV_ROOT_PATH" != "" ]             || die "[ERROR] Missing --pyenv_root_path argument!"
[ "$MUTATION_DATA_DIR_PATH" != "" ]      || die "[ERROR] Missing --mutation_data_dir_path argument!"

# From relative to full paths
QUANTUM_FRAMEWORK_ROOT_PATH=$(cd "$QUANTUM_FRAMEWORK_ROOT_PATH" && pwd)
PYENV_ROOT_PATH=$(cd "$PYENV_ROOT_PATH" && pwd)
MUTATION_DATA_DIR_PATH=$(cd "$MUTATION_DATA_DIR_PATH" && pwd)

# Check whether QUANTUM_FRAMEWORK_ROOT_PATH exits
[ -d "$QUANTUM_FRAMEWORK_ROOT_PATH" ] || die "[ERROR] $QUANTUM_FRAMEWORK_ROOT_PATH does not exist!"
# Check whether PYENV_ROOT_PATH exits
[ -d "$PYENV_ROOT_PATH" ]             || die "[ERROR] $PYENV_ROOT_PATH does not exist!"
# Check whether MUTATION_DATA_DIR_PATH exits
[ -d "$MUTATION_DATA_DIR_PATH" ]      || die "[ERROR] $MUTATION_DATA_DIR_PATH does not exist!"

# Directory to which any data will be written by this script
DATA_OUTPUT_DIR="$SCRIPT_DIR/data"
mkdir -p "$DATA_OUTPUT_DIR" || die "[ERROR] Failed to create $DATA_OUTPUT_DIR!"

PATCH="$SCRIPT_DIR/not-killed-to-killed.patch"
# Check whether PATCH exits
[ -s "$PATCH" ] || die "[ERROR] $PATCH does not exist!"

# ------------------------------------------------------------------------- Util

#
# Run mutation analysis on an augmented test suite and check whether the number
# of mutants killed by it is higher than the number of mutants killed by the
# original test suite.
#
run_analysis() {
  local USAGE="Usage: ${FUNCNAME[0]} algorithm_name <name, e.g., shor> algorithm_full_name <path, e.g., qiskit.aqua.algorithms.factorizers.shor> algorithm_test_suite_full_name <path, e.g., test.aqua.test_shor> mutation_operator <name, e.g., QGD>"
  if [ "$#" != 4 ] ; then
    echo "$USAGE" >&2
    return 1
  fi

  algorithm_name="$1"
  algorithm_full_name="$2"
  algorithm_test_suite_full_name="$3"
  mutation_operator="$4"

  # Run mutation analysis
      mutation_yaml_file="$DATA_OUTPUT_DIR/$algorithm_full_name.$mutation_operator.yaml"
  csv_report_output_file="$DATA_OUTPUT_DIR/$algorithm_full_name.$mutation_operator.csv"
  bash "$SCRIPT_DIR/../../experiments/run-qmutpy.sh" \
    --quantum_framework_root_path "$QUANTUM_FRAMEWORK_TMP_DIR" \
    --algorithm_name "$algorithm_name" \
    --algorithm_full_name "$algorithm_full_name" \
    --algorithm_test_suite_full_name "$algorithm_test_suite_full_name" \
    --mutation_operator "$mutation_operator" \
    --yaml_report_output_file "$mutation_yaml_file" \
    --csv_report_output_file "$csv_report_output_file" || die "[ERROR] Failed to run QMutPy!"
  [ -s "$mutation_yaml_file" ] || die "[ERROR] $mutation_yaml_file does not exist or it is empty!"
  [ -s "$csv_report_output_file" ] || die "[ERROR] $csv_report_output_file does not exist or it is empty!"

  # Check whether mutants killed by the original test suite are still killed by
  # the augmented test suite
  original_csv_report_output_file="$MUTATION_DATA_DIR/$algorithm_name/$mutation_operator/data.csv"
  [ -s "$original_csv_report_output_file" ] || die "[ERROR] $original_csv_report_output_file does not exist or it is empty!"
  while read -r row; do
    grep ",$row," "$csv_report_output_file" || die "[ERROR] $row does not occur in $csv_report_output_file and therefore mutant killed by the original test suite is not killed by the augmented test suite!"
  done < <(grep ",$mutation_operator,killed," "$original_csv_report_output_file" | cut -f12,13,14 -d',')

  # Check whether the augmented test suite kills more mutants than the original
  # test suite
   num_mutants_killed_original_test_suite=$(grep ",$mutation_operator,killed," "$original_csv_report_output_file" | wc -l)
  num_mutants_killed_augmented_test_suite=$(grep ",$mutation_operator,killed," "$csv_report_output_file" | wc -l)
  [ "$num_mutants_killed_augmented_test_suite" -ge "$num_mutants_killed_original_test_suite" ] || die "[ERROR] Augmented test suite killed $num_mutants_killed_augmented_test_suite mutants whereas the original test suite killed $num_mutants_killed_original_test_suite mutants!"
  echo "[INFO] Augmented test suite killed $num_mutants_killed_augmented_test_suite mutants whereas the original test suite killed $num_mutants_killed_original_test_suite mutants."

  return 0
}

# ------------------------------------------------------------------------- Main

echo "PID: $$"
echo "Job started at $(date)"
hostname

#
# Copy Quantum-framework's repository to a temporary directory and all required
# runtime dependencies
#

TMP_DIR="/tmp/$USER-$$"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# Framework
QUANTUM_FRAMEWORK_TMP_DIR="$TMP_DIR/framework"
mkdir -p "$QUANTUM_FRAMEWORK_TMP_DIR"
rsync -avzP "$QUANTUM_FRAMEWORK_ROOT_PATH/" "$QUANTUM_FRAMEWORK_TMP_DIR/" || die "[ERROR] Failed to make a copy of $QUANTUM_FRAMEWORK_ROOT_PATH!"
# Enviroment dependencies
mkdir -p "$TMP_DIR/pyenv/"
rsync -avzP "$PYENV_ROOT_PATH/" "$TMP_DIR/pyenv/" || die "[ERROR] Failed to make a copy of $PYENV_ROOT_PATH!"

#
# Adapt paths
#

sed -i "s|$QUANTUM_FRAMEWORK_ROOT_PATH|$QUANTUM_FRAMEWORK_TMP_DIR|g" "$QUANTUM_FRAMEWORK_TMP_DIR/env/bin/activate" || die "[ERROR] Failed to adapt $QUANTUM_FRAMEWORK_TMP_DIR/env/bin/activate script!"
sed -i "s|$QUANTUM_FRAMEWORK_ROOT_PATH|$QUANTUM_FRAMEWORK_TMP_DIR|g" "$QUANTUM_FRAMEWORK_TMP_DIR/env/lib/python3.7/site-packages/setuptools.pth" || die "[ERROR] Failed to adapt $QUANTUM_FRAMEWORK_TMP_DIR/env/lib/python3.7/site-packages/setuptools.pth file!"
sed -i "s|$PYENV_ROOT_PATH|$TMP_DIR/pyenv|g" "$QUANTUM_FRAMEWORK_TMP_DIR/env/pyvenv.cfg" || die "[ERROR] Failed to adapt $QUANTUM_FRAMEWORK_TMP_DIR/env/pyvenv.cfg file!"

#
# Augment existing test cases
#

pushd . > /dev/null 2>&1
cd "$QUANTUM_FRAMEWORK_TMP_DIR"
  git apply "$PATCH" || die "[ERROR] Failed to apply $PATCH!"
  # Build modified code
  _activate_virtual_environment || die
    python setup.py install || die "[ERROR] Failed to build modified code!"
  _deactivate_virtual_environment || die
popd > /dev/null 2>&1

#
# Perform analysis
#

for mutation_operator in 'QGD' 'QGI' 'QGR' 'QMD' 'QMI'; do
  #
  # Case 1
  # https://github.com/Qiskit/qiskit-aqua/blob/stable/0.9/qiskit/aqua/algorithms/factorizers/shor.py
  # https://github.com/Qiskit/qiskit-aqua/blob/stable/0.9/test/aqua/test_shor.py
  #
  run_analysis \
    "shor" \
    "qiskit.aqua.algorithms.factorizers.shor" \
    "test.aqua.test_shor" \
    "$mutation_operator" || die
done

# Clean up
rm -rf "$TMP_DIR"

echo "Job finished at $(date)"
echo "DONE!"
exit 0

# EOF
