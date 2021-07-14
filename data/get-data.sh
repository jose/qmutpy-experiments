#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script collects all YAML files generated by the experimental scripts
# (i.e., QMutPy) and stores it in a single CSV file.
#
# Usage:
# get-data.sh
#   --output_file <path>
#   --exps_dirs <path, for more than one use ','>
#   [help]
#
# ------------------------------------------------------------------------------

SCRIPT_DIR=$(cd `dirname $0` && pwd)
source "$SCRIPT_DIR/../experiments/utils.sh" || exit 1

# ------------------------------------------------------------------------- Args

USAGE="Usage: $0 --output_file <path> --exps_dirs <path, for more than one use ','> [help]"
if [ "$#" -ne "1" ] && [ "$#" -ne "4" ]; then
  die "$USAGE"
fi

OUTPUT_FILE=""
EXPS_DIRS=""

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--output_file)
      OUTPUT_FILE=$1;
      shift;;
    (--exps_dirs)
      EXPS_DIRS=$1;
      shift;;
    (--help)
      echo "$USAGE"
      exit 0
    (*)
      die "$USAGE";;
  esac
done

# Check whether all mandatory arguments have been used
[ "$OUTPUT_FILE" != "" ] || die "[ERROR] Missing --output_file argument!"
[ "$EXPS_DIRS" != "" ]   || die "[ERROR] Missing --exps_dirs argument!"

rm -f "$OUTPUT_FILE"

# ------------------------------------------------------------------------- Main

for exps_dir in $(echo "$EXPS_DIRS" | tr ',' '\n'); do
  [ -d "$exps_dir" ] || die "[ERROR] $exps_dir does not exist!"

  find "$exps_dir" -type f -name "*.yaml" | while read yaml_file; do
    csv_file=$(echo "$yaml_file" | sed 's|.yaml$|.csv|')
    rm -f "$csv_file"
    python "$SCRIPT_DIR/yaml2csv.py" "$yaml_file" "$csv_file" || die "[ERROR] Failed to convert $yaml_file into CSV!"
    [ -s "$csv_file" ] || die "[ERROR] $csv_file does not exist or it is empty!"

    if [ ! -f "$OUTPUT_FILE" ]; then
      cat "$csv_file" > "$OUTPUT_FILE" || die "[ERROR] Failed to create '$OUTPUT_FILE'!"
    else
      tail -n +2 "$csv_file" >> "$OUTPUT_FILE"
    fi
  done
done

echo "DONE!"
exit 0

# EOF
