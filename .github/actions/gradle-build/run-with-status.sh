#!/bin/bash

WORKFLOW_RUN_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID" 

function create-commit-status()
{
    local payload='{"state":"'$1'","target_url":"'$WORKFLOW_RUN_URL'","context":"'$STATUS_NAME'"}'
    echo "Creating commit status: $payload" >&2
    
    local output
    output="$(
        curl -L -s -S --fail-with-body \
            -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/statuses/${COMMIT_SHA:-$GITHUB_SHA}" \
            -d "$payload"
    )" || {
        echo "Failed to create commit status: $output" >&2
        return 1
    }
    echo "Commit status created" >&2
}

STATUS_NAME="$1"
shift

create-commit-status "pending"

bash -c "$@"
EXITCODE="$?"

[[ $EXITCODE == 0 ]] && STATE="success" || STATE="failure"
create-commit-status "$STATE"

exit $EXITCODE

