#!/bin/bash

set -uo pipefail

PROGNAME=$(basename "$0")
WARN_LEVEL=""
CRIT_LEVEL=""
UNIQUE_MODE=false
TIMEOUT_SEC=10

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage() {
    echo "Usage: $PROGNAME [options]"
    echo ""
    echo "Options:"
    echo "  -w, --warning INTEGER   Set WARNING threshold"
    echo "  -c, --critical INTEGER  Set CRITICAL threshold"
    echo "  -u, --unique            Check UNIQUE users only"
    echo "  -t, --timeout SECONDS   Set execution timeout (default: $TIMEOUT_SEC)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Example:"
    echo "  $PROGNAME --warning 5 --critical 10 --unique"
}

get_cmd_path() {
    local cmd="$1"
    local path
    path=$(command -v "$cmd")
    if [[ -z "$path" ]]; then
        echo "UNKNOWN - Required command '$cmd' not found."
        exit $STATE_UNKNOWN
    fi
    echo "$path"
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -w|--warning)
            if [[ -n "${2:-}" ]] && [[ ${2:0:1} != "-" ]]; then
                WARN_LEVEL="$2"
                shift 2
            else
                echo "UNKNOWN - Argument for $key is missing."
                exit $STATE_UNKNOWN
            fi
            ;;
        -c|--critical)
            if [[ -n "${2:-}" ]] && [[ ${2:0:1} != "-" ]]; then
                CRIT_LEVEL="$2"
                shift 2
            else
                echo "UNKNOWN - Argument for $key is missing."
                exit $STATE_UNKNOWN
            fi
            ;;
        -t|--timeout)
            if [[ -n "${2:-}" ]] && [[ ${2:0:1} != "-" ]]; then
                TIMEOUT_SEC="$2"
                shift 2
            else
                echo "UNKNOWN - Argument for $key is missing."
                exit $STATE_UNKNOWN
            fi
            ;;
        -u|--unique)
            UNIQUE_MODE=true
            shift
            ;;
        -h|--help)
            usage
            exit $STATE_OK
            ;;
        *)
            echo "UNKNOWN - Invalid option: $key"
            usage
            exit $STATE_UNKNOWN
            ;;
    esac
done

if [[ -z "$WARN_LEVEL" || -z "$CRIT_LEVEL" ]]; then
    echo "UNKNOWN - Thresholds --warning and --critical are mandatory."
    exit $STATE_UNKNOWN
fi

re='^[0-9]+$'
if ! [[ $WARN_LEVEL =~ $re ]] || ! [[ $CRIT_LEVEL =~ $re ]] || ! [[ $TIMEOUT_SEC =~ $re ]]; then
    echo "UNKNOWN - Values for thresholds and timeout must be integers."
    exit $STATE_UNKNOWN
fi

if [[ "$WARN_LEVEL" -gt "$CRIT_LEVEL" ]]; then
    echo "UNKNOWN - Warning threshold ($WARN_LEVEL) cannot be greater than Critical ($CRIT_LEVEL)."
    exit $STATE_UNKNOWN
fi

CMD_WHO=$(get_cmd_path "who")
CMD_TIMEOUT=$(get_cmd_path "timeout")
CMD_WC=$(get_cmd_path "wc")
CMD_UNIQ=$(get_cmd_path "uniq")
CMD_SORT=$(get_cmd_path "sort")
CMD_AWK=$(get_cmd_path "awk")

if $UNIQUE_MODE; then
    # shellcheck disable=SC2016
    user_count=$($CMD_TIMEOUT "$TIMEOUT_SEC" "$CMD_WHO" | $CMD_AWK '{print $1}' | $CMD_SORT | $CMD_UNIQ | $CMD_WC -l)
    mode_label="unique users"
else
    user_count=$($CMD_TIMEOUT "$TIMEOUT_SEC" "$CMD_WHO" | $CMD_WC -l)
    mode_label="active sessions currently logged in"
fi

exit_status=$?

if [[ $exit_status == 124 ]]; then
    echo "UNKNOWN - Command timed out after ${TIMEOUT_SEC}s."
    exit $STATE_UNKNOWN
elif [[ $exit_status != 0 ]]; then
    echo "UNKNOWN - Error executing user check."
    exit $STATE_UNKNOWN
fi

user_count=$(echo "$user_count" | xargs)
perf_data="| users=${user_count};${WARN_LEVEL};${CRIT_LEVEL};0;"

if [[ "$user_count" -ge "$CRIT_LEVEL" ]]; then
    echo "USERS CRITICAL - ${user_count} ${mode_label} ${perf_data}"
    exit $STATE_CRITICAL
elif [[ "$user_count" -ge "$WARN_LEVEL" ]]; then
    echo "USERS WARNING - ${user_count} ${mode_label}  ${perf_data}"
    exit $STATE_WARNING
else
    echo "USERS OK - ${user_count} ${mode_label} ${perf_data}"
    exit $STATE_OK
fi