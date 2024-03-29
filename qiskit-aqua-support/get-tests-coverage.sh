#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script measures code coverage (at line level) of each test suite in the
# Qiskit-Aqua project.  For each test suite this script generates a JSON report
# under tests-coverage/, e.g., tests-coverage/qiskit.aqua.algorithms.amplitude_amplifiers.grover.json.
# Once all test suites have been analyzed, this scripts collects all data in a
# single CSV file (tests-coverage.csv) which follows the following format:
#
#    algorithm_full_name,test_suite_full_name,number_of_tests,number_of_tests_skipped,file,statement,line,covered,excluded
#    qiskit.aqua.algorithms.amplitude_amplifiers.grover,test.aqua.test_grover,5,0,qiskit/aqua/algorithms/amplitude_amplifiers/grover.py,12,12,1,0
#    qiskit.aqua.algorithms.amplitude_amplifiers.grover,test.aqua.test_grover,5,0,qiskit/aqua/algorithms/amplitude_amplifiers/grover.py,12,13,1,0
#
# where:
# - algorithm_full_name represents the algorithm's canonical name as, e.g.,
#   qiskit.aqua.algorithms.amplitude_amplifiers.grover
# - test_suite_full_name represents the algorithm's test suite canonical name as,
#   e.g., test.aqua.test_grover
# - number_of_tests represents the number of test cases executed during code
#   coverage analysis
# - number_of_tests_skipped represents the number of test cases excluded by the
# test framework
# - file represents the file for which coverage was collected, e.g.,
#   qiskit/aqua/algorithms/amplitude_amplifiers/grover.py
# - statement represent a statement code which might be include several lines of
#   code
# - line represented the line number of a line of code
# - covered is either 1 if a line was exercised by the test suite, 0 otherwise
# - excluded is either 1 if a line was excluded from coverage report, 0 otherwise
#
# Usage:
# get-tests-coverage.sh
#
# Requirements:
#   Execution of tools/get-tools.sh script.
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/../experiments/utils.sh" || exit 1

# ------------------------------------------------------------------------- Args

QUANTUM_FRAMEWORK_ROOT_PATH="$SCRIPT_DIR/../tools/qiskit-aqua"
# Check whether QUANTUM_FRAMEWORK_ROOT_PATH exits
[ -d "$QUANTUM_FRAMEWORK_ROOT_PATH" ] || die "[ERROR] $QUANTUM_FRAMEWORK_ROOT_PATH does not exist!"

QUANTUM_SUBJECTS_FILE_PATH="$SCRIPT_DIR/subjects.csv"
# Check whether QUANTUM_SUBJECTS_FILE_PATH exits
[ -s "$QUANTUM_SUBJECTS_FILE_PATH" ] || die "[ERROR] $QUANTUM_SUBJECTS_FILE_PATH does not exist or it is empty!"

COVERAGE_DIR="$SCRIPT_DIR/tests-coverage-data"
mkdir -p "$COVERAGE_DIR"
# Check whether COVERAGE_DIR exits
[ -d "$COVERAGE_DIR" ] || die "[ERROR] $COVERAGE_DIR does not exist!"

TEST_COVERAGE_CSV="$SCRIPT_DIR/tests-coverage.csv"
rm -f "$TEST_COVERAGE_CSV"

# ------------------------------------------------------------------------- Main

echo "PID: $$"
echo "Job started at $(date)"
hostname

while read -r subject_row; do
  # algorithm_name,algorithm_full_name,test_suite_full_name
  # grover,qiskit.aqua.algorithms.amplitude_amplifiers.grover,test.aqua.test_grover

  algorithm_full_name=$(echo "$subject_row" | cut -f2 -d',')
  algorithm_test_suite_full_name=$(echo "$subject_row" | cut -f3 -d',')
  json_cov_file="$COVERAGE_DIR/$algorithm_full_name.json"
  csv_cov_file="$COVERAGE_DIR/$algorithm_full_name.csv"

  run_coverage "$QUANTUM_FRAMEWORK_ROOT_PATH" \
    "$algorithm_full_name" \
    "$algorithm_test_suite_full_name" \
    "$json_cov_file" \
    "$csv_cov_file" \
    "$COVERAGE_DIR/$algorithm_full_name-run.log" || die

  # Collect data in a single CSV
  if [ ! -f "$TEST_COVERAGE_CSV" ]; then # header
    head -n1 "$csv_cov_file" | sed 's|^|algorithm_full_name,test_suite_full_name,number_of_tests,number_of_tests_skipped,|g' > "$TEST_COVERAGE_CSV" || die "[ERROR] Failed to create $TEST_COVERAGE_CSV!"
  fi
  tail -n +2 "$csv_cov_file" | sed "s|^|$algorithm_full_name,$algorithm_test_suite_full_name,$number_of_tests,$number_of_tests_skipped,|g" >> "$TEST_COVERAGE_CSV" || die "[ERROR] Failed to populate $TEST_COVERAGE_CSV!"

done < <(tail -n +2 "$QUANTUM_SUBJECTS_FILE_PATH")

echo "Job finished at $(date)"
echo "DONE!"
exit 0

# EOF
