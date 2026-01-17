#!/bin/bash
set -e

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  source "$SCRIPT_DIR/.env"
fi

# Defaults
WORKTREES_DIR="${WORKTREES_DIR:-$HOME/worktrees}"
RALPH_MAX_ITERATIONS="${RALPH_MAX_ITERATIONS:-30}"
SIGNAL_ME_PLUGIN_PATH="${SIGNAL_ME_PLUGIN_PATH:-$HOME/Documents/Hangar2Apps-Github/signal-me}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
  echo "Usage: $0 <project-path> <feature-name> [description]"
  echo ""
  echo "Examples:"
  echo "  $0 ~/Documents/Hangar2Apps-Github/scooperhero auth 'Implement user authentication'"
  echo "  $0 ~/Documents/ITG-GitHub/orapath dashboard 'Build admin dashboard'"
  echo ""
  echo "This will:"
  echo "  1. Create a git worktree at ~/worktrees/<project>/<feature>/"
  echo "  2. Create a new branch feature/<feature>"
  echo "  3. Generate plans/prd.json"
  echo "  4. Start a Docker container running Claude Code + Ralph"
  exit 1
}

# Parse arguments
PROJECT_PATH="${1/#\~/$HOME}"  # Expand ~ to $HOME
FEATURE_NAME="$2"
DESCRIPTION="$3"

if [[ -z "$PROJECT_PATH" ]] || [[ -z "$FEATURE_NAME" ]]; then
  usage
fi

# Derive paths
PROJECT_NAME=$(basename "$PROJECT_PATH")
WORKTREE_PATH="$WORKTREES_DIR/$PROJECT_NAME/$FEATURE_NAME"
BRANCH_NAME="feature/$FEATURE_NAME"
CONTAINER_NAME="ralph-$PROJECT_NAME-$FEATURE_NAME"

# Validate project exists
if [[ ! -d "$PROJECT_PATH/.git" ]]; then
  echo -e "${RED}Error: $PROJECT_PATH is not a git repository${NC}"
  exit 1
fi

# Check if worktree already exists
if [[ -d "$WORKTREE_PATH" ]]; then
  echo -e "${YELLOW}Worktree already exists at $WORKTREE_PATH${NC}"
  read -p "Do you want to continue with existing worktree? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
else
  # Create worktree directory
  mkdir -p "$(dirname "$WORKTREE_PATH")"
  
  # Create the worktree with a new branch
  echo -e "${GREEN}Creating worktree...${NC}"
  cd "$PROJECT_PATH"
  git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" 2>/dev/null || \
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
fi

# Create plans directory
mkdir -p "$WORKTREE_PATH/plans"

# Generate PRD if description provided
if [[ -n "$DESCRIPTION" ]] && [[ ! -f "$WORKTREE_PATH/plans/prd.json" ]]; then
  echo -e "${GREEN}Generating PRD...${NC}"
  cat > "$WORKTREE_PATH/plans/prd.json" << EOF
{
  "feature": "$FEATURE_NAME",
  "description": "$DESCRIPTION",
  "tech_context": {
    "frontend": "React/Next.js with TypeScript",
    "styling": "Tailwind CSS", 
    "backend": "Supabase (Postgres + Auth + Edge Functions)",
    "testing": "Run npm run typecheck and npm run lint after changes"
  },
  "stories": [
    {
      "id": 1,
      "story": "$DESCRIPTION",
      "acceptance": [
        "Feature is fully implemented",
        "TypeScript compiles without errors",
        "Linting passes",
        "Code is committed"
      ],
      "passes": false,
      "notes": ""
    }
  ]
}
EOF
  echo -e "${YELLOW}Created basic PRD. Edit $WORKTREE_PATH/plans/prd.json to add detailed stories.${NC}"
fi

# Create empty progress file
touch "$WORKTREE_PATH/plans/progress.txt"

# Check if container already running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo -e "${YELLOW}Container $CONTAINER_NAME is already running${NC}"
  echo "Use: docker logs -f $CONTAINER_NAME"
  exit 0
fi

# Build the Ralph prompt
RALPH_PROMPT='You are working through a PRD (Product Requirements Document). 

INSTRUCTIONS:
1. Read plans/prd.json to see all tasks
2. Find the highest priority story that has "passes": false
3. Implement ONLY that one story
4. Run typecheck and lint to verify
5. Update prd.json: set "passes": true for completed story
6. Append learnings to plans/progress.txt
7. Git commit with message: "feat(<story-id>): <brief description>"
8. If ALL stories have "passes": true, output <promise>COMPLETE</promise>

SIGNAL NOTIFICATIONS (use signal-me plugin):
- Send a message when you START a new story
- Send a message if you are STUCK and need help
- Send a message when you COMPLETE all stories
- If stuck for more than 2 attempts, message me and WAIT for my reply before continuing

RULES:
- Work on ONE story at a time
- Always verify with typecheck/lint before marking complete
- Small, focused commits

Begin by reading the PRD and sending me a Signal message with your plan.'

echo -e "${GREEN}Starting container $CONTAINER_NAME...${NC}"

# Run the container
docker run -d \
  --name "$CONTAINER_NAME" \
  --network ralph-network \
  -v "$WORKTREE_PATH":/workspace \
  -v "$HOME/.claude":/root/.claude \
  -v "$HOME/.ssh":/root/.ssh:ro \
  -v "$HOME/.gitconfig":/root/.gitconfig:ro \
  -v "$SIGNAL_ME_PLUGIN_PATH":/root/.claude/plugins/signal-me:ro \
  -e SIGNAL_API_URL="${SIGNAL_API_URL:-http://signal-cli-rest-api:8080}" \
  -e SIGNAL_BOT_NUMBER="$SIGNAL_BOT_NUMBER" \
  -e SIGNAL_USER_NUMBER="$SIGNAL_USER_NUMBER" \
  -w /workspace \
  anthropic/claude-code \
  --dangerously-skip-permissions \
  -p "/ralph-loop:ralph-loop \"$RALPH_PROMPT\" --max-iterations $RALPH_MAX_ITERATIONS --completion-promise COMPLETE"

echo ""
echo -e "${GREEN}Started!${NC}"
echo ""
echo "Worktree:  $WORKTREE_PATH"
echo "Branch:    $BRANCH_NAME"
echo "Container: $CONTAINER_NAME"
echo ""
echo "Commands:"
echo "  View logs:     docker logs -f $CONTAINER_NAME"
echo "  Stop:          docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
echo "  Shell in:      docker exec -it $CONTAINER_NAME /bin/bash"
echo ""
echo "When complete:"
echo "  cd $PROJECT_PATH"
echo "  git merge $BRANCH_NAME"
echo "  git worktree remove $WORKTREE_PATH"