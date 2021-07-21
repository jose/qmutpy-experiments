#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script runs QMutPy on a single quantum algorithm.
#
# Usage:
# run-qmutpy.sh
#   --quantum_framework_root_path <path, e.g., $(pwd)/../tools/qiskit-aqua/>
#   --algorithm_name <name, e.g., shor>
#   --algorithm_full_name <path, e.g., qiskit.aqua.algorithms.factorizers.shor>
#   --algorithm_test_suite_full_name <path, e.g., test.aqua.test_shor>
#   --mutation_operator <name, e.g., QGD>
#   --yaml_report_output_file <path, e.g., qiskit-aqua-shor-QGD.yaml>
#   --csv_report_output_file <path, e.g., qiskit-aqua-shor-QGD.csv>
#   [help]
#
# Requirements:
#   Execution of tools/get-tools.sh script.
# ------------------------------------------------------------------------------

SCRIPT_DIR=$(cd `dirname $0` && pwd)
source "$SCRIPT_DIR/utils.sh" || exit 1

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} --quantum_framework_root_path <path, e.g., \$(pwd)/../tools/qiskit-aqua/> --algorithm_name <name, e.g., shor> --algorithm_full_name <path, e.g., qiskit.aqua.algorithms.factorizers.shor> --algorithm_test_suite_full_name <path, e.g., test.aqua.test_shor> --mutation_operator <name, e.g., QGD> --yaml_report_output_file <path, e.g., qiskit-aqua-shor-QGD.yaml> --csv_report_output_file <path, e.g., qiskit-aqua-shor-QGD.csv> [help]"
if [ "$#" -ne "1" ] && [ "$#" -ne "14" ]; then
  die "$USAGE"
fi

QUANTUM_FRAMEWORK_ROOT_PATH=""
ALGORITHM_NAME=""
ALGORITHM_FULL_NAME=""
ALGORITHM_TEST_SUITE_FULL_NAME=""
MUTATION_OPERATOR=""
YAML_REPORT_OUTPUT_FILE=""
CSV_REPORT_OUTPUT_FILE=""

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--quantum_framework_root_path)
      QUANTUM_FRAMEWORK_ROOT_PATH=$1;
      shift;;
    (--algorithm_name)
      ALGORITHM_NAME=$1;
      shift;;
    (--algorithm_full_name)
      ALGORITHM_FULL_NAME=$1;
      shift;;
    (--algorithm_test_suite_full_name)
      ALGORITHM_TEST_SUITE_FULL_NAME=$1;
      shift;;
    (--mutation_operator)
      MUTATION_OPERATOR=$1;
      shift;;
    (--yaml_report_output_file)
      YAML_REPORT_OUTPUT_FILE=$1;
      shift;;
    (--csv_report_output_file)
      CSV_REPORT_OUTPUT_FILE=$1;
      shift;;
    (--help)
      echo "$USAGE"
      exit 0
    (*)
      die "$USAGE";;
  esac
done

# Check whether all mandatory arguments have been used
[ "$QUANTUM_FRAMEWORK_ROOT_PATH" != "" ]    || die "[ERROR] Missing --quantum_framework_root_path argument!"
[ "$ALGORITHM_NAME" != "" ]                 || die "[ERROR] Missing --algorithm_name argument!"
[ "$ALGORITHM_FULL_NAME" != "" ]            || die "[ERROR] Missing --algorithm_full_name argument!"
[ "$ALGORITHM_TEST_SUITE_FULL_NAME" != "" ] || die "[ERROR] Missing --algorithm_test_suite_full_name argument!"
[ "$MUTATION_OPERATOR" != "" ]              || die "[ERROR] Missing --mutation_operator argument!"
[ "$YAML_REPORT_OUTPUT_FILE" != "" ]        || die "[ERROR] Missing --yaml_report_output_file argument!"
[ "$CSV_REPORT_OUTPUT_FILE" != "" ]         || die "[ERROR] Missing --csv_report_output_file argument!"

# Check whether QUANTUM_FRAMEWORK_ROOT_PATH exits
[ -d "$QUANTUM_FRAMEWORK_ROOT_PATH" ] || die "[ERROR] $QUANTUM_FRAMEWORK_ROOT_PATH does not exist!"

YAML_TO_CSV_SCRIPT="$SCRIPT_DIR/../qmutpy-support/utils/yaml2csv.py"
# Check whether YAML_TO_CSV_SCRIPT exits
[ -s "$YAML_TO_CSV_SCRIPT" ] || die "[ERROR] $YAML_TO_CSV_SCRIPT does not exist!"

# ------------------------------------------------------------------------- Main

echo "PID: $$"
echo "Job started at $(date)"
hostname

pushd . > /dev/null 2>&1
cd "$QUANTUM_FRAMEWORK_ROOT_PATH"
  _activate_virtual_environment || die

  # Run mutation testing
  mut.py --target "$ALGORITHM_FULL_NAME" --unit-test "$ALGORITHM_TEST_SUITE_FULL_NAME" -m --operator "$MUTATION_OPERATOR" --report "$YAML_REPORT_OUTPUT_FILE" || die "[ERROR] Failed to run QMutPy::$MUTATION_OPERATOR on $ALGORITHM_NAME!"
  [ -s "$YAML_REPORT_OUTPUT_FILE" ] || die "[ERROR] $YAML_REPORT_OUTPUT_FILE does not exist or it is empty!"

  # Convert the generated YAML to CSV
  python "$YAML_TO_CSV_SCRIPT" "$YAML_REPORT_OUTPUT_FILE" "$CSV_REPORT_OUTPUT_FILE" || die "[ERROR] Failed to convert YAML to CSV!"
  [ -s "$CSV_REPORT_OUTPUT_FILE" ] || die "[ERROR] $CSV_REPORT_OUTPUT_FILE does not exist or it is empty!"

  _deactivate_virtual_environment || die
popd > /dev/null 2>&1

echo "Job finished at $(date)"
echo "DONE!"
exit 0

# EOF
