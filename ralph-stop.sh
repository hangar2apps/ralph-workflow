#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
  echo "Usage: $0 <project-feature | all>"
  echo ""
  echo "Examples:"
  echo "  $0 myapp-auth          # Stop specific container"
  echo "  $0 all                 # Stop all Ralph containers"
  exit 1
}

TARGET="$1"

if [[ -z "$TARGET" ]]; then
  usage
fi

if [[ "$TARGET" == "all" ]]; then
  echo -e "${YELLOW}Stopping all Ralph containers...${NC}"
  docker ps -a --filter "name=ralph-" --format "{{.Names}}" | while read -r container; do
    echo "Stopping $container..."
    docker stop "$container" 2>/dev/null || true
    docker rm "$container" 2>/dev/null || true
  done
  echo -e "${GREEN}Done${NC}"
else
  CONTAINER_NAME="ralph-$TARGET"
  
  if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Container $CONTAINER_NAME not found${NC}"
    echo ""
    echo "Running containers:"
    docker ps -a --filter "name=ralph-" --format "  {{.Names}}"
    exit 1
  fi
  
  echo "Stopping $CONTAINER_NAME..."
  docker stop "$CONTAINER_NAME" 2>/dev/null || true
  docker rm "$CONTAINER_NAME" 2>/dev/null || true
  echo -e "${GREEN}Done${NC}"
fi
