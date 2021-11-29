#!/usr/bin/env bash
set -e

REPO=$(gh repo view --json name --jq .name)
OWNER=$(gh repo view --json name,owner --jq .owner.login)
PROJECT_NUM=$1

QUERY="
  query(\$repo: String!, \$org: String!, \$projectNum: Int!, \$endCursor: String) {
    repository(name: \$repo, owner: \$org) {
      project(number: \$projectNum) {
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

exec gh api graphql -f query="${QUERY}" --paginate -F repo="$REPO" -F org="$OWNER" -F projectNum="$PROJECT_NUM" -q "[.data.repository.project.columns.nodes[] as \$columns | \$columns.cards.nodes[] | select(.content != null) | {id: .content.id, title: .content.title, status: \$columns.name}]"
