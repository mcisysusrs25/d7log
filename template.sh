#!/bin/bash

# template.sh - Script for generating a new log template

# Define colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

# Check if user is logged in
if ! check_auth; then
    echo -e "${YELLOW}You are not logged in.${NC}"
    echo "Please login first with:"
    echo -e "${BLUE}  ./d7log.sh login${NC}"
    echo "or"
    echo -e "${BLUE}  login${NC} (at the d7log prompt)"
    exit 1
fi

# Generate timestamps - use only day-level timestamp
TODAY=$(date +"%Y%m%d")
READABLE_DATE=$(date +"%A, %B %d, %Y")

# Create template directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/templates"

# Template filename with day timestamp only
TEMPLATE_FILE="$SCRIPT_DIR/templates/entry_${TODAY}.json"

# Check if template already exists
if [ -f "$TEMPLATE_FILE" ]; then
    echo -e "${YELLOW}A journal template for today already exists.${NC}"
    echo -e "You can edit it with:${NC}"
    echo -e "${BLUE}  edit${NC} (at the d7log prompt)"
    exit 0
fi

# Get username
USERNAME=$(get_username)

# Create a simple JSON template
cat > "$TEMPLATE_FILE" << EOF
{
  "entry": {
    "id": "${TODAY}",
    "date": "${READABLE_DATE}",
    "author": "${USERNAME}",
    "title": "Today's Journal",
    "content": "",
    "mood": "neutral"
  }
}
EOF

echo -e "${GREEN}✓ Journal template created${NC}"
echo -e "${YELLOW}How was your day today?${NC}"
echo -e "${YELLOW}Tell me what's on your mind...${NC}"
echo ""
echo "You can now edit your journal:"
echo -e "${BLUE}  edit${NC} (at the d7log prompt)"
echo ""
echo "After writing your thoughts, save them with:"
echo -e "${BLUE}  push \"Today's reflections\"${NC}"

exit 0