#! /bin/sh
# Every BACKUP_INTERVAL_SECONDS: if the notes repo has changes, commit them,
# rebase onto the remote and push. Gollum commits its own edits, so a commit
# may already exist with nothing left to add; the push still happens.
set -u

INTERVAL="${BACKUP_INTERVAL_SECONDS:-300}"
REPO=/notes

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

git config --global --add safe.directory "$REPO"

backup_once() {
    cd "$REPO" || return 1
    # Gollum or a previous run may hold the index lock; try again next time.
    if [ -e .git/index.lock ]; then
        log "index locked, skipping this round"
        return 0
    fi
    git add -A || return 1
    if ! git diff --cached --quiet; then
        git commit -q -m "chore: memory backup $(date -u +%Y-%m-%dT%H:%M:%SZ)" || return 1
        log "committed changes"
    fi
    branch=$(git rev-parse --abbrev-ref HEAD) || return 1
    git fetch -q origin "$branch" || return 1
    if [ "$(git rev-list --count "origin/$branch..HEAD")" -gt 0 ] || [ "$(git rev-list --count "HEAD..origin/$branch")" -gt 0 ]; then
        git rebase -q "origin/$branch" || { git rebase --abort; log "rebase failed, will retry"; return 1; }
        git push -q origin "HEAD:$branch" || return 1
        log "pushed"
    fi
}

while :; do
    backup_once || log "backup round failed"
    sleep "$INTERVAL"
done
