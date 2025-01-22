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
echo -e "${YELLOW}                  GOBUSTER SCANNING RESULT                  ${NC}"
echo -e "${YELLOW}============================================================${NC}"
echo

# Default wordlist
DEFAULT_WORDLIST="/usr/share/dirbuster/wordlists/directory-list-lowercase-2.3-small.txt"

# Default extensions
DEFAULT_EXTENSIONS="html,php,txt"

# Check if URL is provided as argument
if [ $# -eq 0 ]; then
    echo "Please provide target URL"
    echo "Usage: ./gobuster.sh <URL>"
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

# Ask for custom extensions
echo -e "Do you want to use custom file extensions? (default: $DEFAULT_EXTENSIONS)"
read -p "Enter y/n: " use_custom_ext
echo

if [[ $use_custom_ext =~ ^[Yy]$ ]]; then
    while true; do
        echo "Enter file extensions (comma-separated, no spaces, e.g., php,txt,html):"
        read custom_extensions
        echo -e "\nYou entered: ${GREEN}$custom_extensions${NC}"
        read -p "Is this correct? (y/n): " confirm
        echo
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            EXTENSIONS=$custom_extensions
            break
        fi
    done
else
    EXTENSIONS=$DEFAULT_EXTENSIONS
fi

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
    printf "+%-60s+%-8s+%-10s+\n" "------------------------------------------------------------" "--------" "----------"
}

gobuster_scan() {
    local target_url=$1
    local wordlist=$2
    local temp_file="/tmp/gobuster_temp.txt"
    local log_file="../logs/gobuster/gobusterscan$(date +%Y%m%d_%H%M%S).log"

    # Create temp file if it doesn't exist
    touch "$temp_file"

    echo -e "Using wordlist: ${GREEN}$wordlist${NC}"
    echo -e "Using extensions: ${GREEN}$EXTENSIONS${NC}\n"

    # Run gobuster with directory and file extensions
    gobuster dir -u "$target_url" -w "$wordlist" -q -x "$EXTENSIONS" > "$temp_file" 2>/dev/null &
    local pid=$!
    loading_animation "$target_url" $pid
    wait $pid

    # Print and save directories section
    echo -e "\n[+] Discovered Directories:" | tee "$log_file"
    printf "+----------+------------------------------------------------------------+----------+\n" | tee -a "$log_file"
    printf "| %-8s | %-58s | %-8s |\n" "TYPE" "PATH" "STATUS" | tee -a "$log_file"
    printf "+----------+------------------------------------------------------------+----------+\n" | tee -a "$log_file"

    # Process directories
    while read -r line; do
        if [[ ! -z "$line" ]] && [[ "$line" =~ "301" || "$line" =~ "/$" ]]; then
            local path=$(echo "$line" | awk '{print $1}')
            # Construct full URL
            local full_url="${target_url%/}${path}"
            
            # Print to screen with colors
            printf "| ${BLUE}%-8s${NC} | ${BLUE}%-58s${NC} | ${BLUE}%-8s${NC} |\n" \
                "DIR" "$full_url" "Found"
            # Save to log without colors
            printf "| %-8s | %-58s | %-8s |\n" \
                "DIR" "$full_url" "Found" >> "$log_file"
        fi
    done < "$temp_file"
    printf "+----------+------------------------------------------------------------+----------+\n" | tee -a "$log_file"

    # Print and save files section
    echo -e "\n[+] Discovered Files:" | tee -a "$log_file"
    printf "+------------------------------------------------------------+--------+--------+\n" | tee -a "$log_file"
    printf "| %-58s | %-6s | %-6s |\n" "URL" "CODE" "SIZE" | tee -a "$log_file"
    printf "+------------------------------------------------------------+--------+--------+\n" | tee -a "$log_file"

    # Process files
    while read -r line; do
        if [[ ! -z "$line" ]] && [[ ! "$line" =~ "301" ]] && [[ ! "$line" =~ "/$" ]]; then
            local path=$(echo "$line" | awk '{print $1}')
            local status=$(echo "$line" | awk '{print $2}')
            local size=$(echo "$line" | awk '{print $3}')
            
            # Construct full URL
            local full_url="${target_url%/}${path}"

            case $status in
                "200") local color=$GREEN ;;
                "403") local color=$RED ;;
                *) local color=$YELLOW ;;
            esac

            # Print to screen with colors
            printf "| ${color}%-58s${NC} | ${color}%-6s${NC} | ${color}%-6s${NC} |\n" \
                "$full_url" "$status" "$size"
            # Save to log without colors
            printf "| %-58s | %-6s | %-6s |\n" \
                "$full_url" "$status" "$size" >> "$log_file"
        fi
    done < "$temp_file"
    printf "+------------------------------------------------------------+--------+--------+\n" | tee -a "$log_file"

    rm -f "$temp_file"
    echo -e "\n[+] Gobuster scanning log saved to: ${CYAN}$log_file${NC}"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    gobuster_scan "$TARGET_URL" "$WORDLIST"
fi
