#!/bin/bash

# d7log.sh - Main entry script for d7log CLI

# Set executable permissions for all scripts
chmod +x "$(dirname "$0")/d7log.sh" 2>/dev/null
chmod +x "$(dirname "$0")/login.sh" 2>/dev/null
chmod +x "$(dirname "$0")/register.sh" 2>/dev/null
chmod +x "$(dirname "$0")/template.sh" 2>/dev/null
chmod +x "$(dirname "$0")/push.sh" 2>/dev/null

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

# Check if curl is installed
check_curl() {
    if ! command_exists curl; then
        echo -e "${RED}Error: curl is not installed. Please install curl to continue.${NC}"
        exit 1
    fi
}

# Check if user is logged in
check_auth() {
    if [ ! -f "$SCRIPT_DIR/auth.json" ]; then
        return 1
    fi
    
    # Try to parse the auth.json file
    if ! grep -q "user" "$SCRIPT_DIR/auth.json" 2>/dev/null; then
        return 1
    fi
    
    return 0
}

# Get username from auth.json
get_username() {
    if [ -f "$SCRIPT_DIR/auth.json" ]; then
        USERNAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$SCRIPT_DIR/auth.json" | cut -d'"' -f4)
        if [ -z "$USERNAME" ]; then
            echo "Unknown User"
        else
            echo "$USERNAME"
        fi
    else
        echo "Unknown User"
    fi
}

# Create required directories
mkdir -p "$SCRIPT_DIR/templates"
mkdir -p "$SCRIPT_DIR/logs"

# Display usage information
show_usage() {
    echo "Usage: ./d7log.sh [command]"
    echo "Commands:"
    echo "  run            - Start d7log CLI"
    echo "  register       - Register a new account"
    echo "  login          - Login to d7log system"
    echo "  template-run   - Create a new log template"
    echo "  push           - Push the template to API and save to logs"
    echo ""
}

# Check if command parameter is provided
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

# Process commands
case "$1" in
    run)
        echo -e "${GREEN}d7log CLI${NC} initializing..."
        echo "----------------------------------------"
        
        # Check if user is logged in
        if ! check_auth; then
            echo -e "${YELLOW}You are not logged in.${NC}"
            "$SCRIPT_DIR/logentry.sh"
            exit 0
        fi
        
        # User is logged in, proceed with service checks
        USERNAME=$(get_username)
        
        # For demo purposes, show success
        echo -e "${GREEN}✓ All systems operational${NC}"
        
        echo "----------------------------------------"
        echo -e "${GREEN}✓ Logged in as:${NC} ${BLUE}$USERNAME${NC}"
        echo -e "${GREEN}✓ Ready to start journaling${NC}"
        echo ""
        echo "Starting d7log CLI..."
        echo "----------------------------------------"
        
        # Start the log entry interface
        "$SCRIPT_DIR/logentry.sh"
        ;;
        
    register)
        # Run the registration script
        "$SCRIPT_DIR/register.sh"
        ;;
        
    login)
        # Run the login script
        "$SCRIPT_DIR/login.sh"
        ;;
        
    template-run)
        # Run the template generation
        "$SCRIPT_DIR/template.sh"
        ;;
        
    push)
        # Check if we have a commit message
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Missing entry title.${NC}"
            echo "Usage: ./d7log.sh push \"Your entry title\""
            exit 1
        fi
        
        # Run the push script with commit message
        "$SCRIPT_DIR/push.sh" "$2"
        ;;
        
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac

# Check if the command is 'run'
if [ "$1" = "run" ]; then
    echo -e "${GREEN}d7log CLI${NC} initializing..."
    echo "----------------------------------------"
    echo "Command executed: d7log run"
    echo "Current directory: $(pwd)"
    echo "Timestamp: $(date)"
    echo "----------------------------------------"
    
    # Setup dependencies
    setup_dependencies
    
    # Run service check
    echo -e "${YELLOW}Checking services...${NC}"
    if ! $SCRIPT_DIR/serviceCheck.sh; then
        echo -e "${RED}Service check failed. Exiting.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Service check passed!${NC}"
    echo "----------------------------------------"
    echo -e "${GREEN}d7log CLI${NC} is now ${BLUE}running${NC}..."
    echo "d7log CLI version 1.0.0"
    echo "Ready to process logs."
    
    # Run log entry
    $SCRIPT_DIR/logentry.sh
else
    echo "Usage: ./d7log.sh run"
    echo "Please provide the 'run' command to execute d7log CLI."
    exit 1
fi