#!/usr/bin/env bash

set -e;
set -o pipefail;
EXIT_SUCCESS="0";
EXIT_FAILURE="1";

BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
QUERY="${1}";

RL_WAIT_BUFFER="5";

TS=`date "+%Y%m%d%H%M%S"`;
CURL_HEADERS="/tmp/curl-response-headers-search_query-${TS}";
CURL_OUTPUT="/tmp/curl-output-search_query-${TS}";
function cleanup() {
    rm "${CURL_HEADERS}" "${CURL_OUTPUT}" 2>/dev/null || true;
}
trap cleanup EXIT;

if ! [ -n "${GITHUB_API_USER}" ]
then
    echo "GITHUB_API_USER is unset; please set GITHUB_API_USER to the GitHub username to use to access the API" >&2;
    exit "${EXIT_FAILURE}";
fi;
if ! [ -n "${GITHUB_API_KEY}" ]
then
    echo "GITHUB_API_KEY is unset; please set GITHUB_API_KEY to a valid Personal Access Token (https://github.com/settings/tokens) for the specified user (GITHUB_API_USER=${GITHUB_API_USER})" >&2;
    exit "${EXIT_FAILURE}";
fi;
if ! [ -n "${QUERY}" ]
then
    echo "No search query specified. Please specify search query as argument to this script" >&2;
    exit "${EXIT_FAILURE}";
fi;

echo "(getting repository list...)";

for REPO_NAME in `${BASE}/list_repos.sh | sort`
do
    echo "====================";
    echo "${REPO_NAME}";
    echo "----------";
    GITHUBURL="https://api.github.com/search/code?q=${QUERY}+repo:${REPO_NAME}";
    cleanup;
    REPO_COUNT="0";
    while [ -n "${GITHUBURL}" ]
    do
        curl --dump-header "${CURL_HEADERS}" --output "${CURL_OUTPUT}" --silent --basic --user "${GITHUB_API_USER}:${GITHUB_API_KEY}" "${GITHUBURL}";
        PAGE_COUNT=`jq --raw-output '.total_count' "${CURL_OUTPUT}"`;
        if [ "${PAGE_COUNT}" -gt "0" 2> /dev/null ]
        then
            REPO_COUNT="$((REPO_COUNT + PAGE_COUNT))";
        fi;
        jq --raw-output '.items[]? | "[PATH] \(.path) | [URL] \(.html_url)"' "${CURL_OUTPUT}";
        RL_REMAINING=`cat "${CURL_HEADERS}" | sed -E -n 's#^X-RateLimit-Remaining[^0-9]*([0-9]+).*#\1#p'`;
        if ! [ "${RL_REMAINING}" -gt "0" ]
        then
            TS_NOW=`date "+%s"`;
            RL_RESET=`cat "${CURL_HEADERS}" | sed -E -n 's#^X-RateLimit-Reset[^0-9]*([0-9]+).*#\1#p'`;
            RL_WAIT="$((RL_RESET - TS_NOW + RL_WAIT_BUFFER))";
            while [ "${RL_WAIT}" -gt "0" ]
            do
                echo "Rate limit throttling; ${RL_WAIT}s remaining..." >&2;
                sleep 1;
                RL_WAIT="$((RL_WAIT - 1))";
            done;
        fi;
        GITHUBURL=`cat "${CURL_HEADERS}" | sed -E -n  's#^Link:.*[<]([^>]+)[>]; rel=["]next["].*#\1#p'`;
    done;
    if [ "${REPO_COUNT}" -gt "0" ]
    then
        echo "----------";
        echo "*** total matches = ${REPO_COUNT} ***";
    fi;
    echo "====================";
    echo;
done;
