#!/usr/bin/env bash

# Useful to kill/stop process if there is no space left on device
# @example: mon_free_space pkill -STOP -u$USER
# @example: mon_free_space -c "pkill -CONT -u$USER" pkill -STOP -u$USER

maxPercents=97
interval=10
diskDefault=1
disks=/
continueCmd=
cmd=:
loopCmd=

function printUsage()
{
    echo "$0 [ -m max_percents ] [ -i interval_secs ] [ -d mount_point ] [ -c continue cmd ] [ -l loop cmd ] [ cmd ]" >&2
    exit 1
}

function parseOptions()
{
    local OPTIND o
    while getopts "m:i:d:c:l:" o; do
        case "$o" in
            m) maxPercents=$OPTARG;;
            i) interval=$OPTARG;;
            d)
                if [ $diskDefault -eq 1 ]; then
                    diskDefault=0
                    disks=
                fi
                disks+="$OPTARG ";;
            c) continueCmd="$OPTARG";;
            l) loopCmd="$OPTARG";;
            *) printUsage;;
        esac
    done
    shift $((OPTIND-1))
    [ -n "$*" ] && cmd=$(printf '"%s" ' "$@")
}

function diskUsedPercents()
{
    local disk=$1
    df -m $disk | tail -n+2 | head -1 | awk '{ print substr($5, 1, length($5) - 1) }'
}

function main()
{
    local triggered=0

    while :; do
        sleep $interval

        for disk in $disks; do
            if [ $(diskUsedPercents $disk) -lt $maxPercents ]; then
                if [ $triggered -eq 1 ]; then
                    eval "$continueCmd"
                    triggered=0
                fi
                continue
            fi

            if [ $triggered -eq 0 ]; then
                printf "Not enough space left on %s, executing user specified command\n" $disk
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
    done
}

parseOptions "$@"
main
