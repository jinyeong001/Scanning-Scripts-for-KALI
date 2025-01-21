#!/bin/bash

clear

# Check if URL is provided as argument
if [ $# -eq 0 ]; then
    echo "Please provide target URL"
    echo "Usage: ./dirb.sh <URL>"
    exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Function to show loading animation
loading_animation() {
    local target=$1
    local pid=$2
    local delay=0.5
    local dots=""
    while ps -p $pid > /dev/null 2>&1; do
        dots="."
        echo -ne "\rScanning directories on $target$dots   "
        sleep $delay
        echo -ne "\rScanning directories on $target$dots$dots  "
        sleep $delay
        echo -ne "\rScanning directories on $target$dots$dots$dots "
        sleep $delay
    done
    echo -ne "\n"
}

# Function to print horizontal line
print_line() {
    printf "+%-10s+%-60s+%-10s+\n" "----------" "------------------------------------------------------------" "----------"
}

dirb_scan() {
    local target_url=$1
    local temp_file="/tmp/dirb_temp.txt"
    local log_file="../logs/dirb/dirbscan$(date +%Y%m%d_%H%M%S).log"

    # Create temp file if it doesn't exist
    touch "$temp_file"

    # Run dirb in background and show loading animation
    dirb "$target_url" -o "$temp_file" >/dev/null 2>&1 &
    local pid=$!
    loading_animation "$target_url" $pid
    wait $pid

    echo -e "\n[+] Discovered Directories:"
    print_line
    printf "| %-8s | %-58s | %-8s |\n" "TYPE" "PATH" "STATUS"
    print_line
    
    grep "==> DIRECTORY:" "$temp_file" | while read -r line; do
        local dir=$(echo "$line" | awk '{print $3}')
        printf "| ${BLUE}%-8s${NC} | ${BLUE}%-58s${NC} | ${BLUE}%-8s${NC} |\n" "DIR" "$dir" "Found"
        echo "[DIR] $dir" >> "$log_file"
    done
    print_line

    echo -e "\n[+] Discovered Files:"
    printf "+%-60s+%-6s+%-6s+\n" "------------------------------------------------------------" "--------" "--------"
    printf "| %-58s | %-6s | %-6s |\n" "URL" "CODE" "SIZE"
    printf "+%-60s+%-6s+%-6s+\n" "------------------------------------------------------------" "--------" "--------"

    grep "+" "$temp_file" | while read -r line; do
        local url=$(echo "$line" | awk '{print $2}')
        local code=$(echo "$line" | grep -oP 'CODE:\K[0-9]+')
        local size=$(echo "$line" | grep -oP 'SIZE:\K[0-9]+')

        case $code in
            "200") local color=$GREEN ;;
            "403") local color=$RED ;;
            *) local color=$YELLOW ;;
        esac

        printf "| ${color}%-58s${NC} | ${color}%-6s${NC} | ${color}%-6s${NC} |\n" "$url" "$code" "$size"
        printf "[FILE] %-60s | %-6s | %-6s\n" "$url" "$code" "$size" >> "$log_file"
    done
    printf "+%-60s+%-6s+%-6s+\n" "------------------------------------------------------------" "--------" "--------"

    rm -f "$temp_file"
    echo -e "\n[+] Log saved to: $log_file"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ -z "$1" ]; then
        read -p "Enter target URL: " url
    else
        url=$1
    fi
    dirb_scan "$url"
fi