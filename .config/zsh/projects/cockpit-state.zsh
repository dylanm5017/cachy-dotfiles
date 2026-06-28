_cockpit_state_dir() {
  print -r -- "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/cockpit"
}

_cockpit_recent_file() {
  print -r -- "$(_cockpit_state_dir)/recent.tsv"
}

_cockpit_notes_dir() {
  print -r -- "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/cockpit/notes"
}

_cockpit_safe_name() {
  local value

  value="$1"
  value="${value//\//__}"
  value="${value//:/_}"
  value="${value// /_}"
  print -r -- "$value"
}

_cockpit_note_file() {
  local row kind name state context project_path description notes_dir

  row="$1"
  IFS=$'\t' read -r kind name state context project_path description <<< "$row"
  notes_dir="$(_cockpit_notes_dir)"

  print -r -- "$notes_dir/$(_cockpit_safe_name "$kind-$name").md"
}

_cockpit_record_recent() {
  local row kind name state context project_path description recent_file

  row="$1"
  IFS=$'\t' read -r kind name state context project_path description <<< "$row"
  [[ -z "$kind" || -z "$name" || -z "$project_path" ]] && return

  recent_file="$(_cockpit_recent_file)"
  mkdir -p -- "${recent_file:h}" || return
  print -r -- "${EPOCHSECONDS:-$(date +%s)}"$'\t'"$kind"$'\t'"$name"$'\t'"$state"$'\t'"$context"$'\t'"$project_path"$'\t'"$description" >> "$recent_file"
}

_cockpit_recent_candidates() {
  local recent_file

  recent_file="$(_cockpit_recent_file)"
  [[ -f "$recent_file" ]] || return 0

  awk -F '\t' '
    { lines[NR] = $0 }
    END {
      for (i = NR; i >= 1; i--) print lines[i]
    }
  ' "$recent_file" \
    | awk -F '\t' '
        NF >= 6 {
          key = $2 "\t" $3 "\t" $6
          if (!seen[key]++) {
            print $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7
          }
        }
      '
}

_cockpit_recent_display_rows() {
  local kind name state context project_path description

  while IFS=$'\t' read -r kind name state context project_path description; do
    [[ -z "$project_path" ]] && continue
    _cockpit_display_row "$kind" "$name" "$state" "$context" "$project_path" "$description"
  done < <(_cockpit_recent_candidates)
}

_cockpit_recent_matches() {
  local query row kind name row_l
  local -a exact partial

  query="${(L)1}"

  while IFS=$'\t' read -r row; do
    kind="${row%%$'\t'*}"
    name="${row#*$'\t'}"
    name="${name%%$'\t'*}"
    row_l="${(L)row}"

    if [[ "${(L)name}" == "$query" ]]; then
      exact+=("$row")
    elif [[ "$row_l" == *"$query"* ]]; then
      partial+=("$row")
    fi
  done < <(_cockpit_recent_candidates)

  if (( ${#exact[@]} )); then
    printf '%s\n' "${exact[@]}"
  else
    printf '%s\n' "${partial[@]}"
  fi
}

_cockpit_select_recent() {
  local query rows output key row action preview

  query="${1:-}"

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'fzf is not installed or not on PATH'
    return 1
  fi

  rows="$(_cockpit_recent_display_rows)"
  if [[ -z "$rows" ]]; then
    print -u2 'no recent cockpit projects yet'
    return 1
  fi

  preview="$(_cockpit_preview_command)"
  output="$(
    print -r -- "$rows" \
      | fzf \
          --ansi \
          --prompt='recent project> ' \
          --height=80% \
          --layout=reverse \
          --border \
          --expect=ctrl-e,ctrl-n,ctrl-t,ctrl-o,ctrl-s,ctrl-r,ctrl-d,ctrl-g,ctrl-y,ctrl-f \
          --delimiter=$'\t' \
          --with-nth=1 \
          --nth=1,3,5,6,7 \
          --header=$'TYPE  PROJECT                       STATE     BRANCH / REMOTE             GROUP             TAGS\nenter code | ^e cd | ^n nvim | ^t term | ^o files | ^f yazi | ^r script | ^d dev | ^g github | ^y notes | ^s status' \
          --preview="$preview" \
          --preview-window='right,60%,border-left' \
          --query="$query"
  )" || return

  key="${output%%$'\n'*}"
  row="${output#*$'\n'}"

  [[ -z "$row" || "$row" == "$output" ]] && return 0

  row="${row#*$'\t'}"
  action="$(_cockpit_action_for_key "$key")"
  print -r -- "$action"$'\t'"$row"
}
