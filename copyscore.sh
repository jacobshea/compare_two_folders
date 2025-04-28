#!/usr/bin/env bash
# CopyScore — quantify code copy‑paste between two repos (Original vs Suspect)
# v0.4.2 – replaces regex extension filter with POSIX glob matching (Bash 3.2‑safe).
# Default: scan **all** text files; use -e to narrow by extension.
# No external dependencies beyond macOS/BSD coreutils.

# ------------------------------------------------------------------
# Defaults
# ------------------------------------------------------------------
DEFAULT_EXTS=""    # blank ⇒ compare all text; e.g. "js,ts,vue" to preset.
EXT_LIST="$DEFAULT_EXTS"
THRESHOLD=0
CSV_FILE=""
JSON_FILE=""

# Pre‑declare arrays before set -u
declare -a IGNORE_PATHS=()

auth_set_strict() {
  set -euo pipefail
  IFS=$' \t\n'
}
auth_set_strict

# ------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: copyscore.sh [options] ORIGINAL_DIR SUSPECT_DIR

Options:
  -t PERCENT     Minimum similarity to report (0‑100; default 0)
  -o FILE.csv    Output per‑file CSV (must end with .csv)
  -j FILE.json   Output per‑file JSON (must end with .json)
  -x PATH        Ignore files/dirs whose relative path starts with PATH (repeatable)
  -e ext1,ext2   Comma‑separated extensions to include; empty string → all‑text
  -h             Show help

Examples:
  # Out‑of‑the‑box: scans all text
  copyscore.sh repoA repoB

  # Only TypeScript + Vue (glob match .ts .vue)
  copyscore.sh -e ts,vue repoA repoB
EOF
  exit 1
}

# ------------------------------------------------------------------
# Parse flags
# ------------------------------------------------------------------
while getopts "t:o:j:x:e:h" opt; do
  case $opt in
    t) THRESHOLD=${OPTARG} ;;
    o) CSV_FILE=${OPTARG} ;;
    j) JSON_FILE=${OPTARG} ;;
    x) IGNORE_PATHS+=("${OPTARG%%/}") ;;
    e) EXT_LIST=${OPTARG} ;;
    h|*) usage ;;
  esac
done
shift $((OPTIND-1))

