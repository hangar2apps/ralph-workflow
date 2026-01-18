# Ralph Workflow

A bash loop for autonomous AI coding with Claude Code. Each iteration gets fresh context, preventing memory bloat. Get Signal notifications when Claude is done or stuck.

## How It Works
```
ralph.sh loop:
  1. Fresh Claude instance starts
  2. Reads PRD.md (tasks to do)
  3. Reads progress.txt (learnings from previous iterations)
  4. Completes ONE task
  5. Commits, updates PRD, logs progress
  6. Exits → next iteration with fresh context
  7. Repeat until all tasks complete
```

## Setup

### 1. Clone this repo
```bash
git clone https://github.com/hangar2apps/ralph-workflow.git ~/ralph-workflow
```

### 2. Configure environment
```bash
cd ~/ralph-workflow
cp .env.example .env
nano .env
```

Set your Signal numbers:
```
SIGNAL_API_URL=http://localhost:8080
SIGNAL_BOT_NUMBER=+1XXXXXXXXXX
SIGNAL_USER_NUMBER=+1XXXXXXXXXX
```

### 3. Start Signal API
```bash
docker-compose up -d
```

First time only - link your Signal account:
```bash
curl -X GET "http://localhost:8080/v1/qrcodelink?device_name=ralph-bot" -o qrcode.png
open qrcode.png
# Scan with Signal app: Settings > Linked Devices
```

## Usage

### 1. Create a worktree for your feature
```bash
cd ~/path/to/your/project
git worktree add ~/worktrees/projectname/feature -b feature/feature-name
cd ~/worktrees/projectname/feature
```

### 2. Create a PRD
```bash
claude
```

Then tell Claude:
```
Create a PRD for: [describe your feature]
```

Claude will ask clarifying questions, then generate `PRD.md` and `progress.txt`.

### 3. Run Ralph
```bash
~/ralph-workflow/ralph.sh 20
```

The number is max iterations (default 10).

### 4. When complete
```bash
# Review
cd ~/worktrees/projectname/feature
git log --oneline
git diff main

# Merge
cd ~/path/to/your/project
git merge feature/feature-name

# Clean up
git worktree remove ~/worktrees/projectname/feature
```

## Files

| File | Purpose |
|------|---------|
| `ralph.sh` | Main bash loop |
| `skills/prd/SKILL.md` | PRD generator skill for Claude |
| `docker-compose.yml` | Signal API container |
| `.env` | Your Signal configuration |

## Documentation

See [USAGE.md](./USAGE.md) for detailed walkthrough and troubleshooting.

## Requirements

- [Claude Code](https://claude.ai/code) CLI installed
- Docker (for Signal API)
- Git
```

**.env.example:**
```
# Signal Configuration
SIGNAL_API_URL=http://localhost:8080
SIGNAL_BOT_NUMBER=+1234567890
SIGNAL_USER_NUMBER=+0987654321
```

**USAGE.md** - just update lines 13-19 to:
```
Set your Signal numbers:
```
SIGNAL_API_URL=http://localhost:8080
SIGNAL_BOT_NUMBER=+1XXXXXXXXXX
SIGNAL_USER_NUMBER=+1XXXXXXXXXX
```