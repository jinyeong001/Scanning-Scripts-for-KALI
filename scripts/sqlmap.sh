#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to display scan mode menu
select_scan_mode() {
    echo -e "${YELLOW}============================================================${NC}"
    echo -e "${YELLOW}                   SQLMAP SCANNING OPTIONS                  ${NC}"
    echo -e "${YELLOW}============================================================${NC}"
    echo "1. Basic Scan (Detect vulnerabilities)"
    echo "2. Advanced Scan (Detailed injection testing)"
    echo

    while true; do
        read -p "Select scan mode (1-2): " scan_mode
        case $scan_mode in
            1)
                echo -e "${CYAN}Basic scan selected.${NC}"
                break
                ;;
            2)
                echo -e "${CYAN}Advanced scan selected.${NC}"
                break
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1 or 2.${NC}"
                ;;
        esac
    done
}

# Function to display risk level menu
select_risk_level() {
    echo -e "\n${YELLOW}============================================================${NC}"
    echo -e "${YELLOW}                     RISK LEVEL OPTIONS                     ${NC}"
    echo -e "${YELLOW}============================================================${NC}"
    echo "1. Low (Minimal risk, fewer payloads)"
    echo "2. Medium (Balanced risk and detection)"
    echo "3. High (Comprehensive testing, more intrusive)"
    echo

    while true; do
        read -p "Select risk level (1-3): " risk_level
        case $risk_level in
            1)
                echo -e "${CYAN}Low risk level selected.${NC}"
                break
                ;;
            2)
                echo -e "${CYAN}Medium risk level selected.${NC}"
                break
                ;;
            3)
                echo -e "${CYAN}High risk level selected.${NC}"
                break
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1, 2, or 3.${NC}"
                ;;
        esac
    done
}

# Function to display technique menu
select_technique() {
    echo -e "\n${YELLOW}============================================================${NC}"
    echo -e "${YELLOW}                   INJECTION TECHNIQUE OPTIONS              ${NC}"
    echo -e "${YELLOW}============================================================${NC}"
    echo "1. B: Boolean-based blind"
    echo "2. E: Error-based"
    echo "3. U: Union query-based"
    echo "4. S: Stacked queries"
    echo "5. T: Time-based blind"
    echo "6. Q: Inline queries"
    echo "7. All techniques"
    echo

    while true; do
        read -p "Select technique (1-7): " tech_choice
        case $tech_choice in
            1) technique="B"; break ;;
            2) technique="E"; break ;;
            3) technique="U"; break ;;
            4) technique="S"; break ;;
            5) technique="T"; break ;;
            6) technique="Q"; break ;;
            7) technique="BEUSTQ"; break ;;
            *) echo -e "${RED}Invalid option. Please select 1 to 7.${NC}" ;;
        esac
    done
}

# Function to get additional options
get_additional_options() {
    echo -e "\n${YELLOW}============================================================${NC}"
    echo -e "${YELLOW}                   ADDITIONAL OPTIONS                       ${NC}"
    echo -e "${YELLOW}============================================================${NC}"
    read -p "Enter additional options (e.g., --level=5 --risk=3): " additional_options
}

# Main function to perform SQLMap scan
sqlmap_scan() {
    target_url="$1"

    if [ -z "$target_url" ]; then
        echo -e "${RED}Error: No target URL provided.${NC}"
        exit 1
    fi

    # Select scan mode, risk level, and technique
    select_scan_mode
    select_risk_level
    select_technique
    get_additional_options

    # Construct SQLMap command based on user selections
    case $scan_mode in
        1) # Basic Scan
            sqlmap_command="sqlmap -u '$target_url' --batch --risk=$risk_level --technique=$technique $additional_options"
            ;;
        2) # Advanced Scan
            sqlmap_command="sqlmap -u '$target_url' --batch --risk=$risk_level --level=5 --technique=$technique $additional_options"
            ;;
    esac

    echo -e "\n${YELLOW}Starting SQLMap scan...${NC}"
    echo -e "Command: ${GREEN}$sqlmap_command${NC}"

    # Execute SQLMap command and capture output
    temp_file="/tmp/sqlmap_temp.txt"
    eval $sqlmap_command > "$temp_file" 2>&1

    # Process and display results
    echo -e "\n${GREEN}SQL Injection Scan Results:${NC}"
    print_line() {
        echo -e "+---------------+----------------------------------------+---------------+--------------------+"
    }
    print_line
    echo -e "| TYPE          | PARAMETER                              | TECHNIQUE     | DETAILS            |"
    print_line

    if grep -q "is vulnerable" "$temp_file"; then
        while IFS= read -r line; do
            if [[ $line =~ "Parameter:" ]]; then
                param=$(echo "$line" | grep -oP "Parameter '\K[^']+")
                tech=$(grep -A 1 "$line" "$temp_file" | grep -oP "Type: \K.*")
                echo -e "| ${RED}VULNERABLE${NC}   | ${RED}$param${NC}                              | ${RED}$tech${NC}         | ${RED}FOUND${NC}            |"
            fi
        done < "$temp_file"
    else
        echo -e "| ${GREEN}SAFE${NC}          | No vulnerabilities                     | N/A           | Target is safe     |"
    fi

    print_line

    # Print scan information
    echo -e "\n${YELLOW}[*] Scan Configuration:${NC}"
    print_line
    echo -e "| ITEM          | VALUE                                  | STATUS        | DETAILS            |"
    print_line
    printf "| %-13s | %-38s | %-13s | %-18s |\n" "URL" "$target_url" "COMPLETED" "Scanned"
    printf "| %-13s | %-38s | %-13s | %-18s |\n" "MODE" "$scan_mode" "COMPLETED" "Applied"
    printf "| %-13s | %-38s | %-13s | %-18s |\n" "RISK LEVEL" "$risk_level" "COMPLETED" "Applied"
    printf "| %-13s | %-38s | %-13s | %-18s |\n" "TECHNIQUE" "$technique" "COMPLETED" "Applied"
    print_line

    # Cleanup
    rm -f "$temp_file"
    echo -e "\n[+] SQLMap scan log saved to: ${CYAN}$log_file${NC}\n"
}

# Entry point for the script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        echo -e "${RED}Error: Target URL required.${NC}"
        echo "Usage: $0 <URL>"
        exit 1
    fi

    sqlmap_scan "$1"
fi