[[ $# -ne 2 ]] && usage
ORIGINAL=$1
SUSPECT=$2

[[ ! -d $ORIGINAL ]] && { echo "[ERROR] ORIGINAL dir '$ORIGINAL' not found" >&2; exit 1; }
[[ ! -d $SUSPECT  ]] && { echo "[ERROR] SUSPECT dir '$SUSPECT' not found"  >&2; exit 1; }

if ! [[ $THRESHOLD =~ ^[0-9]+$ ]] || (( THRESHOLD < 0 || THRESHOLD > 100 )); then
  echo "[ERROR] Threshold must be 0‑100" >&2; exit 1; fi

[[ -n $CSV_FILE  && ! $CSV_FILE  =~ \\.csv$  ]] && { echo "[ERROR] CSV file must end with .csv" >&2;  exit 1; }
[[ -n $JSON_FILE && ! $JSON_FILE =~ \\.json$ ]] && { echo "[ERROR] JSON file must end with .json" >&2; exit 1; }

[[ -n $CSV_FILE  ]] && echo "file,similarity_percent" > "$CSV_FILE"
[[ -n $JSON_FILE ]] && echo "[" > "$JSON_FILE" && JSON_COMMA=""

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
if [[ -t 1 ]]; then GRN="\033[32m"; YLW="\033[33m"; RED="\033[31m"; NC="\033[0m"; else GRN=""; YLW=""; RED=""; NC=""; fi
colorize() { local p=$1; ((p>=90)) && echo -e "${GRN}${p}%${NC}" || { ((p>=50)) && echo -e "${YLW}${p}%${NC}" || echo -e "${RED}${p}%${NC}"; }; }

is_ignored() {
  [[ ${#IGNORE_PATHS[@]} -eq 0 ]] && return 1
  local rel=$1
  for ig in "${IGNORE_PATHS[@]}"; do case $rel in ${ig}/*|${ig}) return 0;; esac; done
  return 1
}

is_text() { file -b --mime "$1" | grep -q '^text/'; }

IFS=',' read -r -a EXT_ARR <<< "$EXT_LIST"
COMPARE_ALL=false
[[ -z $EXT_LIST ]] && COMPARE_ALL=true

match_ext() {
  # $1 = relative path; returns 0 (match) / 1 (no match)
  local rel=$1 ext
  for ext in "${EXT_ARR[@]}"; do
    [[ -z $ext ]] && continue
    case $rel in *."$ext") return 0;; esac
  done
  return 1
}

printf 'Comparing folders:\n  Original: %s\n  Suspect:  %s\n\n' "$ORIGINAL" "$SUSPECT"
printf 'File‑by‑file comparison:\n------------------------\n'

# ------------------------------------------------------------------
# Collect candidate files
# ------------------------------------------------------------------
ORIGINAL_FILES=()
while IFS= read -r path; do
  rel=${path#"$ORIGINAL/"}
  is_ignored "$rel" && continue
  if $COMPARE_ALL; then
    is_text "$path" || continue
  else
    match_ext "$rel" || continue
  fi
  ORIGINAL_FILES+=("$rel")
done < <(find "$ORIGINAL" -type f)

if [[ ${#ORIGINAL_FILES[@]} -eq 0 ]]; then
  MODE_DESC=$([[ $COMPARE_ALL == true ]] && echo "all‑text" || echo "extensions: ${EXT_LIST:-<none>}")
  echo "[ERROR] No candidate files found in '$ORIGINAL'.\n  ‣ Mode: $MODE_DESC" >&2; exit 1; fi

# ------------------------------------------------------------------
# Main loop
# ------------------------------------------------------------------
TOTAL_MATCH=0; TOTAL_ORIG=0; COUNT=0; SUM_PCT=0
for rel in "${ORIGINAL_FILES[@]}"; do
  O_FILE="$ORIGINAL/$rel"; S_FILE="$SUSPECT/$rel"; [[ ! -f $S_FILE ]] && continue
  t1=$(mktemp); t2=$(mktemp)
  sed 's/[[:space:]]\\+$//' "$O_FILE" | awk '{print}' | sort > "$t1"
  sed 's/[[:space:]]\\+$//' "$S_FILE" | awk '{print}' | sort > "$t2"
  LINES=$(wc -l < "$t1"); SHARED=$(comm -12 "$t1" "$t2" | wc -l); rm -f "$t1" "$t2"
  ((LINES==0)) && continue
  PCT=$(( SHARED*100 / LINES )); ((PCT<THRESHOLD)) && continue
  printf '%s → %s\n' "$rel" "$(colorize $PCT)"
  [[ -n $CSV_FILE ]]  && echo "$rel,$PCT" >> "$CSV_FILE"
  if [[ -n $JSON_FILE ]]; then printf '%s{"file":"%s","similarity":%d}' "$JSON_COMMA" "$rel" "$PCT" >> "$JSON_FILE"; JSON_COMMA=","; fi
  TOTAL_MATCH=$((TOTAL_MATCH+SHARED)); TOTAL_ORIG=$((TOTAL_ORIG+LINES)); SUM_PCT=$((SUM_PCT+PCT)); COUNT=$((COUNT+1))
done

printf '\nSummary:\n---------\n'
if ((COUNT==0)); then echo "No files met the similarity threshold of ${THRESHOLD}%"; [[ -n $JSON_FILE ]] && echo "]" >> "$JSON_FILE"; exit 0; fi
AVG=$((SUM_PCT/COUNT)); WEIGHTED=$((TOTAL_MATCH*100/TOTAL_ORIG))
printf 'Average file similarity: %s\n' "$(colorize $AVG)"; printf 'Line‑weighted similarity: %s\n' "$(colorize $WEIGHTED)"
[[ -n $CSV_FILE ]] && echo "\nDetailed CSV written to $CSV_FILE"; [[ -n $JSON_FILE ]] && echo "]" >> "$JSON_FILE" && echo "Detailed JSON written to $JSON_FILE"
