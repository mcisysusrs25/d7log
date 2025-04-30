#!/bin/bash

# login.sh - Script for handling user login

# Define colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate email
validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Function to get system timezone (simplified)
get_system_timezone() {
    # Default to UTC
    local tz="UTC"
    
    # Try different methods to get timezone
    if [ -f /etc/timezone ]; then
        tz=$(cat /etc/timezone 2>/dev/null)
    elif command_exists timedatectl; then
        tz=$(timedatectl | grep "Time zone\|Timezone" | awk '{print $3}')
    elif [ -L /etc/localtime ]; then
        # Try to get timezone from the localtime symlink
        local timezone_path=$(readlink /etc/localtime)
        if [[ "$timezone_path" == *"zoneinfo"* ]]; then
            tz=$(echo "$timezone_path" | sed -e 's|.*/zoneinfo/||')
        fi
    fi
    
    # Make sure we have a valid timezone, otherwise default to UTC
    if [ -z "$tz" ]; then
        tz="UTC"
    fi
    
    echo "$tz"
}

# Display header
echo -e "${BLUE}D7LOG LOGIN${NC}"
echo "----------------------------------------"

# Ask for email with validation
while true; do
    read -p "Enter your email: " EMAIL
    if ! validate_email "$EMAIL"; then
        echo -e "${RED}Invalid email format.${NC}"
        continue
    fi
    break
done

# Ask for password
read -sp "Enter your password: " PASSWORD
echo ""

# Get system timezone
TIMEZONE=$(get_system_timezone)

# Check if the credentials match any existing account
if [ -f "$SCRIPT_DIR/auth.json" ]; then
    EXISTING_EMAIL=$(grep -o '"email"[[:space:]]*:[[:space:]]*"[^"]*"' "$SCRIPT_DIR/auth.json" | cut -d'"' -f4)
    STORED_PASSWORD=$(grep -o '"password"[[:space:]]*:[[:space:]]*"[^"]*"' "$SCRIPT_DIR/auth.json" | cut -d'"' -f4)
    
    # Simple validation for demo - in real app would check against database
    if [ "$EMAIL" = "$EXISTING_EMAIL" ] && [ "$PASSWORD" = "$STORED_PASSWORD" ]; then
        # Use existing auth.json but update timestamp
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        sed -i.bak "s/\"auth_timestamp\": \"[^\"]*\"/\"auth_timestamp\": \"$TIMESTAMP\"/" "$SCRIPT_DIR/auth.json"
        rm -f "$SCRIPT_DIR/auth.json.bak"
        
        # Get username from auth.json
        NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$SCRIPT_DIR/auth.json" | cut -d'"' -f4)
        
        echo -e "${GREEN}✓ Login successful!${NC}"
        echo -e "Welcome back, ${BLUE}$NAME${NC}!"
        echo ""
        echo "You can now use d7log CLI. Run:"
        echo -e "${BLUE}  ./d7log.sh run${NC}"
        echo "to start using the system."
        exit 0
    else
        echo -e "${RED}Invalid credentials. Please try again.${NC}"
        exit 1
    fi
fi

echo -e "${RED}No account found with email: $EMAIL${NC}"
echo "Please register first with:"
echo -e "${BLUE}  ./d7log.sh register${NC}"
exit 1