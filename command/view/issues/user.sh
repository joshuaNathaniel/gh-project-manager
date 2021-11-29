#!/usr/bin/env bash
set -e

if [ -z "$4" ]; then
  OWNER=$(gh repo view --json owner --jq .owner.login)
else
  OWNER=$4
fi

PROJECT_NUM=$1
LEGACY=$2
STATUS_TYPES=$3

if [ -z "$STATUS_TYPES" ]; then
  SELECT_BY_STATUS=
else
  SELECT_BY_STATUS="| select(.status==($STATUS_TYPES))"
fi

if [ "$LEGACY" == true ]; then
  QUERY="
    query(\$org: String!, \$projectNum: Int!, \$endCursor: String) {
      user(login: \$org) {
        project(number: \$projectNum) {
          name
          body
          state
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

  exec gh api graphql -f query="${QUERY}" --paginate -F org="$OWNER" -F projectNum="$PROJECT_NUM" -q "[.data.user.project.columns.nodes[] as \$columns | \$columns.cards.nodes[] | select(.content != null) | {id: .content.id, title: .content.title, status: \$columns.name} $SELECT_BY_STATUS]"
else
   QUERY="
     query(\$org: String!, \$projectNum: Int!, \$endCursor: String) {
       user(login: \$org) {
         projectNext(number: \$projectNum) {
           title
           fields(first:100) {
             nodes {
               id
               name
               settings
             }
           }
           items(first:100, after:\$endCursor ) {
             nodes {
               fieldValues(first: 100) {
                 nodes {
                   value
                   projectField {
                     id
                   }
                 }
               }
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
     }"

  exec gh api graphql -f query="${QUERY}" --paginate -F org="$OWNER" -F projectNum="$PROJECT_NUM" -q "[.data.user.projectNext as \$project | \$project.fields.nodes[] | select(.name == \"Status\") | . as \$field | .settings | fromjson | . as \$settings | {id: \$field.id, name: \$field.name, settings: \$settings} as \$status | \$project.items.nodes as \$cards | \$cards | map({id: .content.id, title: .content.title, status: (.fieldValues.nodes[] | select(.projectField.id == \$status.id) as \$setting | \$settings.options[] | select(.id == \$setting.value)| .name) }) | .[] $SELECT_BY_STATUS]"
fi
