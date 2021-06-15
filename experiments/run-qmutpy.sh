#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script runs QMutPy on a single quantum algorithm.
#
# Usage:
# run-qmutpy.sh
#   --quantum_framework_name <name, e.g., qiskit-aqua>
#   --quantum_framework_root_path <path, e.g., $(pwd)/../tools/qiskit-aqua/>
#   --pyenv_name <name, e.g., 3.7.0>
#   --algorithm_name <name, e.g., shor>
#   --algorithm_file_path <path, e.g., qiskit/aqua/algorithms/factorizers/shor.py>
#   --algorithm_test_suite_file_path <path, e.g., test/aqua/test_shor.py>
#   --mutation_operator <name, e.g., QGD>
#   --report_output_file <path, e.g., qiskit-aqua-shor-QGD.yaml>
#   [help]
#
# Requirements:
#   Execution of tools/get_tools.sh script.
# ------------------------------------------------------------------------------

SCRIPT_DIR=$(cd `dirname $0` && pwd)
source "$SCRIPT_DIR/utils.sh" || exit 1

# ------------------------------------------------------------------------- Envs

# Init pyenv and pyenv-virtualenv
_init_pyenv || die

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} --quantum_framework_name <name, e.g., qiskit-aqua> --quantum_framework_root_path <path, e.g., \$(pwd)/../tools/qiskit-aqua/> --pyenv_name <name, e.g., 3.7.0> --algorithm_name <name, e.g., shor> --algorithm_path <path, e.g., qiskit/aqua/algorithms/factorizers/shor.py> --algorithm_test_suite_file_path <path, e.g., test/aqua/test_shor.py> --mutation_operator <name, e.g., QGD> --report_output_file <path, e.g., qiskit-aqua-shor-QGD.yaml> [help]"
if [ "$#" -ne "16" ]; then
  die "$USAGE"
fi

QUANTUM_FRAMEWORK_NAME=""
QUANTUM_FRAMEWORK_ROOT_PATH=""
PYENV_NAME=""
ALGORITHM_NAME=""
ALGORITHM_PATH=""
ALGORITHM_TEST_SUITE_FILE_PATH=""
MUTATION_OPERATOR=""
REPORT_OUTPUT_FILE=""

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--quantum_framework_name)
      QUANTUM_FRAMEWORK_NAME=$1;
      shift;;
    (--quantum_framework_root_path)
      QUANTUM_FRAMEWORK_ROOT_PATH=$1;
      shift;;
    (--pyenv_name)
      PYENV_NAME=$1;
      shift;;
    (--algorithm_name)
      ALGORITHM_NAME=$1;
      shift;;
    (--algorithm_path)
      ALGORITHM_PATH=$1;
      shift;;
    (--algorithm_test_suite_file_path)
      ALGORITHM_TEST_SUITE_FILE_PATH=$1;
      shift;;
    (--mutation_operator)
      MUTATION_OPERATOR=$1;
      shift;;
    (--report_output_file)
      REPORT_OUTPUT_FILE=$1;
      shift;;
    (--help)
      echo "$USAGE"
      exit 0
    (*)
      die "$USAGE";;
  esac
done

# Check whether all mandatory arguments have been used
[ "$QUANTUM_FRAMEWORK_NAME" != "" ]         || die "[ERROR] Missing --quantum_framework_name argument!"
[ "$QUANTUM_FRAMEWORK_ROOT_PATH" != "" ]    || die "[ERROR] Missing --quantum_framework_root_path argument!"
[ "$PYENV_NAME" != "" ]                     || die "[ERROR] Missing --pyenv_name argument!"
[ "$ALGORITHM_NAME" != "" ]                 || die "[ERROR] Missing --algorithm_name argument!"
[ "$ALGORITHM_PATH" != "" ]                 || die "[ERROR] Missing --algorithm_path argument!"
[ "$ALGORITHM_TEST_SUITE_FILE_PATH" != "" ] || die "[ERROR] Missing --algorithm_test_suite_file_path argument!"
[ "$MUTATION_OPERATOR" != "" ]              || die "[ERROR] Missing --mutation_operator argument!"
[ "$REPORT_OUTPUT_FILE" != "" ]             || die "[ERROR] Missing --report_output_file argument!"

# Check whether QUANTUM_FRAMEWORK_ROOT_PATH exits
[ -d "$QUANTUM_FRAMEWORK_ROOT_PATH" ] || die "[ERROR] $QUANTUM_FRAMEWORK_ROOT_PATH does not exist!"

# ------------------------------------------------------------------------- Main

echo "PID: $$"
echo "Job started at $(date)"
hostname

pushd . > /dev/null 2>&1
cd "$QUANTUM_FRAMEWORK_ROOT_PATH"
  _load_pyenv "$PYENV_NAME" || die

  mut.py --target "$ALGORITHM_PATH" --unit-test "$ALGORITHM_TEST_SUITE_FILE_PATH" -m --operator "$MUTATION_OPERATOR" --report "$REPORT_OUTPUT_FILE" || die "[ERROR] Failed to run QMutPy::$MUTATION_OPERATOR on $ALGORITHM_NAME!"
  [ -s "$REPORT_OUTPUT_FILE" ] || die "[ERROR] $REPORT_OUTPUT_FILE does not exist or it is empty!"

  _unload_pyenv || die
popd > /dev/null 2>&1

echo "Job finished at $(date)"
echo "DONE!"
exit 0

# EOF
