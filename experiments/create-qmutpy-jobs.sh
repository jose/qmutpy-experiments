#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script creates a jobs file with as many calls to QMutPy as number of
# algorithms x mutation operators to consider.  The jobs file can then be used
# with [GNU-Parallel](https://www.gnu.org/software/parallel), e.g.,
#   parallel --progress -j 8 -a qiskit-aqua-jobs.txt
# to run all jobs in parallel.
#
# Usage:
# create-qmutpy-jobs.sh
#   --quantum_framework_name <name, e.g., qiskit-aqua>
#   --quantum_framework_root_path <path, e.g., $(pwd)/../tools/qiskit-aqua/>
#   --quantum_subjects_file_path <name, e.g., $(pwd)/../qiskit-aqua-support/subjects.csv>
#   --quantum_mutation_operators_file_path <name, e.g., $(pwd)/../qmutpy-support/mutation-operators.csv>
#   --report_output_dir <path, e.g., qiskit-aqua/>
#   --jobs_file_path <path, e.g., qiskit-aqua-jobs.txt>
#   [help]
#
# Requirements:
#   Execution of tools/get-tools.sh script.
# ------------------------------------------------------------------------------

SCRIPT_DIR=$(cd `dirname $0` && pwd)
source "$SCRIPT_DIR/utils.sh" || exit 1

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} --quantum_framework_name <name, e.g., qiskit-aqua> --quantum_framework_root_path <path, e.g., \$(pwd)/../tools/qiskit-aqua/> --quantum_subjects_file_path <name, e.g., \$(pwd)/../qiskit-aqua-support/subjects.csv> --quantum_mutation_operators_file_path <name, e.g., \$(pwd)/../qmutpy-support/mutation-operators.csv> --report_output_dir <path, e.g., qiskit-aqua> --jobs_file_path <path, e.g., qiskit-aqua-jobs.txt> [help]"
if [ "$#" -ne "12" ]; then
  die "$USAGE"
fi

QUANTUM_FRAMEWORK_NAME=""
QUANTUM_FRAMEWORK_ROOT_PATH=""
QUANTUM_SUBJECTS_FILE_PATH=""
QUANTUM_MUTATION_OPERATORS_FILE_PATH=""
REPORT_OUTPUT_DIR=""
JOBS_FILE_PATH=""

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--quantum_framework_name)
      QUANTUM_FRAMEWORK_NAME=$1;
      shift;;
    (--quantum_framework_root_path)
      QUANTUM_FRAMEWORK_ROOT_PATH=$1;
      shift;;
    (--quantum_subjects_file_path)
      QUANTUM_SUBJECTS_FILE_PATH=$1;
      shift;;
    (--quantum_mutation_operators_file_path)
      QUANTUM_MUTATION_OPERATORS_FILE_PATH=$1;
      shift;;
    (--report_output_dir)
      REPORT_OUTPUT_DIR=$1;
      shift;;
    (--jobs_file_path)
      JOBS_FILE_PATH=$1;
      shift;;
    (--help)
      echo "$USAGE"
      exit 0
    (*)
      die "$USAGE";;
  esac
done

# Check whether all mandatory arguments have been used
[ "$QUANTUM_FRAMEWORK_NAME" != "" ]               || die "[ERROR] Missing --quantum_framework_name argument!"
[ "$QUANTUM_FRAMEWORK_ROOT_PATH" != "" ]          || die "[ERROR] Missing --quantum_framework_root_path argument!"
[ "$QUANTUM_SUBJECTS_FILE_PATH" != "" ]           || die "[ERROR] Missing --quantum_subjects_file_path argument!"
[ "$QUANTUM_MUTATION_OPERATORS_FILE_PATH" != "" ] || die "[ERROR] Missing --quantum_mutation_operators_file_path argument!"
[ "$REPORT_OUTPUT_DIR" != "" ]                    || die "[ERROR] Missing --report_output_dir argument!"
[ "$JOBS_FILE_PATH" != "" ]                       || die "[ERROR] Missing --jobs_file_path argument!"

