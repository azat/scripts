#!/usr/bin/env bash

# Useful to kill/stop process if it will eat to much memory
# @example: mon_free_swap pkill -STOP -u$USER
# @example: mon_free_swap -c "pkill -CONT -u$USER" pkill -STOP -u$USER

maxPercents=97
interval=10
cmd=:
continueCmd=
loopCmd=

function printUsage()
{
    echo "$0 [ -m max_percents ] [ -i interval_secs ] [ -c continue cmd ] [ -l loop cmd ] [ cmd ]" >&2
    exit 1
}

function parseOptions()
{
    local OPTIND o
    while getopts "m:i:c:l:" o; do
        case "$o" in
            m) maxPercents=$OPTARG;;
            i) interval=$OPTARG;;
            c) continueCmd="$OPTARG";;
            l) loopCmd="$OPTARG";;
            *) printUsage;;
        esac
    done
    shift $((OPTIND-1))
    [ -n "$*" ] && cmd=$(printf '"%s" ' "$@")
}

function swapUsedPercents()
{
    free -m | awk '/Swap:/ {printf("%.f\n", $2?($3/$2)*100:0);}'
}

function main()
{
    local triggered=0

    while :; do
        sleep $interval

        if [ $(swapUsedPercents) -lt $maxPercents ]; then
            if [ $triggered -eq 1 ]; then
                eval "$continueCmd"
                triggered=0
            fi
            continue
        fi

        if [ $triggered -eq 0 ]; then
            echo "Too much swap used, executing user specified command"
            eval "$cmd"
            triggered=1
        fi
        if [ -n "$loopCmd" ]; then
            eval "$loopCmd"
        fi
        if [ -z "$continueCmd" ] && [ -z "$loopCmd" ]; then
            exit
        fi
    done
}

parseOptions "$@"
main
