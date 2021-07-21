#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script perform an exploratory experiment to study whether code coverage
# can be improved and therefore increase the mutation score.
#
# Usage:
# run-exp.sh
#   [--quantum_framework_root_path <path, e.g., $(pwd)/../../tools/qiskit-aqua/>]
#   [--pyenv_root_path <path, e.g., $(pwd)/../../tools/pyenv/>]
#   [help]
#
# Requirements:
#   Execution of tools/get-tools.sh script.
# ------------------------------------------------------------------------------

SCRIPT_DIR=$(cd `dirname $0` && pwd)
source "$SCRIPT_DIR/../../experiments/utils.sh" || exit 1

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} [--quantum_framework_root_path <path, e.g., \$(pwd)/../../tools/qiskit-aqua/>] [--pyenv_root_path <path, e.g., \$(pwd)/../../tools/pyenv/>] [help]"
if [ "$#" -ne "0" ] && [ "$#" -ne "1" ] && [ "$#" -ne "2" ] && [ "$#" -ne "4" ]; then
  die "$USAGE"
fi

QUANTUM_FRAMEWORK_ROOT_PATH="$(pwd)/../../tools/qiskit-aqua"
PYENV_ROOT_PATH="$(pwd)/../../tools/pyenv"

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--quantum_framework_root_path)
      QUANTUM_FRAMEWORK_ROOT_PATH=$1;
      shift;;
    (--pyenv_root_path)
      PYENV_ROOT_PATH=$1;
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

# From relative to full paths
QUANTUM_FRAMEWORK_ROOT_PATH=$(cd "$QUANTUM_FRAMEWORK_ROOT_PATH" && pwd)
PYENV_ROOT_PATH=$(cd "$PYENV_ROOT_PATH" && pwd)

# Check whether QUANTUM_FRAMEWORK_ROOT_PATH exits
[ -d "$QUANTUM_FRAMEWORK_ROOT_PATH" ] || die "[ERROR] $QUANTUM_FRAMEWORK_ROOT_PATH does not exist!"
# Check whether PYENV_ROOT_PATH exits
[ -d "$PYENV_ROOT_PATH" ]             || die "[ERROR] $PYENV_ROOT_PATH does not exist!"

# Directory to which any data will be written by this script
DATA_OUTPUT_DIR="$SCRIPT_DIR/data"
mkdir -p "$DATA_OUTPUT_DIR" || die "[ERROR] Failed to create $DATA_OUTPUT_DIR!"

# Directory with code coverage collected by $(pwd)/../../qiskit-aqua-support/get-tests-coverage.sh script
TEST_COVERAGE_DATA_DIR="$SCRIPT_DIR/../../qiskit-aqua-support/tests-coverage-data"
# Check whether TEST_COVERAGE_DATA_DIR exits
[ -d "$TEST_COVERAGE_DATA_DIR" ] || die "[ERROR] $TEST_COVERAGE_DATA_DIR does not exist!"

PATCH="$SCRIPT_DIR/non-covered-to-covered-code.patch"
# Check whether PATCH exits
[ -s "$PATCH" ] || die "[ERROR] $PATCH does not exist!"

# ------------------------------------------------------------------------- Util

