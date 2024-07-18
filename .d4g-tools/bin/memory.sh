#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC1090
# shellcheck disable=SC2034
set -Eeuo pipefail

usage() {
    cat <<EOF
USAGE ${0} [-v] [-h] --action=<action>

Report memory usage (linux, WSL2)

Supported parameters :
-h, --help : display this message
-v, --verbose : enable enhanced logging

<action>: start, stop, show
EOF
    exit 1
}

parse_params() {
    if [ $# -lt 1 ]; then
        echo "Some parameters are missing"
        usage
    elif [ $# -gt 2 ]; then
        echo "Too many parameters provided"
        usage
    fi

    RUN_SCRIPT="${BASH_SOURCE[0]}"
    RUN_DIR="$(dirname "${RUN_SCRIPT}")"

    source "$LIB_DIR/common.sh"
    # Format the date as YYYYMMDDHHMM
    date=$(date +"%Y%m%d")
    USAGE_LOG="$LOG_DIR"/usage.$date.log
    USAGE_PLOT="$LOG_DIR"/usage.$date.png

    # Parameters
    ACTION="false"

    while :; do
        case "${1-}" in
        -h | --help)
            usage
            ;;
        -v | --verbose)
            DEBUG="true"
            ;;
        --action=*)
            ACTION="${1#*=}"
            ;;
        -?*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            break
            ;;
        esac
        shift
    done

    debug "ACTION: $ACTION"
    debug "Log file: $USAGE_LOG"

    return 0
}

parse_params "$@"

# Function to get memory usage
get_memory_usage() {
    free -m | awk '/Mem/{printf("%.2f"), $3/$2*100}'
}

# Function to get CPU usage
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" |
        sed "s/.*, *\([0-9.]*\)%* id.*/\1/" |
        awk '{print 100 - $1"%"}'
}

case "$ACTION" in
"record")
    # Report memory usage
    time=$(date +"%Y-%m-%d-%H:%M:%S")

    # Get memory usage in MB and CPU usage
    memory_usage=$(free -m | awk 'NR==2{printf "%.2f", $3 }')
    cpu_usage=$(top -bn1 | grep load | awk '{printf "%.2f", $(NF-2)}')
    # memory_usage=$(vmstat -s | grep "used memory" | awk '{print $1/1024}')
    # cpu_usage=$(vmstat 1 2 | tail -1 | awk '{print $13+$14}')

    echo "$time $memory_usage $cpu_usage" >>"$USAGE_LOG"
    "$PROJECT_DIR/d4g" --memory=show
    ;;
"start")
    "$PROJECT_DIR/d4g" --memory=record
    # Add to user crontab if not already added
    if ! crontab -l | grep -q "$PROJECT_DIR/d4g --memory=record"; then
        (
            crontab -l >/dev/null 2>&1
            echo "* * * * * $PROJECT_DIR/d4g --memory=record"
        ) | crontab -
    fi

    ;;
"show")
    gnuplot <<EOF
    set terminal png size 800,600
    set output "$USAGE_PLOT"
    set title 'Memory and CPU Usage Over Time'
    set xlabel 'Time'
    set xdata time
    set timefmt '%Y-%m-%d-%H:%M:%S'
    set format x '%H:%M'
    set ylabel 'Used Memory (MB)'
    set y2label 'CPU Usage (%)'
    set ytics nomirror
    set y2tics
    set y2range [0:100] # Set upper value for y scale with 100 for CPU
    set grid
    plot "$USAGE_LOG" using 1:2 title 'Used Memory (MB)' with lines, \
        "$USAGE_LOG" using 1:3 axes x1y2 title 'CPU Usage (%)' with lines
EOF
    ;;
"stop")
    # Remove memory_usage.sh from crontab
    # crontab -l | grep -v "$RUN_SCRIPT" | crontab -
    crontab -l >tmpcron
    grep -v "$PROJECT_DIR/d4g --memory=record" tmpcron >cron || true
    crontab cron
    ;;
*) ;;
esac
# set title "System Usage Over Time"
# set xlabel "Time"
# set ylabel "Usage (%)"
# set xdata time
# set timefmt "%Y-%m-%d %H:%M:%S"
# set format x "%H:%M"
# set autoscale
# set term png
# set output "usage.png"
# plot "/tmp/usage_data.txt" using 1:2 title 'Memory' with lines, \
#      "/tmp/usage_data.txt" using 1:3 title 'CPU' with lines
cleanup
