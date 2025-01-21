#!/bin/bash

clear

# Check if IP address is provided as argument
if [ $# -eq 0 ]; then
    echo "Please provide target IP address"
    echo "Usage: ./attack.sh <IP address>"
    exit 1
fi

TARGET_IP=$1

# Function to show loading animation
loading_animation() {
    local pid=$1
    local delay=0.5
    local dots=""
    while ps -p $pid > /dev/null; do
        dots="."
        echo -ne "\rStarting Nmap scan on $TARGET_IP$dots   "
        sleep $delay
        echo -ne "\rStarting Nmap scan on $TARGET_IP$dots$dots  "
        sleep $delay
        echo -ne "\rStarting Nmap scan on $TARGET_IP$dots$dots$dots "
        sleep $delay
    done
    echo -ne "\n"
}

# Run nmap scan in background and show loading animation
echo -n "Starting Nmap scan on $TARGET_IP"
sudo nmap $TARGET_IP -sV -v -p- 2>/dev/null > nmap_temp.log &
loading_animation $!

# Print header
echo -e "\nScan Results for IP: $TARGET_IP\n"

# Function to print horizontal line
print_line() {
    printf "+%-10s+%-10s+%-16s+%-39s+\n" "------------" "------------" "------------------" "-----------------------------------------"
}

# Print table header with MySQL-style formatting
print_line
printf "| %-10s | %-10s | %-16s | %-39s |\n" "PORT" "STATE" "SERVICE" "VERSION"
print_line

# Extract and format the port information
sed -n '/^PORT/,/^MAC Address/p' nmap_temp.log | \
grep "^[0-9]" | \
while read line; do
    port=$(echo $line | awk '{print $1}')
    state=$(echo $line | awk '{print $2}')
    service=$(echo $line | awk '{print $3}')
    version=$(echo $line | cut -d' ' -f4- | sed 's/  */ /g')
    printf "| %-10s | %-10s | %-16s | %-39s |\n" "$port" "$state" "$service" "$version"
done

# Print bottom line
print_line

# Clean up temporary file
rm nmap_temp.log