#
# Collect code coverage and run mutation analysis on an augmented test suite,
# and check whether:
#   - A line of code not covered by the original test suite is covered by the
#     augmented test suite.
#   - A mutant injected in the same line of code, and not killed by the original
#     test suite, is killed by the augmented test suite.
#
run_analysis() {
  local USAGE="Usage: ${FUNCNAME[0]} algorithm_name <name, e.g., shor> algorithm_full_name <path, e.g., qiskit.aqua.algorithms.factorizers.shor> algorithm_test_suite_full_name <path, e.g., test.aqua.test_shor> mutation_operator <name, e.g., QGD> line_number <e.g., 242>"
  if [ "$#" != 5 ] ; then
    echo "$USAGE" >&2
    return 1
  fi

  algorithm_name="$1"
  algorithm_full_name="$2"
  algorithm_test_suite_full_name="$3"
  mutation_operator="$4"
  line_number="$5"

  # Collect coverage
  coverage_json_file="$DATA_OUTPUT_DIR/$algorithm_full_name.json"
   coverage_csv_file="$DATA_OUTPUT_DIR/$algorithm_full_name.csv"
   coverage_log_file="$DATA_OUTPUT_DIR/$algorithm_full_name-run.log"
  run_coverage "$QUANTUM_FRAMEWORK_TMP_DIR" \
    "$algorithm_full_name" \
    "$algorithm_test_suite_full_name" \
    "$coverage_json_file" \
    "$coverage_csv_file" \
    "$coverage_log_file" || die "[ERROR] Failed to collect coverage of $algorithm_test_suite_full_name!"

  # Check whether lines of code exercised by the original test suite are also
  # exercised by the augmented test suite
  [ -s "$TEST_COVERAGE_DATA_DIR/$algorithm_full_name.csv" ] || die "[ERROR] $TEST_COVERAGE_DATA_DIR/$algorithm_full_name.csv does not exist or it is empty!"
  while read -r row; do
    grep "^$row$" "$coverage_csv_file" || die "[ERROR] $row does not occur in $coverage_csv_file!"
  done < <(grep ",1,0$" "$TEST_COVERAGE_DATA_DIR/$algorithm_full_name.csv")

  # Check whether the lines of code (of interest and not exercised by the original
  # test suite) are exercised by the augmented test suite
  grep "^$(echo $algorithm_full_name | sed 's|\.|/|g').py,$line_number,$line_number,1,0$" "$coverage_csv_file" || die "[ERROR] Line of number $line_number is neither executed by the augmented test suite!"

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

  # Check whether specific line(s) have been exercised and that all survived
  # mutants are indeed exercised by the augmented test suite
  grep ",$line_number,$mutation_operator,killed," "$csv_report_output_file" || die "[ERROR] $mutation_operator mutant injected in line $line_number is not killed by the augmented test suite!"

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

# Debug # TODO remove me
cat "$QUANTUM_FRAMEWORK_TMP_DIR/env/lib/python3.7/site-packages/setuptools.pth" || die
cat "$QUANTUM_FRAMEWORK_TMP_DIR/env/pyvenv.cfg" || die

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
# Case 1
# https://github.com/Qiskit/qiskit-aqua/blob/stable/0.9/qiskit/aqua/algorithms/linear_solvers/hhl.py#L232
#
# 228        # Measurement of the ancilla qubit
# 229        if measurement:
# 230            c = ClassicalRegister(1)
# 231            qc.add_register(c)
# 232 -          qc.measure(s, c)
# 232 +          pass
# 233            self._success_bit = c
# 234
# 235        self._io_register = q
#
run_analysis \
  "hhl" \
  "qiskit.aqua.algorithms.linear_solvers.hhl" \
  "test.aqua.test_hhl" \
  "QMD" \
  "232" || die

#
# Case 2
# https://github.com/Qiskit/qiskit-aqua/blob/stable/0.9/qiskit/aqua/algorithms/classifiers/vqc.py#L544
#
# 540            c = ClassicalRegister(qc.width(), name='c')
# 541            q = find_regs_by_name(qc, 'q')
# 542            qc.add_register(c)
# 543            qc.barrier(q)
# 544 -          qc.measure(q, c)
# 544 +          pass
# 545            ret = self._quantum_instance.execute(qc)
# 546            self._ret['min_vector'] = ret.get_counts(qc)
#
run_analysis \
  "vqc" \
  "qiskit.aqua.algorithms.classifiers.vqc" \
  "test.aqua.test_vqc" \
  "QMD" \
  "544" || die

# Clean up
rm -rf "$TMP_DIR"

echo "Job finished at $(date)"
echo "DONE!"
exit 0

# EOF
