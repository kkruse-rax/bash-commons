#!/bin/bash
# A collection of functions for working with files.

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/os.sh"

# Returns true (0) if the given file exists and is a file and false (1) otherwise
function file_exists {
  local readonly file="$1"
  [[ -f "$file" ]]
}

# Returns true (0) if the given file exists contains the given text and false (1) otherwise. The given text is a
# regular expression.
function file_contains_text {
  local readonly text="$1"
  local readonly file="$2"
  grep -q "$text" "$file"
}

# Append the given text to the given file. The reason this method exists, as opposed to using bash's built-in append
# operator, is that this method uses sudo, which doesn't work natively with the built-in operator.
function file_append_text {
  local readonly text="$1"
  local readonly file="$2"

  echo -e "$text" | sudo tee -a "$file" > /dev/null
}

# Replace a line of text that matches the given regular expression in a file with the given replacement. Only works for
# single-line replacements. Note that this method uses sudo!
function file_replace_text {
  local readonly original_text_regex="$1"
  local readonly replacement_text="$2"
  local readonly file="$3"

  local args=()
  args+=("-i")

  if os_is_darwin; then
    # OS X requires an extra argument for the -i flag (which we set to empty string) which Linux does no:
    # https://stackoverflow.com/a/2321958/483528
    args+=("")
  fi

  args+=("s|$original_text_regex|$replacement_text|")
  args+=("$file")

  sudo sed "${args[@]}" > /dev/null
}

# If the given file already contains the original text (which is a regex), replace it with the given replacement. If
# it doesn't contain that text, simply append the replacement text at the end of the file.
function file_replace_or_append_text {
  local readonly original_text_regex="$1"
  local readonly replacement_text="$2"
  local readonly file="$3"

  if file_exists "$file" && file_contains_text "$original_text_regex" "$file"; then
    file_replace_text "$original_text_regex" "$replacement_text" "$file"
  else
    file_append_text "$replacement_text" "$file"
  fi
}
