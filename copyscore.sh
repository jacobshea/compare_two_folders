#!/bin/bash
# Usage: ./copyscore.sh /path/to/folderA /path/to/folderB

FOLDER_A="$1"
FOLDER_B="$2"

if [ -z "$FOLDER_A" ] || [ -z "$FOLDER_B" ]; then
  echo "Usage: $0 /path/to/folderA /path/to/folderB"
  exit 1
fi

echo "Comparing folders:"
echo "  Original: $FOLDER_A"
echo "  Suspect:  $FOLDER_B"
echo ""

# Add / remove extensions as needed (regex OR-list, no spaces)
EXTENSIONS="\.ts$|\.js$|\.tsx$|\.jsx$|\.json$|\.html$|\.css$|\.md$|\.yaml$|\.yml$"

TOTAL_LINES=0
MATCHED_LINES=0
MATCHED_FILES=0
TOTAL_PERCENT_SUM=0

echo "File-by-file comparison:"
echo "------------------------"

# --- the critical change: NO pipeline – use process substitution ----
while IFS= read -r fileA; do
  REL_PATH="${fileA#$FOLDER_A/}"
  fileB="${FOLDER_B}/${REL_PATH}"

  if [ -f "$fileB" ]; then
    MATCHED_FILES=$((MATCHED_FILES + 1))

    # Normalise: trim leading/trailing whitespace, sort lines
    normA=$(mktemp); normB=$(mktemp)
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' "$fileA" | sort >"$normA"
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' "$fileB" | sort >"$normB"

    linesA=$(wc -l <"$normA"); linesA=${linesA:-0}
    TOTAL_LINES=$((TOTAL_LINES + linesA))

    matched=$(comm -12 "$normA" "$normB" | wc -l)
    MATCHED_LINES=$((MATCHED_LINES + matched))

    if [ "$linesA" -gt 0 ]; then
      percent=$(awk "BEGIN { printf \"%.1f\", ($matched/$linesA)*100 }")
      TOTAL_PERCENT_SUM=$(awk "BEGIN { printf \"%.2f\", $TOTAL_PERCENT_SUM + $percent }")
      echo "$REL_PATH → $percent% similar"
    else
      echo "$REL_PATH → empty file"
    fi

    rm -f "$normA" "$normB"
  fi
done < <(find "$FOLDER_A" -type f | grep -E "$EXTENSIONS")
# -------------------------------------------------------------------

echo ""

if [ "$MATCHED_FILES" -eq 0 ]; then
  echo "No matching files with supported extensions were found between the two folders."
  exit 1
fi

OVERALL_PERCENT=$(awk "BEGIN { printf \"%.2f\", ($MATCHED_LINES/$TOTAL_LINES)*100 }")
AVG_SIMILARITY=$(awk "BEGIN { printf \"%.2f\", $TOTAL_PERCENT_SUM / $MATCHED_FILES }")

echo "------------------------"
echo "Files matched: $MATCHED_FILES"
echo "Total lines scanned: $TOTAL_LINES"
echo "Matching lines: $MATCHED_LINES"
echo "Estimated similarity (line-level): $OVERALL_PERCENT%"
echo "Average file-level similarity:     $AVG_SIMILARITY%"

