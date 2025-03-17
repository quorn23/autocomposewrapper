#!/bin/bash

# "Gui" to choose which container should be used with autocompose. Multi-select and option to output to a file.
# V1.1
# Gabe 2025/03/17

# Check if the user has sudo rights in case not in the docker group
if ! sudo -v &>/dev/null; then
    echo "This script requires sudo privileges. Please run as a user with sudo access."
    exit 1
fi

# Check if whiptail or dialog is available (for Unraid user and sorts)
if command -v whiptail &>/dev/null; then
    MENU_TOOL="whiptail"
elif command -v dialog &>/dev/null; then
    MENU_TOOL="dialog"
else
    echo "Neither whiptail nor dialog is installed. Please install one of them."
    exit 1
fi

# List running containers
containers=($(docker ps --format "{{.Names}}"))

if [ ${#containers[@]} -eq 0 ]; then
    echo "No running containers found."
    exit 1
fi

# Create options for menu tool
options=()
for container in "${containers[@]}"; do
    options+=("$container" "" OFF)
done

# Show menu for selecting containers
if [[ "$MENU_TOOL" == "whiptail" ]]; then
    selected_containers=$(whiptail --title "Select Containers" --checklist \
        "Use space to select the containers:" 20 78 10 \
        "${options[@]}" 3>&1 1>&2 2>&3)
else
    selected_containers=$(dialog --title "Select Containers" --checklist \
        "Use space to select the containers:" 20 78 10 \
        "${options[@]}" 3>&1 1>&2 2>&3)
fi

# Convert selected_containers into an array
read -r -a container_array <<< $(echo $selected_containers | tr -d '"')

if [ ${#container_array[@]} -eq 0 ]; then
    echo "No containers selected. Exiting."
    exit 1
fi

# Ask user whether to output to file or just print
if [[ "$MENU_TOOL" == "whiptail" ]]; then
    destination=$(whiptail --title "Output Destination" --menu \
        "Choose where to save the output:" 15 60 2 \
        "1" "Print to console" \
        "2" "Save to file (autocompose_CURRENTDATE)" 3>&1 1>&2 2>&3)
else
    destination=$(dialog --title "Output Destination" --menu \
        "Choose where to save the output:" 15 60 2 \
        "1" "Print to console" \
        "2" "Save to file (autocompose_CURRENTDATE)" 3>&1 1>&2 2>&3)
fi

# Generate filename with timestamp
output_file="autocompose_$(date +%Y-%m-%d_%H-%M-%S).yml"

# Display the command before execution
echo "Running command: docker run --rm -v /var/run/docker.sock:/var/run/docker.sock ghcr.io/red5d/docker-autocompose ${container_array[*]}"

# Run docker-autocompose command based on user choice
if [[ "$destination" == "1" ]]; then
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock ghcr.io/red5d/docker-autocompose ${container_array[*]}
elif [[ "$destination" == "2" ]]; then
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock ghcr.io/red5d/docker-autocompose ${container_array[*]} > "$output_file"
    echo "Output saved to $output_file"
fi
