PRE=$(dirname $(realpath $0))

# Source optional env files quietly. .env / .env.secret are user-local and
# gitignored — their absence is the normal case, not a condition worth warning
# about on every shell startup.
[ -f "$PRE/.env" ] && source "$PRE/.env"
[ -f "$PRE/.env.secret" ] && source "$PRE/.env.secret"
