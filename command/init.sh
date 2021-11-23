#!/usr/bin/env bash
set -e
REPO_OWNER=$(gh repo view --json owner --jq .owner.login)
PROJECT_TYPE=

showProjectTypeMenu() {
  PS3="#: "
  options=("User" "Organization" "Quit")

  echo "Select Project Type"
  select opt in "${options[@]}"
  do
    case $opt in
      "User")
        PROJECT_TYPE=users
        break
        ;;
      "Organization")
        PROJECT_TYPE=orgs
        break
        ;;
      "Quit")
        break
        ;;
      *) echo "invalid option $REPLY";;
    esac
  done
}

showProjectTypeMenu

cat <<EOF

The new project (beta) page on github.com will be opened. Currently this is the only recognized way of creating a project.

To save the project you must give it a name.

Press any key to continue...
EOF

read
open https://github.com/$PROJECT_TYPE/"$REPO_OWNER"/projects/new?type=beta