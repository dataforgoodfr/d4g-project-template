#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC1090
# shellcheck disable=SC2034

set -Eeuo pipefail

# IMPORTANT AND NECESSARY: Load dependencies
source "$LIB_DIR"/common.sh

# This script replaces all env vars defined in .env and creates .env-full

# Specify the path to the .env file
env_file=".env"

# Specify the path to the .dock-env file
env_clean_file=".env-clean"

# Specify the path to the .env-full file
env_full_file=".env-full"

# Remove the existing .env-full file if it exists
if [ -f "$env_full_file" ]; then
  rm "$env_full_file"
fi

# Remove comments and blank lines from the original .env file and write to the new .dock-env file
sed '/^[[:blank:]]*#/d; /^[[:blank:]]*$/d' "$env_file" >"$env_clean_file"

#echo "New $env_clean_file file created without comments."

# Set the allexport option
set -o allexport

# Source the $env_clean_file file to load the environment variables
source "$env_clean_file"

# Unset the allexport option
set +o allexport

# Loop through the lines of the .env-clean file and write their values to the .env-full file
while IFS= read -r line; do
  var_name=$(echo "$line" | cut -d= -f1)
  var_value="${!var_name}"
  echo "$var_name=$var_value" >>"$env_full_file"
done <"$env_clean_file"

echo "--- Content of .env-full ---"
cat "$env_full_file"

# Remove the existing $env_clean_file file if it exists
if [ -f "$env_clean_file" ]; then
  rm "$env_clean_file"
fi
