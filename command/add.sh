#!/usr/bin/env bash
set -e

help() {
  cat <<EOF
Manage GitHub Projects(beta) seamlessly from the command line.

USAGE
  gh project-manager add <command> <subcommand> [flags]

COMMANDS
  issues:           Add issues to project

FLAGS
  --help, -h        Show help for command

EXAMPLES
  $ gh project-manager add issues
  $ gh project-manager add issues --project-type org --project-num 1 --path ./data.json
  $ gh project-manager add issues --project-type user --project-num 98 --path /etc/data.json

LEARN MORE
  Use 'gh project-manager add <command> --help' for more information about a command.
  Read the documentation at https://github.com/rise8-us/gh-project-manager
EOF
}

BASEDIR=$(dirname "$0")

if [ "$1" == issues ]; then
  command=$1
  shift
  exec "$BASEDIR"/add/"$command".sh "$@"
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
