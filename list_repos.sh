#!/usr/bin/env bash

set -e;
set -o pipefail;
EXIT_SUCCESS="0";
EXIT_FAILURE="1";

TS=`date "+%Y%m%d%H%M%S"`;
CURL_HEADERS="/tmp/curl-response-headers-list_repos-${TS}";
CURL_OUTPUT="/tmp/curl-output-list_repos-${TS}";
function cleanup() {
    rm "${CURL_HEADERS}" "${CURL_OUTPUT}" 2>/dev/null || true;
}
trap cleanup EXIT;

if ! [ -n "${GITHUB_ORG}" ]
then
    echo "GITHUB_ORG is unset; please set GITHUB_ORG to the name of the organization for which to search for repositories" >&2;
    exit "${EXIT_FAILURE}";
fi;
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

GITHUBURL="https://api.github.com/orgs/${GITHUB_ORG}/repos?type=all";
while [ -n "${GITHUBURL}" ]
do
    curl --dump-header "${CURL_HEADERS}" --output "${CURL_OUTPUT}" --silent --basic --user "${GITHUB_API_USER}:${GITHUB_API_KEY}" "${GITHUBURL}";
    cat "${CURL_OUTPUT}" | jq --raw-output '.[]?.full_name';
    GITHUBURL=`cat "${CURL_HEADERS}" | sed -E -n 's#^Link:.*[<]([^>]+)[>]; rel=["]next["].*#\1#p' | head -1`;
done;
