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

function check-run-create()
{
    local name="$1"
    local status="$2"
    local conclusion="$3"

    local payload='{"name":"'$name'","head_sha":"'$CHECK_RUN_SHA'","status":"'$status'"'
    if [[ "$conclusion" != "" ]]; then
        payload=$payload',"conclusion":"'$conclusion'"'
    fi
    payload="$payload}"

    echo "Creating check run: $payload" >&2

    echo curl -L \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        $GITHUB_API_URL/repos/$GITHUB_REPOSITORY/check-runs \
        -d "$payload"
}



function run-as-check()
{
    local name="$1"
    shift

    check-run-create "$name" "in_progress"

    bash -c "$@"
    local exitcode="$?"

    local conclusion
    [[ $exitcode == 0 ]] && conclusion="success" || conclusion="failure"
    check-run-create "$name" "completed" "$conclusion"

    return $exitcode
}



function report-job-status()
{
    local context="$1"
    local state="$2"

    [[ "$JOB_URL" != "" ]] || get-job-url

    local payload='{"state":"'$state'","target_url":"'$JOB_URL'","context":"'$context'"}'
    echo "SHA: $STATUS_SHA. Payload: $payload" >&2

    curl -L \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/$GITHUB_REPOSITORY/statuses/$STATUS_SHA \
        -d "$payload"
}


run-as-check "$@"
