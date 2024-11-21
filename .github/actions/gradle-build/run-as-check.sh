#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_RUNS_CTX_FILE="$SCRIPT_DIR/.ctx.json"


function _get_check_run_id()
{
    [[ -f "$CHECK_RUNS_CTX_FILE" ]] \
        && CHECK_RUNS_CTX="$(cat "$CHECK_RUNS_CTX_FILE")" \
        || CHECK_RUNS_CTX="{}"
    CHECK_RUN_ID="$(echo "$CHECK_RUNS_CTX" | jq -r ".\"$CHECK_RUN_NAME\"")"
}

function _set_check_run_id()
{
    [[ -f "$CHECK_RUNS_CTX_FILE" ]] \
        && CHECK_RUNS_CTX="$(cat "$CHECK_RUNS_CTX_FILE")" \
        || CHECK_RUNS_CTX="{}"
    echo "$CHECK_RUNS_CTX" | jq -c ". + {\"$CHECK_RUN_NAME\": \"$1\"}" >"$CHECK_RUNS_CTX_FILE"
}

function check-run-req()
{
    curl -L -s -S --fail-with-body \
        -X "$1" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        $GITHUB_API_URL/repos/$GITHUB_REPOSITORY/check-runs$2 \
        -d "$3"
}

function check-run-payload()
{
    local status="$1"
    local conclusion="$2"

    local payload='{"name":"'$CHECK_RUN_NAME'","head_sha":"'${CHECK_RUN_SHA:-$GITHUB_SHA}'","status":"'$status'"'
    payload=$payload',"details_url":"'$CHECK_RUN_DETAILS_URL'"'
    if [[ "$conclusion" != "" ]]; then
        payload=$payload',"conclusion":"'$conclusion'"'
    fi
    payload="$payload}"

    echo "$payload"
}


function check-run-create()
{
    local payload="$(check-run-payload "$@")"
    echo "Creating check run: $payload" >&2

    local output
    output="$(check-run-req POST "" "$payload")" || {
        echo "Failed to create check run: $output" >&2
        return 1
    }
    echo "Check run created" >&2

    CHECK_RUN_ID="$(echo "$output" | jq -r '.id')"
    _set_check_run_id "$CHECK_RUN_ID"
}


function check-run-update()
{
    local payload="$(check-run-payload "$@")"
    echo "Updating check run: $payload" >&2

    local output
    output="$(check-run-req PATCH "/$CHECK_RUN_ID" "$payload")" || {
        echo "Failed to update check run: $output" >&2
        return 1
    }
    echo "Check run updated" >&2
}


function run-as-check()
{
    if [[ -z "$CHECK_RUN_ID" ]]; then
        echo "Check run ID is not set, creating a new check run" >&2
        check-run-create "in_progress"
    else
        echo "Check run ID is set to $CHECK_RUN_ID" >&2
        check-run-update "in_progress"
    fi

    bash -c "$@"
    local exitcode="$?"

    local conclusion
    [[ $exitcode == 0 ]] && conclusion="success" || conclusion="failure"
    check-run-update "completed" "$conclusion"

    return $exitcode
}


CHECK_RUN_NAME="$1"
CHECK_RUN_DETAILS_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"  # URL of the workflow run
_get_check_run_id
shift


[[ "$1" == "--queued" ]] && { check-run-create "queued" ; exit $? ; }
run-as-check "$@"
