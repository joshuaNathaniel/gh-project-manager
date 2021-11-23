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

EXAMPLES
  $ gh project-manager view issues org 1
  $ gh project-manager view issues repo 25
  $ gh project-manager view issues user 98 --legacy

LEARN MORE
  Use 'gh project-manager view issues <command> --help' for more information about a command.
  Read the documentation at https://github.com/jnmiller-va/gh-project-manager
EOF
}

BASEDIR=$(dirname "$0")

if [ "$1" == org ] || [ "$1" == repo ] || [ "$1" == user ]; then
  command=$1
  shift
  exec "$BASEDIR"/issues/"$command".sh "$@"
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