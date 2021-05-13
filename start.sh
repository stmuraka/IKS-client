#!/bin/bash

set -e

HELM=${HELM:-3}
REGION=${REGION:-us-south}

# Display options
echo "Environment variable options:
    API_KEY (IAM API key)                                 = ${API_KEY}
    API_ENDPOINT (default: cloud.ibm.com)                 = ${API_ENDPOINT}
    ACCOUNT_ID (long id)                                  = ${ACCOUNT_ID}
    CLUSTER (IKS cluster name)                            = ${CLUSTER}
    HELM (Helm version)                                   = ${HELM}
    REGION (target region)                                = ${REGION}
    RESOURCE_GROUP (default: default)                     = ${RESOURCE_GROUP}
    USERNAME (IAM username)                               = ${USERNAME}
    SSO (to enable, set =1)                               = ${SSO}
    TEST (set the API Endpoint to test.cloud.ibm.com)     = ${TEST}
"

# If HELM=2 is specified, change the symlink
if [[ ${HELM} -eq 2 ]]; then
    rm /usr/local/bin/helm
    helm2_path=$(ls /usr/local/bin/helm-v2* 2>/dev/null) || { echo "WARNING: Failed to get helm 2 path"; }
    ln -s ${helm2_path} /usr/local/bin/helm
fi

# Update the cli if available
ibmcloud update -f
# Update the plugins if available
ibmcloud plugin update --all --force
#ic_plugins=()
#mapfile -t ic_plugins < <(ibmcloud plugin list --output json | jq -r '.[].Name')
#for p in ${ic_plugins[*]}; do
#    ibmcloud plugin update ${p} -f
#done

# Initialize the oc plugin
ibmcloud oc init

echo ""

# Build login command
login_cmd="ibmcloud login"

# Set the API endpoint
if [ -z ${API_ENDPOINT} ]; then
    # If the API endpoint is not specified, set the defaults
    API_ENDPOINT="https://cloud.ibm.com"

    # Check if the Test flag is enabled for the test environment
    if [ ! -z ${TEST} ]; then
        TEST=$(echo "${TEST}" | awk '{print tolower($0)}')
        if [[ "${TEST}" == "0" || "${TEST}" == "true" ]]; then
            API_ENDPOINT="https://test.cloud.ibm.com"
        fi
    fi
fi
login_cmd="${login_cmd} -a ${API_ENDPOINT}"

# Set API key if specified
if [ ! -z ${API_KEY} ]; then
    login_cmd="${login_cmd} --apikey ${API_KEY}"
fi

# Set Account ID if specified
if [ ! -z ${ACCOUNT_ID} ]; then
    echo "Account ID: ${ACCOUNT_ID}"
    login_cmd="${login_cmd} -c ${ACCOUNT_ID}"
fi

if [ ! -z ${REGION} ]; then
    # Get the valid regions
    REGIONS=()
    mapfile -t REGIONS < <(ibmcloud regions --output json | jq -r '.[].Name')

    REGION="${REGION,,}"
    # Check if the REGION specified is valid
    [[ " ${REGIONS[@]} " =~ " ${REGION} " ]] && login_cmd="${login_cmd} -r ${REGION}" || { echo "WARNING: Unknown region: ${REGION}"; login_cmd="${login_cmd} --no-region"; }
fi

# Set resource group if specified
if [ ! -z ${RESOURCE_GROUP} ]; then
    echo "Resource Group: ${RESOURCE_GROUP}"
    login_cmd="${login_cmd} -g ${RESOURCE_GROUP}"
fi

# Set sso if specified
if [ ! -z ${SSO} ]; then
    echo "Loging in with SSO"
    login_cmd="${login_cmd} --sso"
fi

# Set username if specified
if [ ! -z ${USERNAME} ]; then
    echo "User: ${USERNAME}"
    login_cmd="${login_cmd} -u ${USERNAME}"
fi

# Execute Login Command
${login_cmd}

# Get Cluster if not an environment var
if [ -z ${CLUSTER} ]; then
    ibmcloud ks clusters
    echo ""
    read -p 'Which cluster? ' cluster
    CLUSTER=${cluster}
fi

# Setup cluster config
ibmcloud ks cluster config --cluster ${CLUSTER} --network >/dev/null 2>&1

# Setup calico config if cluster is an iks classic cluster

# Get classic cluster
classic_clusters=()
mapfile -t classic_clusters< <(ibmcloud ks clusters --provider classic --output json | jq -r '.[].name')
declare -A "clusters=( $(echo ${classic_clusters[@]} | sed 's/[^ ]*/[&]="classic"/g') )"

if [[ "${clusters[${CLUSTER}]}" == "classic" ]]; then
    echo -n "Setting up calicoctl..."
    kubectx=$(kubectl config view -o jsonpath='{.current-context}')
    cluster_name=$(echo "${kubectx}" | sed -e 's/\/admin//')
    KUBECONFIG=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"${cluster_name}\")].cluster.certificate-authority}")
    CERTS_DIR=$(dirname ${KUBECONFIG})

    # Copy Calico config
    mkdir -p /etc/calico
    cp ${CERTS_DIR}/calicoctl.cfg /etc/calico/calicoctl.cfg
    echo "done"
else # assume vpc-gen2 cluster
    # get cluster info
    cluster_info=$(ibmcloud oc cluster get --cluster ${CLUSTER} --output json) || { echo "FAILED to get cluster [${CLUSTER}] info"; exit 1; }
    [[ -z ${cluster_info} ]] && { echo "FAILED to get cluster [${CLUSTER}] info"; exit 1; }
    # Setup OC cli
    echo "Get an OTP from: https://iam.cloud.ibm.com/identity/passcode"
    read -s -p 'IAM OTP: ' IAM_OTP
    echo ""
    # get the master url
    master_url=$(echo "${cluster_info}" | jq -r '.masterURL')
    [[ -z ${master_url} ]] && { echo "FAILED to get the master URL for the cluster [${CLUSTER}]"; exit 1; }

    # login to the OpenShift Cluster
    echo -n "Logging into OpenShift cluster ${CLUSTER}..."
    /lib/ld-musl-x86_64.so.1 --library-path /lib /usr/local/bin/oc login -u passcode -p ${IAM_OTP} --server=${master_url}
fi


bash
