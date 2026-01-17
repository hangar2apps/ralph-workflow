#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Ralph Containers ===${NC}"
echo ""

# Get all ralph containers
CONTAINERS=$(docker ps -a --filter "name=ralph-" --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}")

if [[ -z "$CONTAINERS" ]] || [[ "$CONTAINERS" == "NAMES"* && $(echo "$CONTAINERS" | wc -l) -eq 1 ]]; then
  echo "No Ralph containers found."
else
  echo "$CONTAINERS"
fi

echo ""
echo -e "${CYAN}=== Signal API ===${NC}"
echo ""

if docker ps --format '{{.Names}}' | grep -q "signal-cli-rest-api"; then
  echo -e "${GREEN}signal-cli-rest-api is running${NC}"
  
  # Check if we can reach it
  if curl -s http://localhost:8080/v1/about > /dev/null 2>&1; then
    echo "API responding at http://localhost:8080"
  else
    echo -e "${YELLOW}Warning: API not responding${NC}"
  fi
else
  echo -e "${YELLOW}signal-cli-rest-api is not running${NC}"
  echo "Start it with: docker-compose up -d"
fi

echo ""
echo -e "${CYAN}=== Worktrees ===${NC}"
echo ""

WORKTREES_DIR="${WORKTREES_DIR:-$HOME/worktrees}"

if [[ -d "$WORKTREES_DIR" ]]; then
  find "$WORKTREES_DIR" -mindepth 2 -maxdepth 2 -type d | while read -r worktree; do
    project=$(basename "$(dirname "$worktree")")
    feature=$(basename "$worktree")
    
    # Check if there's a matching container
    container_name="ralph-$project-$feature"
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
      status="${GREEN}running${NC}"
    elif docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
      status="${YELLOW}stopped${NC}"
    else
      status="no container"
    fi
    
    # Check PRD progress
    prd_file="$worktree/plans/prd.json"
    if [[ -f "$prd_file" ]]; then
      total=$(jq '.stories | length' "$prd_file" 2>/dev/null || echo "?")
      done=$(jq '[.stories[] | select(.passes == true)] | length' "$prd_file" 2>/dev/null || echo "?")
      progress="$done/$total stories"
    else
      progress="no PRD"
    fi
    
    echo -e "$project/$feature - $status - $progress"
  done
else
  echo "No worktrees directory at $WORKTREES_DIR"
fi
