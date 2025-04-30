#!/bin/bash

# push.sh - Script for pushing log template to API and saving to logs

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

# Check if jq is installed - helps with JSON modification
if ! command_exists jq; then
    echo -e "${YELLOW}Warning: jq is not installed. Using basic JSON handling.${NC}"
fi

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

# Function to get timezone from auth.json
get_timezone() {
    if [ -f "$SCRIPT_DIR/auth.json" ]; then
        TZ=$(grep -o '"timezone"[[:space:]]*:[[:space:]]*"[^"]*"' "$SCRIPT_DIR/auth.json" | cut -d'"' -f4)
        if [ -z "$TZ" ]; then
            echo "UTC"
        else
            echo "$TZ"
        fi
    else
        echo "UTC"
    fi
}

# Create required directories
mkdir -p "$SCRIPT_DIR/logs"
mkdir -p "$SCRIPT_DIR/templates"

# Get timestamps - using day-level timestamp for filenames
DAY_TIMESTAMP=$(date +"%Y%m%d")
ISO_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
READABLE_DATE=$(date +"%A, %B %d, %Y")

# Get title/message
ENTRY_TITLE="$*"

# Check if user is logged in
if ! check_auth; then
    echo -e "${YELLOW}You are not logged in.${NC}"
    echo "Please login first with:"
    echo -e "${BLUE}  ./d7log.sh login${NC}"
    echo "or"
    echo -e "${BLUE}  login${NC} (at the d7log prompt)"
    exit 1
fi

# Check if title is provided
if [ -z "$ENTRY_TITLE" ]; then
    ENTRY_TITLE="Journal Entry - $READABLE_DATE"
fi

# Get username and timezone
USERNAME=$(get_username)
TIMEZONE=$(get_timezone)

# Check for daily template
DAILY_TEMPLATE="$SCRIPT_DIR/templates/entry_${DAY_TIMESTAMP}.json"

# If no daily template exists, create one but don't open editor
if [ ! -f "$DAILY_TEMPLATE" ]; then
    echo -e "${YELLOW}No template for today found. Creating new template...${NC}"
    
    # Create a simple JSON template
    cat > "$DAILY_TEMPLATE" << EOF
{
  "entry": {
    "id": "${DAY_TIMESTAMP}",
    "date": "${READABLE_DATE}",
    "author": "${USERNAME}",
    "title": "${ENTRY_TITLE}",
    "content": "",
    "mood": "neutral"
  }
}
EOF

    echo -e "${YELLOW}Template created at:${NC} $DAILY_TEMPLATE"
    echo -e "${RED}You need to edit this file manually before pushing.${NC}"
    echo -e "Use your preferred editor (nano, vim, etc.) to add content to your journal entry."
    echo -e "Once edited, run this push command again to save your journal."
    exit 0
else
    echo -e "${YELLOW}Using today's template:${NC} $(basename "$DAILY_TEMPLATE")"

    # Check if template has content
    if command_exists jq; then
        # Extract content from template using jq
        CONTENT=$(jq -r '.entry.content' "$DAILY_TEMPLATE" 2>/dev/null)
    else
        # Basic method - check if content field is empty
        CONTENT=$(grep -o '"content"[[:space:]]*:[[:space:]]*"[^"]*"' "$DAILY_TEMPLATE" | cut -d'"' -f4)
    fi

    # Check if content is empty
    if [ -z "$CONTENT" ] || [ "$CONTENT" = "null" ] || [ "$CONTENT" = "" ]; then
        echo -e "${RED}Template has no content. Please edit it first:${NC}"
        echo -e "Template path: ${BLUE}$DAILY_TEMPLATE${NC}"
        echo -e "Use your preferred editor to add content, then run this push command again."
        exit 0
    fi
    
    # Update just the title and timestamp
    if command_exists jq; then
        # Create a temporary file for the new JSON
        TMP_JSON=$(mktemp)
        jq ".entry.title = \"$ENTRY_TITLE\" | 
            .entry.timestamp = \"$ISO_TIMESTAMP\"" "$DAILY_TEMPLATE" > "$TMP_JSON" 2>/dev/null
        if [ $? -eq 0 ]; then
            mv "$TMP_JSON" "$DAILY_TEMPLATE"
        else
            rm -f "$TMP_JSON"
            # Fall back to simple method
            sed -i.bak "s/\"title\": \"[^\"]*\"/\"title\": \"$ENTRY_TITLE\"/" "$DAILY_TEMPLATE"
            rm -f "$DAILY_TEMPLATE.bak"
        fi
    else
        # Basic text replacement as fallback
        sed -i.bak "s/\"title\": \"[^\"]*\"/\"title\": \"$ENTRY_TITLE\"/" "$DAILY_TEMPLATE"
        rm -f "$DAILY_TEMPLATE.bak"
    fi
fi

# Prepare log file path - use day-level timestamp
LOG_FILE="$SCRIPT_DIR/logs/journal_${DAY_TIMESTAMP}.json"

# Copy the updated template to the logs directory
cp "$DAILY_TEMPLATE" "$LOG_FILE"

# Simulate API push
echo -e "${YELLOW}Saving your journal entry...${NC}"

# In a real implementation, you would use curl to push to the actual API
# Example:
# curl -s -X POST "https://api.example.com/logs" \
#    -H "Content-Type: application/json" \
#    -H "Authorization: Bearer $(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' "$SCRIPT_DIR/auth.json" | cut -d'"' -f4)" \
#    -d @"$LOG_FILE"

# Simulate API delay
sleep 1

# Remove the template file after successful push
rm -f "$DAILY_TEMPLATE"

# Simulate successful response
echo -e "${GREEN}✓ Journal entry saved!${NC}"
echo -e "${GREEN}✓ Entry saved to:${NC} $(basename "$LOG_FILE")"

exit 0