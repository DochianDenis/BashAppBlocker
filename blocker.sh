#!/bin/bash

# App Blocker Script
# Usage: sudo ./blocker.sh <on|off> <csv_file>

if [[ $EUID -ne 0 ]]; then
   echo "This script modifies /etc/hosts and must be run as root."
   echo "Please run using: sudo $0 $@" 
   exit 1
fi

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <on|off>"
    echo "Example: sudo $0 on"
    exit 1
fi

ACTION=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# Dynamically get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" &> /dev/null && pwd)"
FILE="$SCRIPT_DIR/apps.csv"

if [[ ! -f "$FILE" ]]; then
    echo "Error: File '$FILE' not found."
    echo "Please create it and add the domains you want to block."
    exit 1
fi

# Backup /etc/hosts just in case we haven't already
cp -n /etc/hosts /etc/hosts.bak 2>/dev/null || true

if [[ "$ACTION" == "on" ]]; then
    echo "Blocking domains from $FILE..."
    while IFS=',' read -r domain _; do
        # Trim whitespace, quotes, and carriage returns
        domain=$(echo "$domain" | tr -d '\r\n" ')
        
        # Skip empty lines, comments, or header rows
        if [[ -z "$domain" || "$domain" =~ ^[dD]omain$ || "$domain" =~ ^# ]]; then
            continue
        fi

        if ! grep -q "^0\.0\.0\.0 $domain$" /etc/hosts; then
            echo "0.0.0.0 $domain" >> /etc/hosts
            echo "Blocked: $domain"
        else
            echo "Already blocked: $domain"
        fi
    done < "$FILE"
    echo "Done."

elif [[ "$ACTION" == "off" ]]; then
    echo "Unblocking domains from $FILE..."
    while IFS=',' read -r domain _; do
        # Trim whitespace, quotes, and carriage returns
        domain=$(echo "$domain" | tr -d '\r\n" ')
        
        # Skip empty lines, comments, or header rows
        if [[ -z "$domain" || "$domain" =~ ^[dD]omain$ || "$domain" =~ ^# ]]; then
            continue
        fi

        # Remove the domain from /etc/hosts
        sed -i "/^0\.0\.0\.0 $domain$/d" /etc/hosts
        echo "Unblocked: $domain"
    done < "$FILE"
    echo "Done."

else
    echo "Invalid argument: $1. Please use 'on' or 'off'."
    exit 1
fi
