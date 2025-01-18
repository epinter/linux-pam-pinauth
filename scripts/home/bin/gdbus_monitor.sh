#!/bin/bash
while read EVENT; do
    case "$EVENT" in
        *"{'LockedHint': <true>}"*)
            sudo -k
            echo sudo cache cleared|systemd-cat -t "${USER}-gdbus_monitor.sh" -p 6
            ;;
    esac
done < <(gdbus monitor -y  -d org.freedesktop.login1)
