#!/usr/bin/env bash

# Copyright 2019 Red Hat, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -x
set -e

export SELENIUM_VERSION="3.141.59"
REPO_ORG=redhatgov


# Identify our container runtime and differences in arguments between them
if which podman &>/dev/null; then
    runtime=podman
    run_args="-v ./tmp:/app/tmp:shared -v ./vars/$DEVSECOPS_CLUSTER:/app/vars:shared,ro --label=disable"
elif which docker &>/dev/null; then
    runtime=docker
    run_args="-v $PWD/tmp:/app/tmp -v $PWD/vars/$DEVSECOPS_CLUSTER:/app/vars:ro --security-opt label=disabled"
else
    echo "A container runtime is necessary to execute these playbooks." >&2
    echo "Please install podman or docker." >&2
    exit 1
fi

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

for I in selenium-base selenium-hub selenium-node-base selenium-node-chrome selenium-node-chrome-debug selenium-node-firefox selenium-node-firefox-debug
do
  cd ${BASEDIR}
  TARGET_DIR=$(echo $I | sed 's@-debug@@g')
  cd ${TARGET_DIR}
  if [[ "${I}" == *"-debug" ]]; then
    if [[ -f Dockerfile ]]; then
      ## Build Debug Container
      $runtime build --no-cache -t ${REPO_ORG}/${I}:${SELENIUM_VERSION} --build-arg GRID_DEBUG="true" --build-arg SELENIUM_VERSION="${SELENIUM_VERSION}" ./
      $runtime tag ${REPO_ORG}/${I}:${SELENIUM_VERSION} ${REPO_ORG}/${I}:latest
    fi
  else
    if [[ -f Dockerfile ]]; then
      ## Build regular container
      $runtime build --no-cache -t ${REPO_ORG}/${I}:${SELENIUM_VERSION} --build-arg SELENIUM_VERSION="${SELENIUM_VERSION}" ./
      $runtime tag ${REPO_ORG}/${I}:${SELENIUM_VERSION} ${REPO_ORG}/${I}:latest
    fi
  fi
  cd ${BASEDIR}
done