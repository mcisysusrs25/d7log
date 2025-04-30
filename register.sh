#!/bin/bash

# register.sh - Script for handling user registration

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

# Function to generate a secure password
generate_password() {
    # Generate a random password with letters, numbers and special characters
    local password=""
    
    # Method 1: Using /dev/urandom if available
    if [ -e /dev/urandom ]; then
        password=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9!@#$%^&*()-_=+' | head -c 32)
    else
        # Method 2: Alternative method for systems without /dev/urandom
        password=$(date +%s | sha256sum | base64 | head -c 32)
        # Add some randomness
        password="${password}$(echo $RANDOM | md5sum | head -c 8)"
        # Ensure some special characters
        password="${password}!@#$%^"
        # Trim to 32 characters
        password=$(echo "$password" | head -c 32)
    fi
    
    echo "$password"
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
echo -e "${BLUE}D7LOG REGISTRATION${NC}"
echo "----------------------------------------"

# Get essential user details
read -p "Enter your first name: " FIRST_NAME
read -p "Enter your last name: " LAST_NAME
NAME="${FIRST_NAME} ${LAST_NAME}"

while true; do
    read -p "Enter your email: " EMAIL
    if ! validate_email "$EMAIL"; then
        echo -e "${RED}Invalid email format.${NC}"
        continue
    fi
    break
done

# Auto-generate a secure password
PASSWORD=$(generate_password)

# Auto-detect timezone
TIMEZONE=$(get_system_timezone)

# Simulate API call for registration
echo -e "${YELLOW}Creating your account...${NC}"

# Create auth.json file with user data
USER_ID=$(date +%s)
TOKEN_PART1=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 40)
TOKEN_PART2=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 40)
AUTH_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.${TOKEN_PART1}.${TOKEN_PART2}"

# Create auth.json safely
cat > "$SCRIPT_DIR/auth.json" << EOF
{
  "user": {
    "id": "${USER_ID}",
    "name": "${NAME}",
    "first_name": "${FIRST_NAME}",
    "last_name": "${LAST_NAME}",
    "email": "${EMAIL}",
    "password": "${PASSWORD}",
    "role": "user",
    "token": "${AUTH_TOKEN}"
  },
  "permissions": {
    "read": true,
    "write": true
  },
  "settings": {
    "timezone": "${TIMEZONE}"
  },
  "auth_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

# Simulate a short delay
sleep 1

echo -e "${GREEN}✓ Registration successful!${NC}"
echo -e "Welcome to d7log, ${BLUE}${NAME}${NC}!"
echo ""
echo -e "${YELLOW}Generated secure password:${NC} ${PASSWORD}"
echo -e "${YELLOW}Important:${NC} Please save this password. It will not be shown again."
echo ""
echo "You are now logged in. Run:"
echo -e "${BLUE}  ./d7log.sh run${NC}"
echo "to start using the system."

exit 0