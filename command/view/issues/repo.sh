#!/usr/bin/env bash
set -e

help() {
  cat <<EOF
Manage GitHub Projects(beta) seamlessly from the command line.

USAGE
  gh project-manager view issues repo <[project-number]> [flags]

FLAGS
  --help, -h        Show help for command

EXAMPLES
  $ gh project-manager view issues repo 101
  $ gh project-manager view issues repo 102 --legacy

LEARN MORE
  Use 'gh project-manager view issues repo --help' for more information about a command.
  Read the documentation at https://github.com/jnmiller-va/gh-project-manager
EOF
}

BASEDIR=$(dirname "$0")
REPO=$(gh repo view --json name --jq .name)
OWNER=$(gh repo view --json name,owner --jq .owner.login)
PROJECT=

if [ "${1:0:2}" == "--" ]; then
  help
  exit 0
else
  PROJECT=$1
  shift
fi

while [ $# -gt 0 ]; do
  case "$1" in
  -h|--help)
    help
    exit 0
    ;;
  *)
    help >&2
    exit 1
    ;;
  esac
  shift
done

QUERY="
  query(\$repo: String!, \$org: String!, \$project: Int!, \$endCursor: String) {
    repository(name: \$repo, owner: \$org) {
      project(number: \$project) {
        name
        columns(first:100) {
          nodes {
            name
            cards(first:100, after: \$endCursor) {
              pageInfo {
                hasNextPage
                endCursor
              }
              nodes {
                content {
                  ... on Issue {
                    id
                    title
                  }
                }
              }
            }
          }
        }
      }
    }
  }"

exec gh api graphql -f query="${QUERY}" --paginate -F repo="$REPO" -F org="$OWNER" -F project="$PROJECT" -q "[.data.repository.project.columns.nodes[] as \$columns | \$columns.cards.nodes[] | select(.content != null) | {id: .content.id, title: .content.title, status: \$columns.name}]"
