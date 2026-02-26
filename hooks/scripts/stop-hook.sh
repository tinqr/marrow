#!/bin/bash
# Marrow Stop hook — checkpoint reminder
# Fires after every agent turn. Guards prevent spam.

# Guard 1: Is this a Marrow session?
# (session-start file is written by SessionStart hook)
if [ ! -f ".marrow/session-start" ]; then
  exit 0
fi

# Guard 2: Already reminded this session?
if [ -f ".marrow/checkpoint-reminded" ]; then
  exit 0
fi

# Guard 3: Already checkpointed this session?
if [ -f ".marrow/last-checkpoint" ]; then
  last_cp=$(cat .marrow/last-checkpoint 2>/dev/null || echo 0)
  session_start=$(cat .marrow/session-start 2>/dev/null || echo 0)
  if [ "$last_cp" -ge "$session_start" ] 2>/dev/null; then
    exit 0
  fi
fi

# Guard 4: Session too short? (< 20 minutes = 1200 seconds)
session_start=$(cat .marrow/session-start 2>/dev/null || echo 0)
now=$(date +%s)
elapsed=$((now - session_start))
if [ "$elapsed" -lt 1200 ] 2>/dev/null; then
  exit 0
fi

# All guards passed — remind once
echo "Hey — you haven't saved this session yet. Run /checkpoint before you go."
touch .marrow/checkpoint-reminded
