#!/bin/bash

# Enable verbose tracing for debugging - this will log every command executed
# Uncomment 'set -x' if you need extremely detailed logging.
# set -x


NOTIFICATION_THRESHOLD=20
SUSPEND_THRESHOLD=10
STATE_FILE="/home/vinaykrishnatdabade/.bin/.tmp/i3_battery_state"

echo "Starting ..." 
echo "Starting ..." > $STATE_FILE
# Ensure the directory for STATE_FILE exists
# mkdir -p "$(dirname "$STATE_FILE")"

# Initialize state variables
NOTIFIED_20_PERCENT=0
SUSPENDED_10_PERCENT=0

# Load previous state if file exists
# if [ -f "$STATE_FILE" ]; then
#     source "$STATE_FILE"
# fi

# This initial message will go to the main script log (which is ~/i3_battery_monitor.log based on your i3 exec line)
echo "$(date): Script started. Initial state: NOTIFIED_20_PERCENT=$NOTIFIED_20_PERCENT, SUSPENDED_10_PERCENT=$SUSPENDED_10_PERCENT"

while true; do
    echo "$(date): Loop iteration started." # This will go to the main script log

    # Get battery status and percentage
    # Check the exact output of 'acpi -b' in your terminal if this section seems problematic.
    BAT_STATUS=$(acpi -b | awk '{print $3}' | tr -d ',')
    BAT_PERCENT=$(acpi -b | awk '{print $4}' | tr -d '%,')
    BAT_PERCENT=${BAT_PERCENT:-0} # Default to 0 if not found

    echo "$(date):   Battery Status: '$BAT_STATUS', Percentage: '$BAT_PERCENT'%." # This will go to the main script log

    # Reset flags if battery is charging or full, and was previously low
    if [ "$BAT_STATUS" != "Discharging" ]; then
        if [ "$NOTIFIED_20_PERCENT" -eq 1 ] || [ "$SUSPENDED_10_PERCENT" -eq 1 ]; then
            echo "$(date):   Battery charging/full, resetting notification/suspend flags." # Log reset
            NOTIFIED_20_PERCENT=0
            SUSPENDED_10_PERCENT=0
            echo "NOTIFIED_20_PERCENT=$NOTIFIED_20_PERCENT" > "$STATE_FILE"
            echo "SUSPENDED_10_PERCENT=$SUSPENDED_10_PERCENT" >> "$STATE_FILE"
        fi
    elif [ "$BAT_STATUS" == "Discharging" ]; then
        # Notify at 20%
        if (( BAT_PERCENT <= NOTIFICATION_THRESHOLD )) && (( NOTIFIED_20_PERCENT == 0 )); then
            echo "$(date):   Battery at ${BAT_PERCENT}%, notifying." # Log notification trigger
            notify-send -u critical -t 5000 "Battery Low!" "Your battery is at ${BAT_PERCENT}%"
            NOTIFIED_20_PERCENT=1
            echo "NOTIFIED_20_PERCENT=$NOTIFIED_20_PERCENT" > "$STATE_FILE"
            echo "SUSPENDED_10_PERCENT=$SUSPENDED_10_PERCENT" >> "$STATE_FILE"
        fi

        # Suspend at 10%
        if (( BAT_PERCENT <= SUSPEND_THRESHOLD )) && (( SUSPENDED_10_PERCENT == 0 )); then
            echo "$(date):   Battery at ${BAT_PERCENT}%, suspending." # Log suspend trigger
            notify-send -u critical -t 0 "Battery CRITICALLY Low!" "Suspending system in 5 seconds! Battery at ${BAT_PERCENT}%"
            sleep 5
            systemctl suspend
            SUSPENDED_10_PERCENT=1
            echo "NOTIFIED_20_PERCENT=$NOTIFIED_20_PERCENT" > "$STATE_FILE"
            echo "SUSPENDED_10_PERCENT=$SUSPENDED_10_PERCENT" >> "$STATE_FILE"
        fi
    fi

    echo "$(date): Loop iteration finished, sleeping for 300 seconds." # Log end of loop iteration
    sleep 300
done
