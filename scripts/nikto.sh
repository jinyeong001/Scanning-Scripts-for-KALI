#!/bin/bash

nikto_scan() {
    local TARGET_URL=$1

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
    echo -e "${YELLOW}                    NIKTO SCANNING RESULT                   ${NC}"
    echo -e "${YELLOW}============================================================${NC}"
    echo

    # Function to print horizontal line
    print_line() {
        local widths=($1)
        printf "+%s+%s+\n" \
            "$(printf '%0.s-' $(seq 1 ${widths[0]}))" \
            "$(printf '%0.s-' $(seq 1 ${widths[1]}))"
    }

    # Function to show loading animation
    loading_animation() {
        local target=$1
        local pid=$2
        local tool=$3  # 각 도구의 이름을 파라미터로 받음
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

    # Function to determine risk level
    get_risk_level() {
        local input=$1
        case "$input" in
            *"Target"*|*"Start Time"*|*"Server:"*|*"robots.txt"*) echo "INFO" ;;
            *"X-Frame-Options"*|*"X-Content-Type-Options"*|*"Directory listing"*) echo "LOW" ;;
            *"TRACE"*|*"OPTIONS"*|*"phpinfo"*|*"backup"*) echo "MEDIUM" ;;
            *"Git"*|*"SQL"*|*"XSS"*|*"RCE"*|*"credentials"*|*".env"*) echo "HIGH" ;;
            *) echo "INFO" ;;
        esac
    }

    # Function to categorize findings
    categorize_finding() {
        local input=$1
        case "$input" in
            *"Target"*|*"Start Time"*|*"End Time"*) echo "SCAN INFO" ;;
            *"Server:"*|*"x-powered-by"*) echo "SERVER INFO" ;;
            *"X-Frame-Options"*|*"X-Content-Type-Options"*|*"httponly"*|*"HSTS"*) echo "SECURITY HEADERS" ;;
            *"Directory indexing"*|*"Directory listing"*) echo "DIRECTORY ACCESS" ;;
            *"Git"*|*"composer"*|*"README"*|*".env"*|*"backup"*|*".bak"*) echo "SENSITIVE FILES" ;;
            *"TRACE"*|*"OPTIONS"*|*"methods"*) echo "HTTP METHODS" ;;
            *"PHP"*|*"ASP"*|*"JSP"*) echo "TECH STACK" ;;
            *"robots.txt"*|*"sitemap"*) echo "CONFIGURATION" ;;
            *"SQL"*|*"XSS"*|*"RCE"*|*"LFI"*) echo "VULNERABILITIES" ;;
            *) echo "OTHER" ;;
        esac
    }

    # Function to summarize findings
    summarize_finding() {
        local input=$1
        case "$input" in
            *"Target IP:"*) echo "Target IP: $(echo $input | cut -d':' -f2 | xargs)" ;;
            *"Target Port:"*) echo "Port: $(echo $input | cut -d':' -f2 | xargs)" ;;
            *"Server:"*) echo "Web Server: $(echo $input | cut -d':' -f2- | xargs)" ;;
            *"X-Frame-Options"*) echo "Missing Clickjacking Protection" ;;
            *"X-Content-Type-Options"*) echo "Missing MIME Protection" ;;
            *"Directory indexing"*|*"Directory listing"*)
                local dir=$(echo $input | awk '{print $2}' | sed 's/:$//')
                echo "Directory listing enabled in $dir" ;;
            *"Git"*)
                local path=$(echo $input | awk '{print $2}' | sed 's/:$//')
                echo "Git repository files exposed in $path" ;;
            *"composer"*)
                local file=$(echo $input | awk '{print $2}' | sed 's/:$//')
                echo "Composer configuration exposed in $file" ;;
            *"TRACE"*) echo "HTTP TRACE method enabled" ;;
            *"OPTIONS"*) echo "Allowed HTTP Methods: $(echo $input | grep -o 'HEAD.*' | cut -d' ' -f1-5)" ;;
            *"robots.txt"*) echo "Sensitive information in robots.txt" ;;
            *"x-powered-by"*) echo "Server technology exposed: $(echo $input | grep -o 'PHP/[0-9.]*')" ;;
            *"httponly"*) echo "Cookies missing HttpOnly flag" ;;
            *) echo "$input" | sed 's/^+ //' | cut -c1-93 ;;
        esac
    }

    # Create log directory and files
    mkdir -p ../logs/nikto
    log_file="../logs/nikto/nikto_scan_$(date +%Y%m%d_%H%M%S).log"
    temp_file="/tmp/nikto_temp_$$.txt"

    # Run Nikto scan
    nikto -h "$TARGET_URL" > "$temp_file" &
    loading_animation "$TARGET_URL" $! "Nikto"

    # Calculate dynamic column widths
    col_widths=(25 95)

    # Arrays to store findings by risk level
    declare -A info_findings
    declare -A low_findings
    declare -A medium_findings
    declare -A high_findings

    # First pass - group findings by risk level
    while IFS= read -r line; do
        if [[ $line =~ ^\+ ]]; then
            category=$(categorize_finding "$line")
            risk=$(get_risk_level "$line")
            summary=$(summarize_finding "$line")
            finding="${category}|${summary}"
            
            case "$risk" in
                "INFO") info_findings["${#info_findings[@]}"]="$finding" ;;
                "LOW") low_findings["${#low_findings[@]}"]="$finding" ;;
                "MEDIUM") medium_findings["${#medium_findings[@]}"]="$finding" ;;
                "HIGH") high_findings["${#high_findings[@]}"]="$finding" ;;
            esac
        fi
    done < "$temp_file"

    # Display results header
    echo -e "\n${GREEN}[+] Scan Results by Risk Level:${NC}\n" | tee "$log_file"

    # Print risk level indicators
    echo -e "Risk Level Indicators:"
    echo -e "${BLUE}■${NC} Information"
    echo -e "${GREEN}■${NC} Low Risk"
    echo -e "${YELLOW}■${NC} Medium Risk"
    echo -e "${RED}■${NC} High Risk"

    # Information Level Findings
    if [ ${#info_findings[@]} -gt 0 ]; then
        echo -e "\n${BLUE}[*] Information Level Findings${NC}" | tee -a "$log_file"
        print_line "${col_widths[*]}" | tee -a "$log_file"
        printf "| %-23s | %-93s |\n" "CATEGORY" "FINDING" | tee -a "$log_file"
        print_line "${col_widths[*]}" | tee -a "$log_file"
        for finding in "${info_findings[@]}"; do
            IFS='|' read -r category summary <<< "$finding"
            printf "|${BLUE} %-23s${NC} | ${BLUE}%-93s ${NC}|\n" "$category" "$summary"
            printf "| %-23s | %-93s |\n" "$category" "$summary" >> "$log_file"
        done
        print_line "${col_widths[*]}" | tee -a "$log_file"
    fi

    # Low Risk Findings
    if [ ${#low_findings[@]} -gt 0 ]; then
        echo -e "\n${GREEN}[+] Low Risk Findings${NC}" | tee -a "$log_file"
        print_line "${col_widths[*]}" | tee -a "$log_file"
        printf "| %-23s | %-93s |\n" "CATEGORY" "FINDING" | tee -a "$log_file"
        print_line "${col_widths[*]}" | tee -a "$log_file"
        for finding in "${low_findings[@]}"; do
            IFS='|' read -r category summary <<< "$finding"
            printf "|${GREEN} %-23s${NC} | ${GREEN}%-93s ${NC}|\n" "$category" "$summary"
            printf "| %-23s | %-93s |\n" "$category" "$summary" >> "$log_file"
        done
        print_line "${col_widths[*]}" | tee -a "$log_file"
    fi

    # Medium Risk Findings
    if [ ${#medium_findings[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}[!] Medium Risk Findings${NC}" | tee -a "$log_file"
        print_line "${col_widths[*]}" | tee -a "$log_file"
        printf "| %-23s | %-93s |\n" "CATEGORY" "FINDING" | tee -a "$log_file"
        print_line "${col_widths[*]}" | tee -a "$log_file"
        for finding in "${medium_findings[@]}"; do
            IFS='|' read -r category summary <<< "$finding"
            printf "|${YELLOW} %-23s${NC} | ${YELLOW}%-93s ${NC}|\n" "$category" "$summary"
            printf "| %-23s | %-93s |\n" "$category" "$summary" >> "$log_file"
        done
        print_line "${col_widths[*]}" | tee -a "$log_file"
    fi

    # High Risk Findings
    if [ ${#high_findings[@]} -gt 0 ]; then
        echo -e "\n${RED}[!!] High Risk Findings${NC}" | tee -a "$log_file"
        print_line "${col_widths[*]}" | tee -a "$log_file"
        printf "| %-23s | %-93s |\n" "CATEGORY" "FINDING" | tee -a "$log_file"
        print_line "${col_widths[*]}" | tee -a "$log_file"
        for finding in "${high_findings[@]}"; do
            IFS='|' read -r category summary <<< "$finding"
            printf "|${RED} %-23s${NC} | ${RED}%-93s ${NC}|\n" "$category" "$summary"
            printf "| %-23s | %-93s |\n" "$category" "$summary" >> "$log_file"
        done
        print_line "${col_widths[*]}" | tee -a "$log_file"
    fi

    # Cleanup
    rm -f "$temp_file"
    echo -e "\n[+] NIKTO scanning log saved to: ${CYAN}$log_file${NC}\n"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        echo "Please provide target URL"
        echo "Usage: ./nikto.sh <URL>"
        exit 1
    fi
    nikto_scan "$1"
fi
