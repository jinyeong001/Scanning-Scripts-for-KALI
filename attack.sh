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
# Also store HTTP ports for later use
declare -a http_ports=()
while read line; do
    port=$(echo $line | awk '{print $1}')
    state=$(echo $line | awk '{print $2}')
    service=$(echo $line | awk '{print $3}')
    version=$(echo $line | cut -d' ' -f4- | sed 's/  */ /g')
    printf "| %-10s | %-10s | %-16s | %-39s |\n" "$port" "$state" "$service" "$version"
    
    # Store HTTP ports that are open
    if [[ "$state" == "open" && ("$service" == "http" || "$service" == "httpd" || "$service" =~ http*) ]]; then
        port_number=$(echo $port | cut -d'/' -f1)
        http_ports+=($port_number)
    fi
done < <(sed -n '/^PORT/,/^MAC Address/p' nmap_temp.log | grep "^[0-9]")

# Print bottom line
print_line

# Clean up nmap temporary file
rm nmap_temp.log

# If HTTP ports were found, offer directory scanning
if [ ${#http_ports[@]} -gt 0 ]; then
    echo -e "\nFound open HTTP ports: ${http_ports[@]}"
    read -p "Would you like to perform directory scanning on these ports? (yes/no): " answer
    
    if [[ "$answer" == "yes" ]]; then
        for port in "${http_ports[@]}"; do
            echo -e "\nStarting directory scan on port $port..."
            
            # Function for dirb loading animation
            dirb_loading_animation() {
                local pid=$1
                local delay=0.5
                local dots=""
                while ps -p $pid > /dev/null; do
                    dots="."
                    echo -ne "\rScanning directories on port $port$dots   "
                    sleep $delay
                    echo -ne "\rScanning directories on port $port$dots$dots  "
                    sleep $delay
                    echo -ne "\rScanning directories on port $port$dots$dots$dots "
                    sleep $delay
                done
                echo -ne "\n"
            }
            
            # Run dirb in background with loading animation
            dirb "http://$TARGET_IP:$port" ./wordlist.txt -w 2>/dev/null > dirb_temp.log &
            dirb_loading_animation $!
            
            # Print dirb results in table format
            echo -e "\nDirectory Scan Results for Port $port:\n"
            printf "+%-50s+\n" $(printf -- "-%.0s" {1..50})
            printf "| %-48s |\n" "DISCOVERED DIRECTORIES"
            printf "+%-50s+\n" $(printf -- "-%.0s" {1..50})
            
            grep "=>" dirb_temp.log | while read -r line; do
                dir=$(echo "$line" | awk '{print $2}')
                printf "| %-48s |\n" "$dir"
            done
            
            printf "+%-50s+\n" $(printf -- "-%.0s" {1..50})
            rm dirb_temp.log
        done
    fi
fi
