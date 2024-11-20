#!/bin/bash

function get-job-url() {
    # local jobs_json="$(
    #     curl -L \
    #         -H "Accept: application/vnd.github+json" \
    #         -H "Authorization: Bearer $GITHUB_TOKEN" \
    #         -H "X-GitHub-Api-Version: 2022-11-28" \
    #         https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID/jobs
    # )"

    # NOTE: it's actually a workflow URL, not a job URL
    JOB_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
    echo "JOB_URL=$JOB_URL" | tee -a $GITHUB_ENV
}


function report-job-status()
{
    local context="$1"
    local state="$2"

    [[ "$JOB_URL" != "" ]] || get-job-url

    local payload='{"state":"'$state'","target_url":"'$JOB_URL'","context":"'$context'"}'
    echo "SHA: $GITHUB_SHA. Payload: $payload" >&2

    curl -L \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/$GITHUB_REPOSITORY/statuses/$GITHUB_SHA \
        -d "$payload"
}

"$1" "$2" "$3" "$4"
