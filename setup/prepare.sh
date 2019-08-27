#!/bin/bash
set -eou pipefail

default_dev="n"
default_dir_path="$HOME/dev"
default_pod_dir_name="lrd-pod"
default_git_repo_ctl="https://github.com/lucasbasquerotto/ansible-manager"

CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
    
start="$(date '+%F %X')"

read -e -p "Is this a development environment? [Y/n] " yn
dev=""

if [[ $yn == "y" || $yn == "Y" ]]; then
  dev=true
  echo "development"
else
  echo "non-development"
fi

read -e -p "Enter the directory path: " -i "$default_dir_path" dir_path
mkdir -p "$dir_path"
cd "$dir_path/"

msg="Enter the specific pod local name to create files from the templates"
msg="$msg (leave empty to create the files for all environment repos): "
read -e -p "$msg" -i "" pod_local_name
    
if [ "$dev" = true ]; then
  read -e -p "Enter the pod directory name to run at the end of the setup: " \
    -i "$default_pod_dir_name" pod_dir_name
fi

read -e -p "Enter the controller git repository: " \-i "$default_git_repo_ctl" git_repo_ctl
git clone "$git_repo_ctl" ctl

if [ "$dev" = true ]; then
  echo -e "${CYAN}$(date '+%F %X') setup (dev) started${NC}"
  ./ctl/run setup-dev
  echo -e "${CYAN}$(date '+%F %X') setup (dev) ended${NC}"

  echo -e "${CYAN}$(date '+%F %X') pod migration started${NC}"
  ./pod/"$pod_dir_name"/run migrate
  echo -e "${CYAN}$(date '+%F %X') pod migration ended${NC}"
else
  echo -e "${CYAN}$(date '+%F %X') setup started${NC}"
  ./ctl/run setup
  echo -e "${CYAN}$(date '+%F %X') setup ended${NC}"

  echo -e "${CYAN}$(date '+%F %X') updating the environment repositories files${NC}"
  ./ctl/run main-cmd /root/ctl/run run -e env_name="$pod_local_name"
  echo -e "${CYAN}$(date '+%F %X') environment repositories files updated${NC}"

  if [ ! -z "$pod_local_name" ]; then
    echo -e "${CYAN}$(date '+%F %X') run the upgrade script ($pod_local_name)${NC}"
    ./ctl/run main-cmd "/root/r/w/$pod_local_name/upgrade"
    echo -e "${CYAN}$(date '+%F %X') upgrade script ($pod_local_name) executed${NC}"
  fi
fi

end="$(date '+%F %X')"
echo -e "${CYAN}ended - $start - $end${NC}"