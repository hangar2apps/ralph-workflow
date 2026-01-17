# Ralph Workflow Usage Guide

## One-Time Setup

### 1. Configure environment

```bash
cd ~/ralph-workflow
cp .env.example .env
nano .env
```

Set these values:
```
SIGNAL_API_URL=http://signal-cli-rest-api:8080
SIGNAL_BOT_NUMBER=+1XXXXXXXXXX
SIGNAL_USER_NUMBER=+1XXXXXXXXXX
SIGNAL_ME_PLUGIN_PATH=~/Documents/Hangar2Apps-Github/signal-me
WORKTREES_DIR=~/worktrees
RALPH_MAX_ITERATIONS=30
```

### 2. Start Signal API

```bash
cd ~/ralph-workflow
docker-compose up -d
```

If you get a "container name already in use" error, your signal-me container is already running. Just connect it to the ralph network:

```bash
docker network connect ralph-network signal-cli-rest-api
```

### 3. Verify Signal API

```bash
curl http://localhost:8080/v1/about
```

If this is your first time, link your Signal account:
```bash
curl -X GET "http://localhost:8080/v1/qrcodelink?device_name=ralph-bot" -o qrcode.png
open qrcode.png
# Scan with Signal app: Settings > Linked Devices > Link New Device
```

---

## Starting a Feature

### 1. Run ralph-start

```bash
cd ~/ralph-workflow

# Side projects
./ralph-start.sh ~/Documents/Hangar2Apps-Github/PROJECT_NAME FEATURE_NAME "Description"

# Work projects
./ralph-start.sh ~/Documents/ITG-GitHub/PROJECT_NAME FEATURE_NAME "Description"
```

**Examples:**
```bash
./ralph-start.sh ~/Documents/Hangar2Apps-Github/scooperhero auth "Add user authentication with Supabase"
./ralph-start.sh ~/Documents/ITG-GitHub/orapath dashboard "Build admin dashboard"
```

### 2. (Optional) Edit PRD for detailed tasks

The script creates a basic single-task PRD. For better results, break it into smaller stories:

```bash
nano ~/worktrees/PROJECT_NAME/FEATURE_NAME/plans/prd.json
```

Example PRD with multiple stories:
```json
{
  "feature": "auth",
  "description": "Add user authentication with Supabase",
  "tech_context": {
    "frontend": "React/Next.js with TypeScript",
    "styling": "Tailwind CSS",
    "backend": "Supabase (Postgres + Auth + Edge Functions)",
    "testing": "Run npm run typecheck and npm run lint after changes"
  },
  "stories": [
    {
      "id": 1,
      "story": "User can sign up with email/password",
      "acceptance": [
        "Sign up form at /signup",
        "Validates email format",
        "Password requires 8+ chars",
        "Creates user in Supabase"
      ],
      "passes": false,
      "notes": ""
    },
    {
      "id": 2,
      "story": "User can log in",
      "acceptance": [
        "Login form at /login",
        "Redirects to /dashboard on success",
        "Shows error on bad credentials"
      ],
      "passes": false,
      "notes": ""
    },
    {
      "id": 3,
      "story": "User can log out",
      "acceptance": [
        "Logout button in header",
        "Clears session",
        "Redirects to /login"
      ],
      "passes": false,
      "notes": ""
    }
  ]
}
```

### 3. Watch logs

```bash
docker logs -f ralph-PROJECT_NAME-FEATURE_NAME
```

Example:
```bash
docker logs -f ralph-scooperhero-auth
```

---

## While Running

### Check status of all features

```bash
./ralph-status.sh
```

### Respond to Signal messages

| Message | What to do |
|---------|------------|
| "Starting story #1..." | No response needed |
| "Stuck: [problem]" | Reply with guidance |
| "Completed all stories!" | Time to review |

### Stop a feature

```bash
# Stop specific feature
./ralph-stop.sh PROJECT_NAME-FEATURE_NAME

# Example
./ralph-stop.sh scooperhero-auth

# Stop all
./ralph-stop.sh all
```

---

## When Complete

### 1. Review the work

```bash
cd ~/worktrees/PROJECT_NAME/FEATURE_NAME

# See commits
git log --oneline

# See all changes vs main
git diff main

# Check the code
code .
```

### 2. Merge if happy

```bash
# Go to original repo
cd ~/Documents/Hangar2Apps-Github/PROJECT_NAME
# or
cd ~/Documents/ITG-GitHub/PROJECT_NAME

# Merge the feature branch
git merge feature/FEATURE_NAME

# Push if desired
git push
```

### 3. Clean up

```bash
# Remove the worktree
git worktree remove ~/worktrees/PROJECT_NAME/FEATURE_NAME

# Remove the container (if not already stopped)
docker rm ralph-PROJECT_NAME-FEATURE_NAME
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Start Signal API | `docker-compose up -d` |
| Check Signal API | `curl http://localhost:8080/v1/about` |
| Start feature | `./ralph-start.sh <project-path> <feature> "description"` |
| Check all status | `./ralph-status.sh` |
| View logs | `docker logs -f ralph-<project>-<feature>` |
| Stop feature | `./ralph-stop.sh <project>-<feature>` |
| Stop all | `./ralph-stop.sh all` |
| Create detailed PRD | `./ralph-create-prd.sh ~/worktrees/<project>/<feature>` |

---

## Troubleshooting

### Container exits immediately

```bash
# Check why it failed
docker logs ralph-PROJECT_NAME-FEATURE_NAME
```

### Signal messages not sending

```bash
# Check Signal API is running
docker ps | grep signal

# Check it's on ralph-network
docker network inspect ralph-network

# Test sending manually
curl -X POST http://localhost:8080/v2/send \
  -H "Content-Type: application/json" \
  -d '{"message": "Test", "number": "+1BOTNUM", "recipients": ["+1YOURNUM"]}'
```

### Worktree conflicts

```bash
# List all worktrees
cd ~/Documents/Hangar2Apps-Github/PROJECT_NAME
git worktree list

# Remove a stale worktree
git worktree remove ~/worktrees/PROJECT_NAME/FEATURE_NAME --force
```

### Need to restart a feature

```bash
./ralph-stop.sh PROJECT_NAME-FEATURE_NAME
./ralph-start.sh ~/path/to/project FEATURE_NAME
# It will detect existing worktree and ask to continue
```
