#!/usr/bin/env bash
set -e

help() {
  cat <<EOF
Manage GitHub Projects(beta) seamlessly from the command line.

USAGE
  gh project-manager add issues org <project-number> <path-to-data> [flags]

FLAGS
  --help, -h        Show help for command

EXAMPLES
  $ gh project-manager add issues org 98 ./data.json

LEARN MORE
  Use 'gh project-manager add issues org --help' for more information about a command.
  Read the documentation at https://github.com/jnmiller-va/gh-project-manager
EOF
}

BASEDIR=$(dirname "$0")
OWNER=$(gh repo view --json owner --jq .owner.login)
PROJECT=
ISSUES=

if [ "${1:0:2}" == "--" ]; then
  help
  exit 0
else
  PROJECT=$1
  shift
fi

if [ "${1:0:2}" == "--" ]; then
  help
  exit 0
else
  # shellcheck disable=SC2002
  ISSUES=$(jq -c -r ".[]" "${1}")
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

OPTIONS_QUERY="
  query(\$org: String!, \$project: Int!) {
    organization(login: \$org) {
      projectNext(number: \$project) {
        id
        fields(first:100) {
          nodes {
            name,
            id,
            settings
          }
        }
      }
    }
  }
  "

QUERIED_PROJECT=$(exec gh api graphql -f query="${OPTIONS_QUERY}" -F org="$OWNER" -F project="$PROJECT")

PROJECT_ID=$(echo "$QUERIED_PROJECT" | jq ".data.organization.projectNext.id")
FIELD_ID=$(echo "$QUERIED_PROJECT" | jq ".data.organization.projectNext.fields.nodes[] | select(.name == \"Status\") | .id")
OPTIONS=$(echo "$QUERIED_PROJECT" | jq ".data.organization.projectNext.fields.nodes[] | select(.name == \"Status\") | .settings | fromjson | .options")

ADD_ISSUE_MUTATION="
  mutation(\$projectId: ID!, \$contentId: ID!) {
    addProjectNextItem(input: {
      projectId: \$projectId
      contentId: \$contentId
    }) {
      projectNextItem {
        id
      }
    }
  }
  "

UPDATE_ISSUE_MUTATION="
  mutation(\$projectId: ID!, \$itemId: ID!, \$fieldId: ID!, \$fieldVal: String!) {
    updateProjectNextItemField(input: {
      projectId: \$projectId
      itemId: \$itemId
      fieldId: \$fieldId
      value: \$fieldVal
    }) {
      projectNextItem {
        id
      }
    }
  }
  "

IFS=$'\n'
# shellcheck disable=SC2068
echo -ne "Adding Issues"
for issue in $ISSUES; do
  echo -ne "."
  CONTENT_ID=$(echo "$issue" | jq -r ".id")
  STATUS=$(echo "$issue" | jq -r ".status")
  FIELD_VAL=$(echo "$OPTIONS" | jq ".[] | select(.name == \"${STATUS}\") | .id" | sed -e 's/^"//' -e 's/"$//')
  ITEM_ID=$(gh api graphql -f query="${ADD_ISSUE_MUTATION}" -F projectId="$PROJECT_ID" -F contentId="$CONTENT_ID" -q ".data.addProjectNextItem.projectNextItem.id")
  gh api graphql -f query="${UPDATE_ISSUE_MUTATION}" -F projectId="$PROJECT_ID" -F itemId="\"$ITEM_ID\"" -F fieldId="$FIELD_ID" -F fieldVal="$FIELD_VAL" --silent
done
echo " Success!"
