#!/bin/bash
set -e

MAX=${1:-10}
SLEEP=${2:-2}

echo "Starting Ralph - Max $MAX iterations"
echo ""

for ((i=1; i<=$MAX; i++)); do
    echo "==========================================="
    echo "  Iteration $i of $MAX"
    echo "==========================================="

    result=$(claude --dangerously-skip-permissions -p "You are Ralph, an autonomous coding agent. Do exactly ONE task per iteration.

## Steps

1. Read PRD.md and find the first task that is NOT complete (marked [ ]).
2. Read progress.txt - check the Learnings section first for patterns from previous iterations.
3. Implement that ONE task only.
4. Run tests/typecheck to verify it works.

## Critical: Only Complete If Tests Pass

- If tests PASS:
  - Update PRD.md to mark the task complete (change [ ] to [x])
  - Commit your changes with message: feat: [task description]
  - Append what worked to progress.txt

- If tests FAIL:
  - Do NOT mark the task complete
  - Do NOT commit broken code
  - Append what went wrong to progress.txt (so next iteration can learn)

## Progress Notes Format

Append to progress.txt using this format:

## Iteration [N] - [Task Name]
- What was implemented
- Files changed
- Learnings for future iterations:
  - Patterns discovered
  - Gotchas encountered
  - Useful context
---

## Manual Steps Required

If your implementation requires ANY manual action from the user, add to progress.txt:

### Manual Steps Required
- [ ] Database: Create table X / Add column Y / Run migration
- [ ] Environment: Add VAR_NAME to .env  
- [ ] Deployment: Deploy edge function X
- [ ] External: Configure webhook at URL
- [ ] Other: Any other manual steps

Be specific - include exact SQL, exact env var names, exact commands needed.

## Project Documentation

Always maintain a SETUP.md file in the project root with:
- **Setup Instructions**: Step-by-step guide for any required manual steps (account creation, SQL migrations, environment variables, API keys, etc.)
- **Project Overview**: What the project is and what problem it solves
- **Usage Guide**: How to use the completed features

Update this file as you complete tasks. If it doesn't exist, create it. If you add new features that require setup or usage instructions, add them to SETUP.md.

## Signal Notifications

Use the signal-me plugin to message me:
- At the START of this iteration (which task you're working on)
- If you get STUCK and need help (then STOP and wait - do not keep trying)
- When ALL tasks are complete

## Update AGENTS.md (If Applicable)

If you discover a reusable pattern that future work should know about:
- Check if AGENTS.md exists in the project root
- Add patterns like: 'This codebase uses X for Y' or 'Always do Z when changing W'
- Only add genuinely reusable knowledge, not task-specific details

## End Condition

After completing your task, check PRD.md:
- If ALL tasks are [x], output exactly: <promise>COMPLETE</promise>
- If tasks remain [ ], just end your response (next iteration will continue)")

    echo "$result"
    echo ""

    if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
        echo "==========================================="
        echo "  All tasks complete after $i iterations!"
        echo "==========================================="
        exit 0
    fi

    sleep $SLEEP
done

echo "==========================================="
echo "  Reached max iterations ($MAX)"
echo "==========================================="
exit 1