#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC1090
# shellcheck disable=SC2034

set -Eeuo pipefail

# Function to replace @@var with its corresponding environment variable value
replace_env_vars() {
    template_file=$1
    output_file="${1%.dist}"
    temp_file="temp.txt"
    rm -f $temp_file
    while IFS= read -r line; do
        for word in $line; do
            if [[ $word == @@* ]]; then
                var_name=${word#@@}
                var_value=${!var_name}
                if [ -n "$var_value" ]; then
                    line=${line/$word/$var_value}
                fi
            fi
        done
        echo "$line" >>$temp_file
    done <"$template_file"
    mv $temp_file "$output_file"
}

# Export the function so it can be used in other scripts
export -f replace_env_vars
