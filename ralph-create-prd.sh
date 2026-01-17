#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
  echo "Usage: $0 <worktree-path>"
  echo ""
  echo "Interactively create a PRD for a feature."
  echo ""
  echo "Example:"
  echo "  $0 ~/worktrees/myapp/feature-auth"
  exit 1
}

WORKTREE_PATH="$1"

if [[ -z "$WORKTREE_PATH" ]]; then
  usage
fi

if [[ ! -d "$WORKTREE_PATH" ]]; then
  echo "Error: $WORKTREE_PATH does not exist"
  exit 1
fi

PRD_FILE="$WORKTREE_PATH/plans/prd.json"
mkdir -p "$WORKTREE_PATH/plans"

echo -e "${CYAN}=== PRD Creator ===${NC}"
echo ""

# Feature name
read -p "Feature name: " FEATURE_NAME

# Description
read -p "Brief description: " DESCRIPTION

echo ""
echo -e "${YELLOW}Now enter user stories. Each story should be small and testable.${NC}"
echo "Enter an empty story to finish."
echo ""

STORIES="[]"
STORY_ID=1

while true; do
  echo -e "${GREEN}Story #$STORY_ID${NC}"
  read -p "  User story (or empty to finish): " STORY
  
  if [[ -z "$STORY" ]]; then
    break
  fi
  
  echo "  Acceptance criteria (one per line, empty line to finish):"
  ACCEPTANCE="[]"
  while true; do
    read -p "    - " CRITERION
    if [[ -z "$CRITERION" ]]; then
      break
    fi
    ACCEPTANCE=$(echo "$ACCEPTANCE" | jq --arg c "$CRITERION" '. + [$c]')
  done
  
  # Add story to array
  STORIES=$(echo "$STORIES" | jq \
    --arg story "$STORY" \
    --argjson id "$STORY_ID" \
    --argjson acceptance "$ACCEPTANCE" \
    '. + [{
      "id": $id,
      "story": $story,
      "acceptance": $acceptance,
      "passes": false,
      "notes": ""
    }]')
  
  ((STORY_ID++))
  echo ""
done

# Build final PRD
PRD=$(jq -n \
  --arg feature "$FEATURE_NAME" \
  --arg description "$DESCRIPTION" \
  --argjson stories "$STORIES" \
  '{
    "feature": $feature,
    "description": $description,
    "tech_context": {
      "frontend": "React/Next.js with TypeScript",
      "styling": "Tailwind CSS",
      "backend": "Supabase (Postgres + Auth + Edge Functions)",
      "testing": "Run npm run typecheck and npm run lint after changes"
    },
    "stories": $stories
  }')

echo "$PRD" > "$PRD_FILE"

echo ""
echo -e "${GREEN}PRD saved to $PRD_FILE${NC}"
echo ""
echo "Stories created: $((STORY_ID - 1))"
echo ""
echo "You can edit $PRD_FILE directly to make changes."
