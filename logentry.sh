#!/bin/bash

# logentry.sh - Script for entering and processing log data

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

# Function to check if user is logged in
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

# Function to get username from auth.json
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

# Function to clear the screen
clear_screen() {
    if [ -n "$TERM" ]; then
        tput clear || clear || echo -e "\033c" || echo -e "\x1B[2J\x1B[H"
    else
        clear || echo -e "\033c" || echo -e "\x1B[2J\x1B[H"
    fi
}

# Create log file
create_log_file() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local log_dir="$SCRIPT_DIR/logs"
    
    # Create logs directory if it doesn't exist
    mkdir -p "$log_dir"
    
    # Create log file
    local log_file="$log_dir/session_$timestamp.log"
    
    # Get username
    local username=$(get_username)
    
    # Create the log file with header
    echo "# D7LOG SESSION - $timestamp" > "$log_file"
    echo "# User: $username" >> "$log_file"
    echo "----------------------------------------" >> "$log_file"
    
    # Return log file path
    echo "$log_file"
}

# Function to run login
run_login() {
    "$SCRIPT_DIR/login.sh"
    # If login was successful, continue with CLI
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Successfully logged in${NC}"
        USERNAME=$(get_username)
        echo -e "Now logged in as: ${BLUE}$USERNAME${NC}"
        echo ""
    fi
}

# Function to run registration
run_register() {
    "$SCRIPT_DIR/register.sh"
    # If registration was successful, continue with CLI
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Successfully registered${NC}"
        USERNAME=$(get_username)
        echo -e "Now logged in as: ${BLUE}$USERNAME${NC}"
        echo ""
    fi
}

# Function to run template creation
run_template() {
    # Check if user is logged in
    if ! check_auth; then
        echo -e "${YELLOW}You need to login first.${NC}"
        echo "Type 'login' or 'register' to get started."
        return 1
    fi
    
    "$SCRIPT_DIR/template.sh"
}

# Function to run push
run_push() {
    # Check if user is logged in
    if ! check_auth; then
        echo -e "${YELLOW}You need to login first.${NC}"
        echo "Type 'login' or 'register' to get started."
        return 1
    fi
    
    # Extract title (everything after 'push')
    local entry_title="${*:1}"
    
    "$SCRIPT_DIR/push.sh" "$entry_title"
}

