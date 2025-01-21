#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Print banner
echo -e "${YELLOW}============================================================${NC}"
echo -e "${YELLOW}                    NMAP SCANNING RESULT                    ${NC}"
echo -e "${YELLOW}============================================================${NC}"
echo

# Check if IP address is provided as argument
if [ $# -eq 0 ]; then
    echo "Please provide target IP address"
    echo "Usage: ./nmap.sh <IP address>"
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
        echo -ne "\rScanning ports on $TARGET_IP$dots   "
        sleep $delay
        echo -ne "\rScanning ports on $TARGET_IP$dots$dots  "
        sleep $delay
        echo -ne "\rScanning ports on $TARGET_IP$dots$dots$dots "
        sleep $delay
    done
    echo -ne "\n"
}

# Create log file name with timestamp in the correct directory
log_file="../logs/nmap/nmapscan$(date +%Y%m%d_%H%M%S).log"

# Run nmap scan in background and show loading animation
echo -n "Starting Nmap scan on $TARGET_IP"
sudo nmap $TARGET_IP -sV -v -p- 2>/dev/null > nmap_temp.log &
loading_animation $!

# Print header and save to log
echo -e "[+] Discovered Ports:" | tee "$log_file"

# Function to print horizontal line
print_line() {
    printf "+%-10s+%-10s+%-16s+%-39s+\n" "------------" "------------" "------------------" "-----------------------------------------"
}

# Print table header
print_line | tee -a "$log_file"
printf "| %-10s | %-10s | %-16s | %-39s |\n" "PORT" "STATE" "SERVICE" "VERSION" | tee -a "$log_file"
print_line | tee -a "$log_file"

# Extract and format the port information
sed -n '/^PORT/,/^MAC Address/p' nmap_temp.log | \
grep "^[0-9]" | \
while read line; do
    port=$(echo $line | awk '{print $1}')
    state=$(echo $line | awk '{print $2}')
    service=$(echo $line | awk '{print $3}')
    version=$(echo $line | cut -d' ' -f4- | sed 's/  */ /g')
    
    # Set color based on state
    if [ "$state" = "open" ]; then
        color=$GREEN
    else
        color=$RED
    fi
    
    # Print to screen with colors
    printf "${NC}| ${color}%-10s ${NC}|${color} %-10s ${NC}|${color} %-16s ${NC}|${color} %-39s ${NC}|\n" \
        "$port" "$state" "$service" "$version"
    # Save to log file without colors
    printf "| %-10s | %-10s | %-16s | %-39s |\n" \
        "$port" "$state" "$service" "$version" >> "$log_file"
done

# Print and save bottom line
print_line | tee -a "$log_file"

# Clean up temporary file
rm nmap_temp.log

echo -e "\n[+] Log saved to: $log_file"
