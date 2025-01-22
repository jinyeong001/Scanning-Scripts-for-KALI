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
echo -e "${YELLOW}                   GOBUSTER SCANNING RESULT                 ${NC}"
echo -e "${YELLOW}============================================================${NC}"
echo

# Default settings
DEFAULT_WORDLIST="/usr/share/dirb/wordlists/common.txt"
DEFAULT_EXTENSIONS="html,php,txt"

# Check if URL is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Please provide target URL${NC}"
    echo "Usage: $0 <URL>"
    exit 1
fi

TARGET_URL=$1

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
    printf "+----------+----------------------------------------+---------------+----------+\n"
}

# Ask for custom wordlist
echo -e "Do you want to use a custom wordlist? (default: $DEFAULT_WORDLIST)"
read -p "Enter y/n: " use_custom_wordlist
echo

WORDLIST=$DEFAULT_WORDLIST
if [[ $use_custom_wordlist =~ ^[Yy]$ ]]; then
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
                    break
                fi
            fi
        fi
    done
fi

# Ask for custom extensions
echo -e "Do you want to use custom extensions? (default: $DEFAULT_EXTENSIONS)"
read -p "Enter y/n: " use_custom_extensions
echo

EXTENSIONS=$DEFAULT_EXTENSIONS
if [[ $use_custom_extensions =~ ^[Yy]$ ]]; then
    read -p "Enter extensions (comma-separated, no spaces): " custom_extensions
    EXTENSIONS=$custom_extensions
fi

gobuster_analyze() {
    local target_url=$1
    local wordlist=$2
    local extensions=$3
    local temp_file="/tmp/gobuster_temp.txt"
    local log_file="../logs/gobuster/gobusterscan$(date +%Y%m%d_%H%M%S).log"
    
    # Create logs directory if it doesn't exist
    mkdir -p ../logs/gobuster

    echo -e "\nUsing wordlist: ${GREEN}$wordlist${NC}"
    echo -e "Using extensions: ${GREEN}$extensions${NC}\n"

    # Remove trailing slash from target_url if present
    target_url=${target_url%/}

    # Run gobuster and save output to temporary file
    gobuster dir -u "$target_url" -w "$wordlist" -x "$extensions" -q > "$temp_file" &
    loading_animation "$target_url" $! "Gobuster"

    # Print and save directories section
    echo -e "\n${BLUE}[+] Discovered Directories:${NC}" | tee "$log_file"
    print_line | tee -a "$log_file"
    printf "| %-8s | %-38s | %-13s | %-8s |\n" "TYPE" "PATH" "STATE" "SIZE" | tee -a "$log_file"
    print_line | tee -a "$log_file"

    # First pass: Print directories (Status: 301)
    while IFS= read -r line; do
        if [[ $line =~ \/(.*)[[:space:]]+\(Status:[[:space:]]+([0-9]+)\)[[:space:]]+\[Size:[[:space:]]+([0-9]+)\] ]]; then
            local path="/${BASH_REMATCH[1]}"
            local status="${BASH_REMATCH[2]}"
            local size="${BASH_REMATCH[3]}"
            
            path=$(echo "$path" | sed 's/[[:space:]]*$//')
            local full_url="${target_url}${path}"
            
            if [ "$status" -eq 301 ]; then
                printf "| ${BLUE}%-8s${NC} | ${BLUE}%-38s${NC} | ${BLUE}%-13s${NC} | ${BLUE}%-8s${NC} |\n" "DIR" "$full_url" "$status" "$size"
                printf "| %-8s | %-38s | %-13s | %-8s |\n" "DIR" "$full_url" "$status" "$size" >> "$log_file"
            fi
        fi
    done < "$temp_file"
    print_line | tee -a "$log_file"

    # Print files section
    echo -e "\n${YELLOW}[+] Discovered Files:${NC}" | tee -a "$log_file"
    print_line | tee -a "$log_file"
    printf "| %-8s | %-38s | %-13s | %-8s |\n" "TYPE" "PATH" "STATE" "SIZE" | tee -a "$log_file"
    print_line | tee -a "$log_file"

    # Second pass: Print files (Status: 200)
    while IFS= read -r line; do
        if [[ $line =~ \/(.*)[[:space:]]+\(Status:[[:space:]]+([0-9]+)\)[[:space:]]+\[Size:[[:space:]]+([0-9]+)\] ]]; then
            local path="/${BASH_REMATCH[1]}"
            local status="${BASH_REMATCH[2]}"
            local size="${BASH_REMATCH[3]}"
            
            path=$(echo "$path" | sed 's/[[:space:]]*$//')
            local full_url="${target_url}${path}"
            
            if [ "$status" -eq 200 ]; then
                # Get file extension and convert to uppercase for TYPE
                local file_type="FILE"
                if [[ $path =~ \.([^.]+)$ ]]; then
                    file_type="${BASH_REMATCH[1]^^}"
                fi
                
                printf "| ${YELLOW}%-8s${NC} | ${YELLOW}%-38s${NC} | ${YELLOW}%-13s${NC} | ${YELLOW}%-8s${NC} |\n" "$file_type" "$full_url" "$status" "$size"
                printf "| %-8s | %-38s | %-13s | %-8s |\n" "$file_type" "$full_url" "$status" "$size" >> "$log_file"
            fi
        fi
    done < "$temp_file"
    print_line | tee -a "$log_file"
    
    # Cleanup and show log location
    rm -f "$temp_file"
    echo -e "\n[+] Gobuster scanning log saved to: ${CYAN}$log_file${NC}"
}

# Run the analysis
gobuster_analyze "$TARGET_URL" "$WORDLIST" "$EXTENSIONS"