# Function to open editor
open_editor() {
    # Check if user is logged in
    if ! check_auth; then
        echo -e "${YELLOW}You need to login first.${NC}"
        echo "Type 'login' or 'register' to get started."
        return 1
    fi
    
    # Find the most recent template
    LATEST_TEMPLATE=$(find "$SCRIPT_DIR/templates" -name "*.json" -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [ -z "$LATEST_TEMPLATE" ]; then
        echo -e "${RED}No journal template found. Create one first with 'template-run'.${NC}"
        return 1
    fi
    
    # Create a temporary file for editing the content
    TEMP_FILE=$(mktemp)
    
    # If jq is installed, extract content from template
    if command_exists jq; then
        CONTENT=$(jq -r '.entry.content' "$LATEST_TEMPLATE")
        if [ "$CONTENT" = "null" ] || [ -z "$CONTENT" ]; then
            echo "Enter your journal entry here..." > "$TEMP_FILE"
        else
            echo "$CONTENT" > "$TEMP_FILE"
        fi
    else
        # Fallback if jq is not installed
        echo "Enter your journal entry here..." > "$TEMP_FILE"
    fi
    
    echo -e "${YELLOW}Opening journal editor...${NC}"
    
    # Open editor
    if [ -n "$EDITOR" ]; then
        $EDITOR "$TEMP_FILE"
    elif command_exists nano; then
        nano "$TEMP_FILE"
    elif command_exists vim; then
        vim "$TEMP_FILE"
    elif command_exists vi; then
        vi "$TEMP_FILE"
    else
        echo -e "${RED}No editor found. Please set the EDITOR environment variable.${NC}"
        rm "$TEMP_FILE"
        return 1
    fi
    
    # Read content from temp file
    EDITED_CONTENT=$(cat "$TEMP_FILE")
    rm "$TEMP_FILE"
    
    # Update template with new content
    if command_exists jq; then
        TEMPLATE_CONTENT=$(cat "$LATEST_TEMPLATE")
        echo "$TEMPLATE_CONTENT" | jq ".entry.content = \"$EDITED_CONTENT\"" > "$LATEST_TEMPLATE"
    else
        # Basic text replacement
        sed -i.bak "s/\"content\": \"[^\"]*\"/\"content\": \"$EDITED_CONTENT\"/" "$LATEST_TEMPLATE"
        rm -f "$LATEST_TEMPLATE.bak"
    fi
    
    echo -e "${GREEN}✓ Journal updated. Use 'push' to save it.${NC}"
    return 0
}

# Function to show help
show_help() {
    echo -e "${BLUE}Available commands:${NC}"
    echo "  register        - Create a new account"
    echo "  login           - Login to d7log system"
    echo "  template-run    - Create a new journal template"
    echo "  edit            - Write in your journal"
    echo "  push [title]    - Save journal with optional title"
    echo "  clear/cls       - Clear the terminal screen"
    echo "  help            - Show this help information"
    echo "  exit            - Exit d7log CLI"
}

# Create log file for this session
LOG_FILE=$(create_log_file)

# Display header
echo -e "${BLUE}D7LOG JOURNAL SYSTEM${NC}"
echo "----------------------------------------"
if check_auth; then
    USERNAME=$(get_username)
    echo -e "User: ${BLUE}$USERNAME${NC}"
else
    echo -e "Status: ${YELLOW}Not logged in${NC}"
    echo "Type 'register' to create an account"
    echo "Type 'login' to sign in"
fi
echo "Type 'help' for available commands"
echo "----------------------------------------"

# Main command loop
while true; do
    # Display prompt
    echo -n -e "${GREEN}d7log>${NC} "
    
    # Read command
    read -r COMMAND_INPUT
    
    # Process command
    if [ -z "$COMMAND_INPUT" ]; then
        # Empty input, do nothing
        continue
    elif [ "$COMMAND_INPUT" = "exit" ]; then
        # Exit command
        echo "Exiting d7log CLI. Goodbye!"
        break
    elif [ "$COMMAND_INPUT" = "help" ]; then
        # Help command
        show_help
    elif [ "$COMMAND_INPUT" = "clear" ] || [ "$COMMAND_INPUT" = "cls" ]; then
        # Clear screen command
        clear_screen
        # Redisplay header after clearing
        echo -e "${BLUE}D7LOG JOURNAL SYSTEM${NC}"
        echo "----------------------------------------"
        if check_auth; then
            USERNAME=$(get_username)
            echo -e "User: ${BLUE}$USERNAME${NC}"
        else
            echo -e "Status: ${YELLOW}Not logged in${NC}"
            echo "Type 'register' to create an account"
            echo "Type 'login' to sign in"
        fi
        echo "Type 'help' for available commands"
        echo "----------------------------------------"
    elif [ "$COMMAND_INPUT" = "login" ]; then
        # Login command
        run_login
    elif [ "$COMMAND_INPUT" = "register" ]; then
        # Registration command
        run_register
    elif [ "$COMMAND_INPUT" = "template-run" ]; then
        # Template command
        run_template
    elif [ "$COMMAND_INPUT" = "edit" ]; then
        # Edit command - edit the journal content
        open_editor
    elif [[ "$COMMAND_INPUT" == push* ]]; then
        # Push command
        ENTRY_TITLE="${COMMAND_INPUT#push }"
        ENTRY_TITLE="${ENTRY_TITLE#\"}"
        ENTRY_TITLE="${ENTRY_TITLE%\"}"
        
        run_push "$ENTRY_TITLE"
    else
        # Not a recognized command
        echo -e "${YELLOW}Unknown command: $COMMAND_INPUT${NC}"
        echo "Type 'help' to see available commands."
    fi
done

# Add footer to log file
echo "----------------------------------------" >> "$LOG_FILE"
echo "# End of session - $(date)" >> "$LOG_FILE"

exit 0