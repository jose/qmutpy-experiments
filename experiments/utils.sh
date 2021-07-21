#!/usr/bin/env bash

UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
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
# Init [Simple Python Version Management: pyenv](https://github.com/pyenv/pyenv).
#
_init_pyenv() {
  export PYENV_ROOT="$UTILS_SCRIPT_DIR/../tools/pyenv"
  [ -d "$PYENV_ROOT" ] || die "[ERROR] $PYENV_ROOT does not exist!"
  export PATH="$PYENV_ROOT/bin:$PATH"

  # Check whether `pyenv` is available
  pyenv --version > /dev/null 2>&1 || die "[ERROR] Could not find 'pyenv'!"

  # Init it
  eval "$(pyenv init --path)" || die "[ERROR] Failed to init pyenv!"

  return 0
}

#
# Activate virtual environment.
#
_activate_virtual_environment() {
  local USAGE="Usage: ${FUNCNAME[0]}"
  if [ "$#" != 0 ] ; then
    echo "$USAGE" >&2
    return 1
  fi

  source env/bin/activate || die "[ERROR] Failed to activate virtual environment!"
  python --version >&2

  return 0
}

#
# Deactivate virtual environment.
#
_deactivate_virtual_environment() {
  local USAGE="Usage: ${FUNCNAME[0]}"
  if [ "$#" != 0 ] ; then
    echo "$USAGE" >&2
    return 1
  fi

  deactivate || die "[ERROR] Failed to deactivate virtual environment!"

  return 0
}

#
# Run a quantum test suite of a quantum algorithm and collect its coverage.
#
run_coverage() {
  local USAGE="Usage: ${FUNCNAME[0]} <quantum_framework_root_path> <algorithm_full_name> <algorithm_test_suite_full_name> <json_output_file> <csv_output_file> <log_file>"
  if [ "$#" != 6 ] ; then
    echo "$USAGE" >&2
    return 1
  fi

  # Check environment variables
  JSON_TO_CSV_SCRIPT="$UTILS_SCRIPT_DIR/../qiskit-aqua-support/utils/json2csv.py"
  # Check whether JSON_TO_CSV_SCRIPT exits
  [ -s "$JSON_TO_CSV_SCRIPT" ] || die "[ERROR] $JSON_TO_CSV_SCRIPT does not exist!"

  # Get arguments
  quantum_framework_root_path="$1"
  algorithm_full_name="$2"
  algorithm_test_suite_full_name="$3"
  json_cov_file="$4"
  csv_cov_file="$5"
  run_log_file="$6"

  pushd . > /dev/null 2>&1
  cd "$quantum_framework_root_path"
    _activate_virtual_environment || die

    # Remove any previously collected coverage
    rm -f "$json_cov_file" "$csv_cov_file" "$run_log_file" ".coverage" >&2

    # Run test suite and collect coverage
    coverage run --source="$algorithm_full_name" -m unittest "$algorithm_test_suite_full_name" > "$run_log_file" 2>&1; run_exit_code="$?"; cat "$run_log_file" >&2
    [ "$run_exit_code" -eq "0" ] || die "[ERROR] Failed to collect $algorithm_full_name coverage!"
    [ -s ".coverage" ] || die "[ERROR] .coverage does not exist or it is empty!"

    # Collect number of tests executed during code-coverage analysis
    number_of_tests=$(grep -E "^Ran [0-9]+ test[s]? in " "$run_log_file" | cut -f2 -d' ')
    [ "$?" -eq "0" ] || die "[ERROR] Failed to collect number of tests executed!"
    [ "$number_of_tests" != "" ] || die "[ERROR] number of tests executed cannot be empty!"

    # Collect number of skipped tests
    number_of_tests_skipped=0
    if grep -Eq "^OK \(skipped=[1-9]+\)" "$run_log_file"; then
      number_of_tests_skipped=$(grep -E "^OK \(skipped=[1-9]+\)" "$run_log_file" | cut -f2 -d'=' | cut -f1 -d')')
    fi
    [ "$number_of_tests_skipped" != "" ] || die "[ERROR] number of tests skipped cannot be empty!"

    # Print to stdout the coverage collected
    coverage report -m "$(echo $algorithm_full_name | tr '.' '/').py" >&2 || die "[ERROR] Failed to run coverage report for $algorithm_full_name!"

    # Print to a JSON file the coverage collected
    coverage json -o "$json_cov_file" --pretty-print --include="$(echo $algorithm_full_name | tr '.' '/').py" >&2 || die "[ERROR] Failed to print to JSON file the coverage collected for $algorithm_full_name!"
    [ -s "$json_cov_file" ] || die "[ERROR] $json_cov_file does not exist or it is empty!"

    # Convert the auto generated JSON to CSV
    python "$JSON_TO_CSV_SCRIPT" "$json_cov_file" "$csv_cov_file" >&2 || die "[ERROR] Failed to convert $json_cov_file into $csv_cov_file!"

    _deactivate_virtual_environment || die
  popd > /dev/null 2>&1

  return 0
}

# EOF
