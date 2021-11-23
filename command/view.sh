#!/usr/bin/env bash
set -e

help() {
  cat <<EOF
Manage GitHub Projects(beta) seamlessly from the command line.

USAGE
  gh project-manager view <command> <subcommand> [flags]

COMMANDS
  issues:           View issues for project

FLAGS
  --help, -h        Show help for command
  --legacy          Set project as legacy

EXAMPLES
  $ gh project-manager view issues org 1
  $ gh project-manager view issues repo 25 --legacy
  $ gh project-manager view issues user 98 --legacy

LEARN MORE
  Use 'gh project-manager view <command> --help' for more information about a command.
  Read the documentation at https://github.com/jnmiller-va/gh-project-manager
EOF
}

BASEDIR=$(dirname "$0")

if [ "$1" == issues ]; then
  command=$1
  shift
  exec "$BASEDIR"/view/"$command".sh "$@"
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
