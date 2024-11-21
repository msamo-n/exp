#!/bin/bash

WORKFLOW_RUN_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID" 


function create-commit-status()
{
    local payload='{"state":"'$1'","target_url":"'$WORKFLOW_RUN_URL'","context":"'$STATUS_NAME'"}'
    echo "Creating commit status: $payload" >&2
    curl -L -s -S --fail-with-body \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/statuses/${COMMIT_SHA:-$GITHUB_SHA}" \
        -d "$payload" \
        || {
            echo "Failed to create commit status" >&2
            return 1
        }
    echo "Commit status created" >&2
}


function run-with-sommit-status()
{
    create-commit-status "pending"

    bash -c "$@"
    local exitcode="$?"

    local state
    [[ $exitcode == 0 ]] && state="success" || state="failure"
    create-commit-status "$state"

    return $exitcode
}


STATUS_NAME="$1"
shift

run-with-sommit-status "$@"
