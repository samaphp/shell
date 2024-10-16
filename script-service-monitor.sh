#!/bin/bash
# This script will run in background and check the failed services and will show a notification to allow you to be aware and restart the failed service.
# Requirements: zenity `sudo zypper install zenity`

check_failed_services() {
    # Get the list of failed services
    failed_services=$(systemctl --failed --no-pager --no-legend | awk '{print $2}')

    # If there are failed services, send a notification with restart option
    if [ ! -z "$failed_services" ]; then
        # Show a notification with the list of failed services
        notify-send "Failed Services Detected" "The following services have failed: $failed_services"
        
        # Ask the user if they want to restart any of the failed services using zenity
        service_to_restart=$(zenity --list --title="Restart Failed Service" \
            --text="Select a service to restart:" \
            --column="Failed Services" $failed_services)
        
        # Restart the selected service if the user chose one
        if [ ! -z "$service_to_restart" ]; then
            sudo systemctl restart "$service_to_restart"
            if [ $? -eq 0 ]; then
                notify-send "Service Restarted" "$service_to_restart was successfully restarted."
            else
                notify-send "Service Restart Failed" "Failed to restart $service_to_restart."
            fi
        fi
    fi
}

# Main loop to run in the background
while true; do
    check_failed_services
    sleep 60  # Check every 60 seconds
done
