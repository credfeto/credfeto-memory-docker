#! /bin/sh
# Every BACKUP_INTERVAL_SECONDS: if the notes repo has changes, commit them,
# rebase onto the remote and push. Gollum commits its own edits, so a commit
# may already exist with nothing left to add; the push still happens.
# A failed round (e.g. a DNS blip while a nameserver reboots) is retried once
# after BACKUP_RETRY_SECONDS. Successful rounds that push nothing are silent,
# so the first good round after a failure logs that it recovered: the last
# log line then always reflects the current state.
set -u

INTERVAL="${BACKUP_INTERVAL_SECONDS:-300}"
RETRY="${BACKUP_RETRY_SECONDS:-30}"
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

failed=0
while :; do
    if backup_once; then
        [ "$failed" -eq 1 ] && log "backup round ok, recovered from earlier failure"
        failed=0
    else
        log "backup attempt did not complete, retrying in ${RETRY}s"
        sleep "$RETRY"
        if backup_once; then
            log "backup round ok on retry"
            failed=0
        else
            log "backup round failed"
            failed=1
        fi
    fi
    sleep "$INTERVAL"
done
