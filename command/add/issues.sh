#!/usr/bin/env bash
set -e

help() {
  cat <<EOF
Manage GitHub Projects(beta) seamlessly from the command line.

USAGE
  gh project-manager add issues <command> <subcommand> [flags]

FLAGS
  --help, -h        Show help for command
  --path            Set json file path
  --project-num     Set project number
  --project-type    Set project number

EXAMPLES
  $ gh project-manager add issues --project-type org --project-num 1 --path ./data.json
  $ gh project-manager add issues --project-type user --project-num 98 --path /etc/data.json

LEARN MORE
  Use 'gh project-manager add issues <command> --help' for more information about a command.
  Read the documentation at https://github.com/rise8-us/gh-project-manager
EOF
}

PROJECT_TYPE=
PROJECT_NUM=
ISSUES=

showPathPrompt() {
  echo "Please enter path to issues JSON data or enter 'q' to quit: "
  read -r

  if [ "$REPLY" == q ]; then
    exit 0
  fi

  ISSUES=$(jq -c -r ".[]" "${REPLY}")
}

showProjectTypeMenu() {
  PS3="#: "
  options=("User" "Organization" "Quit")

  echo "Select Project Type"
  select opt in "${options[@]}"
  do
    case $opt in
      "User")
        PROJECT_TYPE=user
        break
        ;;
      "Organization")
        PROJECT_TYPE=organization
        break
        ;;
      "Quit")
        exit 0
        ;;
      *)
        echo "invalid option $REPLY"
        exit 0
        ;;
    esac
  done
}

showProjectNumberPrompt() {
  echo "Please enter project number or enter 'q' to quit:"
  read -r

  if [ "$REPLY" == q ]; then
    exit 0
  fi

  PROJECT_NUM=${REPLY}
}

while [ $# -gt 0 ]; do
  case "$1" in
  --path)
    ISSUES=$(jq -c -r ".[]" "${2}")
    shift
    ;;
  --project-type)
    if [ "$2" == org ]; then
      PROJECT_TYPE=organization
      shift
    elif [ "$2" == user ]; then
      PROJECT_TYPE=user
      shift
    else
      help
      exit 0
    fi
    ;;
  --project-num)
    PROJECT_NUM=$2
    shift
    ;;
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

if [ -z $PROJECT_TYPE ]; then
  showProjectTypeMenu
fi

if [ -z "$PROJECT_NUM" ]; then
  showProjectNumberPrompt
fi

if [ -z "$ISSUES" ]; then
  showPathPrompt
fi

OWNER=$(gh repo view --json owner --jq .owner.login)

OPTIONS_QUERY="
  query(\$org: String!, \$projectNum: Int!) {
    ${PROJECT_TYPE}(login: \$org) {
      projectNext(number: \$projectNum) {
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

QUERIED_PROJECT=$(exec gh api graphql -f query="${OPTIONS_QUERY}" -F org="$OWNER" -F projectNum="$PROJECT_NUM")

PROJECT_ID=$(echo "$QUERIED_PROJECT" | jq ".data.${PROJECT_TYPE}.projectNext.id")
FIELD_ID=$(echo "$QUERIED_PROJECT" | jq ".data.${PROJECT_TYPE}.projectNext.fields.nodes[] | select(.name == \"Status\") | .id")
OPTIONS=$(echo "$QUERIED_PROJECT" | jq ".data.${PROJECT_TYPE}.projectNext.fields.nodes[] | select(.name == \"Status\") | .settings | fromjson | .options")

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
