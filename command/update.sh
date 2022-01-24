#!/usr/bin/env bash
set -e

help() {
  cat <<EOF
Manage GitHub Projects(beta) seamlessly from the command line.

USAGE
  gh project-manager view <command> <subcommand> [flags]

COMMANDS
  issues:           Update issues for project

FLAGS
  --help, -h        Show help for command

EXAMPLES
  $ gh project-manager update issues --project-type org --project-num 1 --field Status --value Done --path ./data.json
  $ gh project-manager update issues --project-type org --project-num 1 --field Sprint --value current --path ./data.json

LEARN MORE
  Use 'gh project-manager view <command> --help' for more information about a command.
  Read the documentation at https://github.com/jnmiller-va/gh-project-manager
EOF
}

BASEDIR=$(dirname "$0")

if [ "$1" == issues ]; then
  command=$1
  shift
  exec "$BASEDIR"/update/"$command".sh "$@"
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
