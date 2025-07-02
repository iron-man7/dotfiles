#!/bin/zsh
###!/bin/bash

NOTIFICATION_THRESHOLD=20
SUSPEND_THRESHOLD=10
STATE_FILE="/home/vinaykrishnatdabade/.bin/.tmp/i3_battery_state"

# Initialize state variables
NOTIFIED_20_PERCENT=0
SUSPENDED_10_PERCENT=0

# Load previous state if file exists
if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
fi

echo "Whats up !" > "$STATE_FILE"

while true; do
    BAT_STATUS=$(acpi -b | awk '{print $3}' | tr -d ',')
    BAT_PERCENT=$(acpi -b | awk '{print $4}' | tr -d '%,')
    BAT_PERCENT=${BAT_PERCENT:-0} # Default to 0 if not found

    # Reset flags if battery is charging or full, and was previously low
    if [ "$BAT_STATUS" != "Discharging" ]; then
        if [ "$NOTIFIED_20_PERCENT" -eq 1 ] || [ "$SUSPENDED_10_PERCENT" -eq 1 ]; then
            NOTIFIED_20_PERCENT=0
            SUSPENDED_10_PERCENT=0
            echo "NOTIFIED_20_PERCENT=$NOTIFIED_20_PERCENT" > "$STATE_FILE"
            echo "SUSPENDED_10_PERCENT=$SUSPENDED_10_PERCENT" >> "$STATE_FILE"
        fi
    elif [ "$BAT_STATUS" == "Discharging" ]; then
        # Notify at 20%
        if (( BAT_PERCENT <= NOTIFICATION_THRESHOLD )) && (( NOTIFIED_20_PERCENT == 0 )); then
            notify-send -u critical -t 5000 "Battery Low!" "Your battery is at ${BAT_PERCENT}%"
            NOTIFIED_20_PERCENT=1
            echo "NOTIFIED_20_PERCENT=$NOTIFIED_20_PERCENT" > "$STATE_FILE"
            echo "SUSPENDED_10_PERCENT=$SUSPENDED_10_PERCENT" >> "$STATE_FILE"
        fi

        # Suspend at 10%
        if (( BAT_PERCENT <= SUSPEND_THRESHOLD )) && (( SUSPENDED_10_PERCENT == 0 )); then
            notify-send -u critical -t 0 "Battery CRITICALLY Low!" "Suspending system in 5 seconds! Battery at ${BAT_PERCENT}%"
            sleep 5
            systemctl suspend
            SUSPENDED_10_PERCENT=1
            echo "NOTIFIED_20_PERCENT=$NOTIFIED_20_PERCENT" > "$STATE_FILE"
            echo "SUSPENDED_10_PERCENT=$SUSPENDED_10_PERCENT" >> "$STATE_FILE"
        fi
    fi

    sleep 30
done
