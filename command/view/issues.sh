#!/usr/bin/env bash
set -e

help() {
  cat <<EOF
Manage GitHub Projects(beta) seamlessly from the command line.

USAGE
  gh project-manager view issues <command> <subcommand> [flags]

COMMANDS
  org:              View issues for organizational project
  repo:             View issues for specific repository project
  user:             View issues for specific user project

FLAGS
  --help, -h        Show help for command
  --legacy          Set project as legacy
  --project-num     Set project number
  --project-type    Set project number

EXAMPLES
  $ gh project-manager view issues
  $ gh project-manager view issues --project-type org --project-num 1
  $ gh project-manager view issues --project-type repo --project-num 25
  $ gh project-manager view issues --project-type user --project-num 98 --legacy

LEARN MORE
  Use 'gh project-manager view issues <command> --help' for more information about a command.
  Read the documentation at https://github.com/jnmiller-va/gh-project-manager
EOF
}

BASEDIR=$(dirname "$0")
LEGACY=false
PROJECT_TYPE=
PROJECT_NUM=

showProjectTypeMenu() {
  PS3="#: "
  options=("User" "Organization" "Repository" "Quit")

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
      "Repository")
        PROJECT_TYPE=repo
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
  --legacy)
    LEGACY=true
    ;;
  --project-type)
    if [ "$2" == org ]; then
      PROJECT_TYPE=organization
      shift
    elif [ "$2" == user ]; then
      PROJECT_TYPE=user
      shift
    elif [ "$2" == repo ]; then
      PROJECT_TYPE=repository
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

exec "$BASEDIR"/issues/"$PROJECT_TYPE".sh "$PROJECT_NUM" "$LEGACY"
