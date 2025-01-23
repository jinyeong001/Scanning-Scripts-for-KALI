#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Print banner
echo -e "${YELLOW}============================================================${NC}"
echo -e "${YELLOW}                    DIRB SCANNING RESULT                    ${NC}"
echo -e "${YELLOW}============================================================${NC}"
echo

# Default wordlist
DEFAULT_WORDLIST="/usr/share/dirb/wordlists/common.txt"

# Check if URL is provided as argument
if [ $# -eq 0 ]; then
    echo "Please provide target URL"
    echo "Usage: ./dirb.sh <URL>"
    exit 1
fi

TARGET_URL=$1

# Ask for custom wordlist
echo -e "Do you want to use a custom wordlist? (default: $DEFAULT_WORDLIST)"
read -p "Enter y/n: " use_custom
echo

if [[ $use_custom =~ ^[Yy]$ ]]; then
    while true; do
        read -p "Enter wordlist path: " custom_wordlist
        echo -e "\nYou entered: ${GREEN}$custom_wordlist${NC}"
        read -p "Is this correct? (y/n): " confirm
        echo
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            if [ -f "$custom_wordlist" ]; then
                WORDLIST=$custom_wordlist
                break
            else
                echo -e "${RED}Error: Wordlist file not found${NC}"
                echo -e "Do you want to:"
                echo "1. Try another wordlist path"
                echo "2. Use default wordlist"
                read -p "Enter choice (1-2): " retry_choice
                echo
                
                if [ "$retry_choice" = "2" ]; then
                    WORDLIST=$DEFAULT_WORDLIST
                    break
                fi
            fi
        fi
    done
else
    WORDLIST=$DEFAULT_WORDLIST
fi

# Function to show loading animation
loading_animation() {
    local target=$1
    local pid=$2
    local tool=$3
    local delay=0.1
    local spin=('-' '\' '|' '/')
    
    while ps -p $pid > /dev/null; do
        for i in "${spin[@]}"; do
            printf "\r${GREEN}[+] Scanning target ${BLUE}$target${NC} using ${PURPLE}$tool${NC} $i"
            sleep $delay
        done
    done
    printf "\r${GREEN}[+] Scan completed for ${BLUE}$target${NC} using ${PURPLE}$tool${NC}    \n"
}

# Function to print horizontal line
print_line() {
    printf "+----------+--------------------------------------------------+----------+----------+\n"
}

dirb_scan() {
    local target_url=$1
    local wordlist=$2
    local temp_file="/tmp/dirb_temp.txt"
    local log_file="../logs/dirb/dirbscan$(date +%Y%m%d_%H%M%S).log"

    # Create logs directory if it doesn't exist
    mkdir -p ../logs/dirb

    echo -e "Using wordlist: ${GREEN}$wordlist${NC}\n"

    # Run dirb in background and show loading animation
    dirb "$target_url" "$wordlist" -o "$temp_file" >/dev/null 2>&1 &
    loading_animation "$target_url" $! "Dirb"

    # Print and save directories section
    echo -e "\n${BLUE}[+] Discovered Directories:${NC}" | tee "$log_file"
    print_line | tee -a "$log_file"
    printf "| %-8s | %-48s | %-8s | %-8s |\n" "TYPE" "PATH" "STATE" "SIZE" | tee -a "$log_file"
    print_line | tee -a "$log_file"

    # First process explicit directories
    grep "==> DIRECTORY:" "$temp_file" | while read -r line; do
        local dir=$(echo "$line" | awk '{print $3}')
        local size=$(curl -sI "$dir" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
        [ -z "$size" ] && size="N/A"
        
        printf "| ${BLUE}%-8s${NC} | ${BLUE}%-48s${NC} | ${BLUE}%-8s${NC} | ${BLUE}%-8s${NC} |\n" "DIR" "$dir" "301" "$size"
        printf "| %-8s | %-48s | %-8s | %-8s |\n" "DIR" "$dir" "301" "$size" >> "$log_file"
    done

    # Then process other entries that end with '/' (directories)
    grep "+" "$temp_file" | grep -v "DIRECTORY" | while read -r line; do
        local url=$(echo "$line" | awk '{print $2}')
        if [[ $line =~ \(CODE:([0-9]+)\|SIZE:([0-9]+)\) ]]; then
            local code="${BASH_REMATCH[1]}"
            local size="${BASH_REMATCH[2]}"
        else
            local response=$(curl -sI "$url")
            local code=$(echo "$response" | grep "HTTP" | awk '{print $2}')
            local size=$(echo "$response" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
        fi
        [ -z "$size" ] && size="N/A"

        if [[ $url =~ /$ ]]; then
            case $code in
                "200") local color=$BLUE ;;
                "403") local color=$RED ;;
                *) local color=$YELLOW ;;
            esac
            
            printf "| ${color}%-8s${NC} | ${color}%-48s${NC} | ${color}%-8s${NC} | ${color}%-8s${NC} |\n" "DIR" "$url" "$code" "$size"
            printf "| %-8s | %-48s | %-8s | %-8s |\n" "DIR" "$url" "$code" "$size" >> "$log_file"
        fi
    done
    print_line | tee -a "$log_file"

    # Print and save files section
    echo -e "\n${YELLOW}[+] Discovered Files:${NC}" | tee -a "$log_file"
    print_line | tee -a "$log_file"
    printf "| %-8s | %-48s | %-8s | %-8s |\n" "TYPE" "PATH" "STATE" "SIZE" | tee -a "$log_file"
    print_line | tee -a "$log_file"

    # Process only files (entries that don't end with '/')
    grep "+" "$temp_file" | grep -v "DIRECTORY" | while read -r line; do
        local url=$(echo "$line" | awk '{print $2}')
        if [[ ! $url =~ /$ ]]; then 
            if [[ $line =~ \(CODE:([0-9]+)\|SIZE:([0-9]+)\) ]]; then
                local code="${BASH_REMATCH[1]}"
                local size="${BASH_REMATCH[2]}"
            else
                local response=$(curl -sI "$url")
                local code=$(echo "$response" | grep "HTTP" | awk '{print $2}')
                local size=$(echo "$response" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
            fi
            [ -z "$size" ] && size="N/A"

            local filename="${url##*/}"
            local type="UNDEFINED"

            if [[ $filename =~ \. ]]; then
                local extension="${filename##*.}"
                type="${extension^^}"
            else
                type="FILE"
            fi

            case $code in
                "200") local color=$YELLOW ;;
                "403") local color=$RED ;;
                *) local color=$YELLOW ;;
            esac

            printf "| ${color}%-8s${NC} | ${color}%-48s${NC} | ${color}%-8s${NC} | ${color}%-8s${NC} |\n" "$type" "$url" "$code" "$size"
            printf "| %-8s | %-48s | %-8s | %-8s |\n" "$type" "$url" "$code" "$size" >> "$log_file"
        fi
    done
    print_line | tee -a "$log_file"

    rm -f "$temp_file"
    echo -e "\n[+] DIRB scanning log saved to: ${CYAN}$log_file${NC}"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    dirb_scan "$TARGET_URL" "$WORDLIST"
fi