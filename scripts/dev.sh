#!/bin/bash
# Cuzzo Monorepo Development Launcher
# Quick launcher for opening development workspaces for different applications

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOREPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}🎯 Cuzzo Monorepo Development Launcher${NC}"
echo ""

# If no arguments, show menu
if [ $# -eq 0 ]; then
    echo "Available applications:"
    echo ""
    echo "  1. thiccc   - Fitness tracking iOS app"
    echo ""
    read -p "Select application (1 or name): " choice
    echo ""
    
    case $choice in
        1|thiccc)
            APP="thiccc"
            ;;
        *)
            echo -e "${YELLOW}Invalid selection${NC}"
            exit 1
            ;;
    esac
else
    APP="$1"
fi

# Launch the appropriate application workspace
case $APP in
    thiccc)
        echo -e "${GREEN}Launching Thiccc development workspace...${NC}"
        echo ""
        "$MONOREPO_ROOT/applications/thiccc/scripts/dev-workspace.sh"
        ;;
    *)
        echo -e "${YELLOW}Unknown application: $APP${NC}"
        echo ""
        echo "Available applications:"
        echo "  • thiccc"
        exit 1
        ;;
esac


