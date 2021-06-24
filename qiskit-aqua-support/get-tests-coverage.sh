#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script measures code coverage (at line level) of each test suite in the
# Qiskit-Aqua project.  For each test suite this script generates a JSON report
# under tests-coverage/, e.g., tests-coverage/qiskit.aqua.algorithms.amplitude_amplifiers.grover.json.
# Once all test suites have been analyzed, this scripts collects all data in a
# single CSV file (tests-coverage.csv) which follows the following format:
#
#    algorithm_full_name,test_suite_full_name,number_of_tests,file,statement,line,covered,excluded
#    qiskit.aqua.algorithms.amplitude_amplifiers.grover,test.aqua.test_grover,qiskit/aqua/algorithms/amplitude_amplifiers/grover.py,5,12,12,1,0
#    qiskit.aqua.algorithms.amplitude_amplifiers.grover,test.aqua.test_grover,qiskit/aqua/algorithms/amplitude_amplifiers/grover.py,5,12,13,1,0
#
# where:
# - algorithm_full_name represents the algorithm's canonical name as, e.g.,
#   qiskit.aqua.algorithms.amplitude_amplifiers.grover
# - test_suite_full_name represents the algorithm's test suite canonical name as,
#   e.g., test.aqua.test_grover
# - number_of_tests represents the number of test cases executed during code
#   coverage analysis
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

SCRIPT_DIR=$(cd `dirname $0` && pwd)
source "$SCRIPT_DIR/../experiments/utils.sh" || exit 1

# ------------------------------------------------------------------------- Args

QUANTUM_FRAMEWORK_ROOT_PATH="$SCRIPT_DIR/../tools/qiskit-aqua"
# Check whether QUANTUM_FRAMEWORK_ROOT_PATH exits
[ -d "$QUANTUM_FRAMEWORK_ROOT_PATH" ] || die "[ERROR] $QUANTUM_FRAMEWORK_ROOT_PATH does not exist!"

QUANTUM_SUBJECTS_FILE_PATH="$SCRIPT_DIR/subjects.csv"
# Check whether QUANTUM_SUBJECTS_FILE_PATH exits
[ -s "$QUANTUM_SUBJECTS_FILE_PATH" ] || die "[ERROR] $QUANTUM_SUBJECTS_FILE_PATH does not exist or it is empty!"

COVERAGE_DIR="$SCRIPT_DIR/tests-coverage"
# Check whether COVERAGE_DIR exits
[ -d "$COVERAGE_DIR" ] || die "[ERROR] $COVERAGE_DIR does not exist!"

JSON_TO_CSV_SCRIPT="$COVERAGE_DIR/json2csv.py"
# Check whether JSON_TO_CSV_SCRIPT exits
[ -s "$JSON_TO_CSV_SCRIPT" ] || die "[ERROR] $JSON_TO_CSV_SCRIPT does not exist!"

TEST_COVERAGE_CSV="$SCRIPT_DIR/tests-coverage.csv"
rm -f "$TEST_COVERAGE_CSV"

# ------------------------------------------------------------------------- Main

echo "PID: $$"
echo "Job started at $(date)"
hostname

pushd . > /dev/null 2>&1
cd "$QUANTUM_FRAMEWORK_ROOT_PATH"
  _activate_virtual_environment || die

  while read -r subject_row; do
    # algorithm_name,algorithm_full_name,test_suite_full_name
    # grover,qiskit.aqua.algorithms.amplitude_amplifiers.grover,test.aqua.test_grover

    algorithm_full_name=$(echo "$subject_row" | cut -f2 -d',')
    algorithm_test_suite_full_name=$(echo "$subject_row" | cut -f3 -d',')
    json_cov_file="$COVERAGE_DIR/$algorithm_full_name.json"
    csv_cov_file="$COVERAGE_DIR/$algorithm_full_name.csv"

    # Remove any previously collected coverage
    rm -f "$json_cov_file" "$csv_cov_file" ".coverage"

    # Run test suite and collect coverage
    run_log_file="$COVERAGE_DIR/$algorithm_full_name-run.log"
    coverage run --source="$algorithm_full_name" -m unittest "$algorithm_test_suite_full_name" > "$run_log_file" 2>&1; run_exit_code="$?"; cat "$run_log_file"
    [ "$run_exit_code" -eq "0" ] || die "[ERROR] Failed to collect $algorithm_full_name coverage!"
    [ -s ".coverage" ] || die "[ERROR] .coverage does not exist or it is empty!"

    # Collect number of tests executed during code-coverage analysis
    number_of_tests=$(grep -E "^Ran [0-9]+ test[s]? in " "$run_log_file" | cut -f2 -d' ')
    [ "$?" -eq "0" ] || die "[ERROR] Failed to collect number of tests executed!"
    [ "$number_of_tests" != "" ] || die "[ERROR] number of tests executed cannot be empty!"

    # Print to stdout the coverage collected
    coverage report -m "$(echo $algorithm_full_name | tr '.' '/').py" || die "[ERROR] Failed to run coverage report for $algorithm_full_name!"

    # Print to a JSON file the coverage collected
    coverage json -o "$json_cov_file" --pretty-print --include="$(echo $algorithm_full_name | tr '.' '/').py" || die "[ERROR] Failed to print to JSON file the coverage collected for $algorithm_full_name!"
    [ -s "$json_cov_file" ] || die "[ERROR] $json_cov_file does not exist or it is empty!"

    # Convert the auto generated JSON to CSV
    python "$JSON_TO_CSV_SCRIPT" "$json_cov_file" "$csv_cov_file" || die "[ERROR] Failed to convert $json_cov_file into $csv_cov_file!"

    # Collect data in a single CSV
    if [ ! -f "$TEST_COVERAGE_CSV" ]; then # header
      head -n1 "$csv_cov_file" | sed 's|^|algorithm_full_name,test_suite_full_name,number_of_tests,|g' > "$TEST_COVERAGE_CSV" || die "[ERROR] Failed to create $TEST_COVERAGE_CSV!"
    fi
    tail -n +2 "$csv_cov_file" | sed "s|^|$algorithm_full_name,$algorithm_test_suite_full_name,$number_of_tests,|g" >> "$TEST_COVERAGE_CSV" || die "[ERROR] Failed to populate $TEST_COVERAGE_CSV!"
  done < <(tail -n +2 "$QUANTUM_SUBJECTS_FILE_PATH")

  _deactivate_virtual_environment || die
popd > /dev/null 2>&1

echo "Job finished at $(date)"
echo "DONE!"
exit 0

# EOF
