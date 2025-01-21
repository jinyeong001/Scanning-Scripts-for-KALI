#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to create necessary directories
create_directories() {
    # Create main logs directory if it doesn't exist
    if [ ! -d "logs" ]; then
        mkdir logs
    fi

    # Create subdirectories for each tool
    if [ ! -d "logs/nmap" ]; then
        mkdir logs/nmap
    fi
    if [ ! -d "logs/dirb" ]; then
        mkdir logs/dirb
    fi
}

# Function to display menu
show_menu() {
    if [ "$first_run" = true ]; then
        clear
        first_run=false
    fi
    echo -e "${BLUE}=== Available Scanning Tools ===${NC}"
    echo "1. Nmap Port Scanner"
    echo "2. Dirb Directory Scanner"
    echo "3. Exit"
    echo
    read -p "Select a tool (1-3): " choice
}

# Function to handle nmap scan
run_nmap() {
    while true; do
        read -p "Enter target IP address: " target_ip
        if [ ! -z "$target_ip" ]; then
            echo -e "\nYou entered: ${GREEN}$target_ip${NC}"
            read -p "Is this correct? (y/n): " confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                # Move to scripts directory and run nmap.sh
                cd scripts
                ./nmap.sh "$target_ip"
                cd ..
                break
            fi
        else
            echo -e "${RED}Invalid IP address${NC}"
        fi
    done
}

# Function to handle dirb scan
run_dirb() {
    while true; do
        read -p "Enter target URL: " target_url
        if [ ! -z "$target_url" ]; then
            echo -e "\nYou entered: ${GREEN}$target_url${NC}"
            read -p "Is this correct? (y/n): " confirm
            echo 
            if [[ $confirm =~ ^[Yy]$ ]]; then
                # Move to scripts directory and run dirb.sh
                cd scripts
                ./dirb.sh "$target_url"
                cd ..
                break
            fi
        else
            echo -e "${RED}Invalid URL${NC}"
        fi
    done
}

# Main execution loop
create_directories
first_run=true

while true; do
    show_menu

    case $choice in
        1)
            run_nmap
            ;;
        2)
            run_dirb
            ;;
        3)
            echo -e "${YELLOW}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac

    echo
    read -p "Do you want to run another scan? (y/n): " continue_scan
    if [[ ! $continue_scan =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Exiting...${NC}"
        break
    fi
    echo  # Add a new line before showing menu again
done
