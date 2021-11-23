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
  $ gh project-manager add issues org 1 $(cat data.json)
  $ gh project-manager add issues user 98 $(cat data.json)

LEARN MORE
  Use 'gh project-manager add <command> --help' for more information about a command.
  Read the documentation at https://github.com/jnmiller-va/gh-project-manager
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
