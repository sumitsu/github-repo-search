# github-repo-search
Convenience scripts for querying GitHub via the GitHub REST API (https://developer.github.com/v3)

## Required Packages (`brew`/`yum`/`apt`/etc.)
- curl
- jq

## GitHub Authentication: Personal Access Token
The GitHub REST API requires a personal access token:
1. Create a token here: [https://github.com/settings/tokens].
2. Set the `GITHUB_API_KEY` environment property to the token value when executing the scripts.

## Scripts
### `list_repos.sh`: List repositories within an organization
```bash
GITHUB_ORG="<GitHub user or org you want to search>" GITHUB_API_USER="<your GitHub username>" GITHUB_API_KEY="<personal access token>" ./list_repos.sh
```

### `query_all_repos.sh`: Perform a search query on all repositories within an organization
```bash
GITHUB_ORG="<GitHub user/org you want to search>" GITHUB_API_USER="<your GitHub username>" GITHUB_API_KEY="<personal access token>" ./query_all_repos.sh "<search query string>"
```
