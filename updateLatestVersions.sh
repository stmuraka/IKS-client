#!/usr/bin/env bash

set -e

# Flag for updates; 0=none
UPDATED=0

echo "Checking for client version updates..."
echo ""

# Get code versions
echo "Dockerfile versions:"
code_kubectl_version=$(grep '^ARG KUBECTL_VERSION' Dockerfile | cut -d '=' -f2)
echo "- kubectl: ${code_kubectl_version}"
code_calicoctl_version=$(grep '^ARG CALICOCTL_VERSION' Dockerfile | cut -d '=' -f2)
echo "- calicoctl: ${code_calicoctl_version}"
code_helm3_version=$(grep '^ARG HELM3_VERSION' Dockerfile | cut -d '=' -f2)
echo "- helm 3: ${code_helm3_version}"
code_oc_version=$(grep '^ARG OC_VERSION' Dockerfile | cut -d '=' -f2)
echo "- oc: ${code_oc_version}"

echo ""

# Get latest versions
echo "Getting latest versions..."
latest_kubectl_version=$(curl -sSL https://storage.googleapis.com/kubernetes-release/release/stable.txt | tr -d 'v')
echo "- Latest kubectl version: ${latest_kubectl_version}"
latest_calicoctl_version=$(curl -sSL https://github.com/projectcalico/calicoctl/releases/latest | grep '<a href=.*/tree/' | awk '{print $2}' | cut -d '=' -f2 | tr -d '"' | xargs basename | tr -d 'v')
echo "- Latest calicoctl version: ${latest_calicoctl_version}"
latest_helm3_version=$(curl -sSL https://api.github.com/repos/helm/helm/releases | jq -r '.[].tag_name' | grep '^v3' | grep -v '-' | tr -d 'v' | sort -V | tail -n 1)
echo "- Latest helm 3 version: ${latest_helm3_version}"
latest_oc_version=$(curl -sSL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/ | grep '<a href=\".*\/\">' | cut -d '"' -f2 | tr -d '/' | grep -v 'candidate' | grep -v 'latest' | grep -v 'fast' | grep -v 'stable' | grep -v 'unreleased' | grep -v 'ec' | grep -v 'rc' | grep -v '4.12' | sort -V | tail -n 1)
echo "- Latest oc version: ${latest_oc_version}"

echo ""

# Compare kubectl versions
if [[ "${latest_kubectl_version}" != "${code_kubectl_version}"  ]]; then
    echo "Updating kubectl ${code_kubectl_version} -> ${latest_kubectl_version}"
    update_str="${update_str}Bumping kubectl version to ${latest_kubectl_version}; "
    sed -ie "s/^ARG KUBECTL_VERSION=${code_kubectl_version}/ARG KUBECTL_VERSION=${latest_kubectl_version}/" Dockerfile
    ((UPDATED+=1))
fi
# Compare calicoctl versions
if [[ "${latest_calicoctl_version}" != "${code_calicoctl_version}"  ]]; then
    echo "Updating calicoctl ${code_calicoctl_version} -> ${latest_calicoctl_version}"
    update_str="${update_str}Bumping calicoctl version to ${latest_calicoctl_version}; "
    sed -ie "s/^ARG CALICOCTL_VERSION=${code_calicoctl_version}/ARG CALICOCTL_VERSION=${latest_calicoctl_version}/" Dockerfile
    ((UPDATED+=1))
fi
# Compare helm 3 versions
if [[ "${latest_helm3_version}" != "${code_helm3_version}"  ]]; then
    echo "Updating Helm 3 ${code_helm3_version} -> ${latest_helm3_version}"
    update_str="${update_str}Bumping Helm 3 version to ${latest_helm3_version}; "
    sed -ie "s/^ARG HELM3_VERSION=${code_helm3_version}/ARG HELM3_VERSION=${latest_helm3_version}/" Dockerfile
    ((UPDATED+=1))
fi
# Compare oc versions
if [[ "${latest_oc_version}" != "${code_oc_version}"  ]]; then
    echo "Updating oc ${code_oc_version} -> ${latest_oc_version}"
    update_str="${update_str}Bumping OC version to ${latest_oc_version}; "
    sed -ie "s/^ARG OC_VERSION=${code_oc_version}/ARG OC_VERSION=${latest_oc_version}/" Dockerfile
    ((UPDATED+=1))
fi

# If updated, print message
if [[ ${UPDATED} -gt 0 ]]; then
    echo ""
    echo "Dockerfile updated"
    echo "Please review and commit changes to Git"
else
    echo "No updates"
fi
