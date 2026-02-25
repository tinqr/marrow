#!/bin/bash
# Marrow SessionStart hook — detect Marrow, show landscape

# Detection: is this a Marrow directory?
if [ ! -f "./CLAUDE.md" ] || ! grep -q '<!-- marrow:root:v0\.5\.1 -->' "./CLAUDE.md" 2>/dev/null; then
  exit 0
fi

# Write session state
mkdir -p .marrow
date +%s > .marrow/session-start
rm -f .marrow/checkpoint-reminded

# --- Build landscape output ---

echo "=== marrow ==="

if [ ! -f "./projects.md" ]; then
  echo "No projects found. Use /new-project to create one."
  echo "==============="
  exit 0
fi

# Parse projects.md for project info
current_project=""
current_status=""
first_activity=""
printed_header=0
active_count=0
paused_count=0
done_count=0
stale_projects=""
now_epoch=$(date +%s)

print_project() {
  if [ -z "$1" ]; then return; fi
  local proj="$1" status="$2" activity="$3"

  case "$status" in
    active) active_count=$((active_count + 1)) ;;
    paused) paused_count=$((paused_count + 1)) ;;
    done)   done_count=$((done_count + 1)) ;;
  esac
}

# First pass: count projects
while IFS= read -r line; do
  if [[ "$line" =~ ^##\  ]] && [[ ! "$line" =~ ^### ]]; then
    if [ -n "$current_project" ]; then
      print_project "$current_project" "$current_status" "$first_activity"
    fi
    current_project="${line#\#\# }"
    current_status=""
    first_activity=""
  elif [[ "$line" =~ ^Status:\  ]]; then
    current_status="${line#Status: }"
    current_status="${current_status%% *}"
  elif [[ "$line" =~ ^-\  ]] && [ -z "$first_activity" ] && [ -n "$current_project" ]; then
    first_activity="$line"
  fi
done < "./projects.md"
# Don't forget the last project
if [ -n "$current_project" ]; then
  print_project "$current_project" "$current_status" "$first_activity"
fi

total=$((active_count + paused_count + done_count))
echo "Projects: $total ($active_count active, $paused_count paused, $done_count done)"
echo ""

# Second pass: display active projects with details
current_project=""
current_status=""
first_activity=""
in_activity=0
displayed=0

while IFS= read -r line; do
  if [[ "$line" =~ ^##\  ]] && [[ ! "$line" =~ ^### ]]; then
    # Print previous project if active
    if [ -n "$current_project" ] && [ "$current_status" = "active" ]; then
      echo "$current_project"
      if [ -n "$first_activity" ]; then
        echo "  ${first_activity#- }"
      fi
      # Count notes in project directory
      if [ -d "./$current_project" ]; then
        note_names=""
        note_count=0
        for f in "./$current_project"/*.md; do
          [ -f "$f" ] || continue
          bn=$(basename "$f" .md)
          case "$bn" in CLAUDE|index|session-archive) continue ;; esac
          note_count=$((note_count + 1))
          if [ $note_count -le 5 ]; then
            [ -n "$note_names" ] && note_names="$note_names, "
            note_names="$note_names$bn"
          fi
        done
        if [ $note_count -gt 0 ]; then
          if [ $note_count -gt 5 ]; then
            extra=$((note_count - 5))
            echo "  Notes: $note_names (+$extra more)"
          else
            echo "  Notes: $note_names"
          fi
        fi
      fi
      # Stale detection: check if last activity > 7 days
      if [ -n "$first_activity" ]; then
        if [[ "$first_activity" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
          activity_date="${BASH_REMATCH[1]}"
          activity_epoch=$(date -j -f "%Y-%m-%d" "$activity_date" "+%s" 2>/dev/null || echo 0)
          if [ "$activity_epoch" -gt 0 ]; then
            days_ago=$(( (now_epoch - activity_epoch) / 86400 ))
            if [ "$days_ago" -ge 7 ]; then
              stale_projects="$stale_projects  $current_project — last activity $activity_date (${days_ago}d ago)\n"
            fi
          fi
        fi
      fi
      displayed=$((displayed + 1))
    fi
    current_project="${line#\#\# }"
    current_status=""
    first_activity=""
    in_activity=0
  elif [[ "$line" =~ ^Status:\  ]]; then
    current_status="${line#Status: }"
    current_status="${current_status%% *}"
  elif [[ "$line" =~ ^###\ Activity ]]; then
    in_activity=1
  elif [ "$in_activity" -eq 1 ] && [[ "$line" =~ ^-\  ]] && [ -z "$first_activity" ]; then
    first_activity="$line"
  elif [[ "$line" =~ ^## ]] || [[ "$line" =~ ^# ]]; then
    in_activity=0
  fi
done < "./projects.md"

# Print last project
if [ -n "$current_project" ] && [ "$current_status" = "active" ]; then
  echo "$current_project"
  if [ -n "$first_activity" ]; then
    echo "  ${first_activity#- }"
  fi
  if [ -d "./$current_project" ]; then
    note_names=""
    note_count=0
    for f in "./$current_project"/*.md; do
      [ -f "$f" ] || continue
      bn=$(basename "$f" .md)
      case "$bn" in CLAUDE|index|session-archive) continue ;; esac
      note_count=$((note_count + 1))
      if [ $note_count -le 5 ]; then
        [ -n "$note_names" ] && note_names="$note_names, "
        note_names="$note_names$bn"
      fi
    done
    if [ $note_count -gt 0 ]; then
      if [ $note_count -gt 5 ]; then
        extra=$((note_count - 5))
        echo "  Notes: $note_names (+$extra more)"
      else
        echo "  Notes: $note_names"
      fi
    fi
  fi
  if [ -n "$first_activity" ]; then
    if [[ "$first_activity" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
      activity_date="${BASH_REMATCH[1]}"
      activity_epoch=$(date -j -f "%Y-%m-%d" "$activity_date" "+%s" 2>/dev/null || echo 0)
      if [ "$activity_epoch" -gt 0 ]; then
        days_ago=$(( (now_epoch - activity_epoch) / 86400 ))
        if [ "$days_ago" -ge 7 ]; then
          stale_projects="$stale_projects  $current_project — last activity $activity_date (${days_ago}d ago)\n"
        fi
      fi
    fi
  fi
fi

# Stale warnings
if [ -n "$stale_projects" ]; then
  echo ""
  echo "## Stale (no checkpoint in 7+ days)"
  printf "$stale_projects"
fi

# Paused projects
current_project=""
current_status=""
has_paused=0
while IFS= read -r line; do
  if [[ "$line" =~ ^##\  ]] && [[ ! "$line" =~ ^### ]]; then
    if [ -n "$current_project" ] && [ "$current_status" = "paused" ]; then
      if [ "$has_paused" -eq 0 ]; then
        echo ""
        echo "## Paused"
        has_paused=1
      fi
      echo "  $current_project"
    fi
    current_project="${line#\#\# }"
    current_status=""
  elif [[ "$line" =~ ^Status:\  ]]; then
    current_status="${line#Status: }"
    current_status="${current_status%% *}"
  fi
done < "./projects.md"
if [ -n "$current_project" ] && [ "$current_status" = "paused" ]; then
  if [ "$has_paused" -eq 0 ]; then
    echo ""
    echo "## Paused"
  fi
  echo "  $current_project"
fi

echo ""
echo "Commands: /recall <project> · /checkpoint · /new-project"
echo "==============="
