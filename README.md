# Ralph Workflow: Parallel AI Coding with Signal Notifications

Run multiple AI coding agents in parallel, each in a sandboxed Docker container, working on separate git worktrees. Get Signal messages when Claude needs input or finishes.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  HOST MACHINE (macOS)                                               │
│                                                                     │
│  ~/projects/myapp/                    (main repo - don't touch)     │
│  ~/worktrees/myapp/                                                 │
│    ├── feature-auth/                  → Container 1                 │
│    ├── feature-dashboard/             → Container 2                 │
│    └── feature-payments/              → Container 3                 │
│                                                                     │
│  ~/ralph-workflow/                                                  │
│    ├── docker-compose.yml             (signal-cli-rest-api)         │
│    ├── ralph-start.sh                 (spin up new feature)         │
│    ├── ralph-status.sh                (check running containers)    │
│    └── prd-template.json              (copy to each worktree)       │
│                                                                     │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
  ┌──────────┐        ┌──────────┐        ┌──────────┐
  │Container1│        │Container2│        │Container3│
  │feature-  │        │feature-  │        │feature-  │
  │auth      │        │dashboard │        │payments  │
  │          │        │          │        │          │
  │ Claude   │        │ Claude   │        │ Claude   │
  │ + Ralph  │        │ + Ralph  │        │ + Ralph  │
  │ + Signal │        │ + Signal │        │ + Signal │
  └────┬─────┘        └────┬─────┘        └────┬─────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           ▼
                 signal-cli-rest-api
                    (shared Docker)
                           │
                           ▼
                      Your Phone
```

## Setup

### 1. Prerequisites

```bash
# Install Docker
brew install --cask docker

# Make sure Docker is running
docker info
```

### 2. Clone this workflow

```bash
git clone <this-repo> ~/ralph-workflow
cd ~/ralph-workflow
```

### 3. Start signal-cli-rest-api

```bash
docker-compose up -d

# Link your Signal account (first time only)
curl -X GET "http://localhost:8080/v1/qrcodelink?device_name=ralph-bot" --output qrcode.png
open qrcode.png
# Scan with Signal app: Settings > Linked Devices > Link New Device

# Verify it worked
curl http://localhost:8080/v1/accounts
```

### 4. Configure environment

```bash
cp .env.example .env
# Edit .env with your values
```

## Usage

### Start a new feature

```bash
# Creates worktree, starts container, kicks off Ralph
./ralph-start.sh myapp feature-auth "Implement user authentication with Supabase"
```

This will:
1. Create `~/worktrees/myapp/feature-auth/` from your repo
2. Create a new git branch `feature/auth`
3. Generate `plans/prd.json` from your description
4. Start a Docker container with Claude Code
5. Run Ralph loop until complete or max iterations

### Check status

```bash
./ralph-status.sh
```

### Stop a feature

```bash
./ralph-stop.sh feature-auth
```

### Review and merge when done

```bash
cd ~/worktrees/myapp/feature-auth
git log --oneline  # See what Claude did
git diff main      # Review changes

# If happy, merge
cd ~/projects/myapp
git merge feature/auth
git worktree remove ~/worktrees/myapp/feature-auth
```

## File Structure in Each Worktree

```
~/worktrees/myapp/feature-auth/
├── plans/
│   ├── prd.json           # Task list with pass/fail status
│   └── progress.txt       # Claude's notes across iterations
├── src/                   # Your actual code
└── ...
```

## PRD Format

The PRD (Product Requirements Document) is how you tell Claude what to build:

```json
{
  "feature": "User Authentication",
  "description": "Implement auth with Supabase",
  "stories": [
    {
      "id": 1,
      "story": "User can sign up with email/password",
      "acceptance": [
        "Sign up form exists at /signup",
        "Form validates email format",
        "Password requires 8+ characters",
        "Successful signup redirects to /dashboard",
        "Error messages display for invalid input"
      ],
      "passes": false
    },
    {
      "id": 2,
      "story": "User can log in",
      "acceptance": [
        "Login form exists at /login",
        "Successful login redirects to /dashboard",
        "Invalid credentials show error"
      ],
      "passes": false
    }
  ]
}
```

## Signal Notifications

Claude will message you when:
- Starting a new task
- Stuck and needs input
- Completed a task
- Finished all tasks
- Hit an error it can't resolve

Reply to the Signal message to give Claude direction.

## Tips

1. **Keep tasks small** - Each story should be completable in one iteration
2. **Be specific** - Detailed acceptance criteria = better results
3. **Check progress.txt** - See what Claude learned/struggled with
4. **Review commits** - Claude commits after each completed story
5. **Start with 1 container** - Get comfortable before parallelizing
