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
STATE=$5
SPRINT=$6

if [ -z "$STATUS_TYPES" ]; then
  SELECT_BY_STATUS=
else
  SELECT_BY_STATUS="| select(.Status.name==($STATUS_TYPES))"
  SELECT_BY_STATUS_LEGACY="| select(.status==($STATUS_TYPES))"
fi

if [ -z "$STATE" ]; then
  SELECT_BY_STATE=
else
  SELECT_BY_STATE="| select(.state==\"$STATE\")"
fi

if [ -z "$SPRINT" ]; then
  SELECT_BY_SPRINT=
else
  SELECT_BY_SPRINT="| select(.Sprint.title==\"$SPRINT\")"
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
                      state
                    }
                  }
                }
              }
            }
          }
        }
      }
    }"

  exec gh api graphql -f query="${QUERY}" --paginate -F org="$OWNER" -F projectNum="$PROJECT_NUM" -q "[.data.user.project.columns.nodes[] as \$columns | \$columns.cards.nodes[] | select(.content != null) | {id: .content.id, title: .content.title, state: .content.state, status: \$columns.name} $SELECT_BY_STATUS_LEGACY $SELECT_BY_STATE]"
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
               id
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
                   state
                 }
               }
             }
           }
         }
       }
     }"

  parser="[
    .data.user.projectNext as \$project

    # map fields
    | \$project.fields.nodes
    | map({id, name, settings: (.settings
    | fromjson)})
    | reduce .[] as \$field ({}; .[\$field.id] = {
        name: \$field.name,
        settings: (
          if \$field.settings == null then
            null
          elif \$field.settings.configuration != null then
            (
              [\$field.settings.configuration.completed_iterations[], \$field.settings.configuration.iterations[]]
              | reduce .[] as \$iteration ({}; .[\$iteration.id] = {
                  duration: \$iteration.duration,
                  title: \$iteration.title,
                  start_date: \$iteration.start_date
                })
            )
          elif \$field.settings.options != null then
            (
              \$field.settings.options
              | reduce .[] as \$option ({}; .[\$option.id] = {
                  name: \$option.name
                })
            )
          else
            \$field.settings
          end
        )
      })
    | . as \$fieldMap

    # map items
    | \$project.items.nodes
    | map({id, fields: .fieldValues.nodes, content})
    | map({id, fields: (.fields | reduce .[] as \$field ({}; .[\$fieldMap[\$field.projectField.id].name] =
      (
        if \$fieldMap[\$field.projectField.id].settings == null then
          \$field.value
        elif (\$fieldMap[\$field.projectField.id].settings[\$field.value] != null) then
          \$fieldMap[\$field.projectField.id].settings[\$field.value]
        else
          null
        end
      )
    )), content})
    | map({item: {id: .id}}+.content+.fields)
    | .[]
    $SELECT_BY_STATUS $SELECT_BY_STATE $SELECT_BY_SPRINT
    ]"

  exec gh api graphql -f query="${QUERY}" --paginate -F org="$OWNER" -F projectNum="$PROJECT_NUM" -q "$parser"
fi