# Check whether QUANTUM_FRAMEWORK_ROOT_PATH exits
[ -d "$QUANTUM_FRAMEWORK_ROOT_PATH" ] || die "[ERROR] $QUANTUM_FRAMEWORK_ROOT_PATH does not exist!"
# Check whether QUANTUM_SUBJECTS_FILE_PATH exits
[ -s "$QUANTUM_SUBJECTS_FILE_PATH" ] || die "[ERROR] $QUANTUM_SUBJECTS_FILE_PATH does not exist or it is empty!"
# Check whether QUANTUM_MUTATION_OPERATORS_FILE_PATH exits
[ -s "$QUANTUM_MUTATION_OPERATORS_FILE_PATH" ] || die "[ERROR] $QUANTUM_MUTATION_OPERATORS_FILE_PATH does not exist or it is empty!"

# Create output dir
mkdir -p "$REPORT_OUTPUT_DIR" || die "[ERROR] Failed to create $REPORT_OUTPUT_DIR!"
# Create jobs file
rm -f "$JOBS_FILE_PATH"; touch "$JOBS_FILE_PATH"

# ------------------------------------------------------------------------- Main

while read -r mutation_operator_row; do
  # mutation_operator_description,mutation_operator_id
  mutation_operator_id=$(echo "$mutation_operator_row" | cut -f2 -d',')

  while read -r subject_row; do
    # algorithm_name,algorithm_full_name,test_suite_full_name
    algorithm_name=$(echo "$subject_row" | cut -f1 -d',')
    algorithm_full_name=$(echo "$subject_row" | cut -f2 -d',')
    algorithm_test_suite_full_name=$(echo "$subject_row" | cut -f3 -d',')

    exp_dir="$REPORT_OUTPUT_DIR/$QUANTUM_FRAMEWORK_NAME/$algorithm_name/$mutation_operator_id"
    mkdir -p "$exp_dir" || die "[ERROR] Failed to create $exp_dir!"

    report_file="$exp_dir/data.yaml"
    log_file="$exp_dir/log.txt"
    echo "QUANTUM_FRAMEWORK_NAME: $QUANTUM_FRAMEWORK_NAME"                  > "$log_file"
    echo "ALGORITHM_FULL_NAME: $algorithm_full_name"                       >> "$log_file"
    echo "ALGORITHM_TEST_SUITE_FULL_NAME: $algorithm_test_suite_full_name" >> "$log_file"
    echo "MUTATION_OPERATOR_ID: $mutation_operator_id"                     >> "$log_file"

    echo "bash \"$SCRIPT_DIR/run-qmutpy.sh\" \
          --quantum_framework_name \"$QUANTUM_FRAMEWORK_NAME\" \
          --quantum_framework_root_path \"$QUANTUM_FRAMEWORK_ROOT_PATH\" \
          --algorithm_name \"$algorithm_name\" \
          --algorithm_full_name \"$algorithm_full_name\" \
          --algorithm_test_suite_full_name \"$algorithm_test_suite_full_name\" \
          --mutation_operator \"$mutation_operator_id\" \
          --report_output_file \"$report_file\" >> \"$log_file\" 2>&1" >> "$JOBS_FILE_PATH"

  done < <(tail -n +2 "$QUANTUM_SUBJECTS_FILE_PATH")
done < <(tail -n +2 "$QUANTUM_MUTATION_OPERATORS_FILE_PATH")

echo "All jobs have been created! To now run jobs in parallel execute the following command:"
echo "nohup parallel --progress -j \$(cat /proc/cpuinfo | grep 'cpu cores' | sort -u | cut -f2 -d':' | cut -f2 -d' ') -a $JOBS_FILE_PATH > $JOBS_FILE_PATH-gnu-parallel-jobs.txt.log 2>&1 &"

echo "DONE!"
exit 0

# EOF
