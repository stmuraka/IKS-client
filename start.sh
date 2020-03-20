#!/bin/sh

set -e

# Update the cli if available
ibmcloud update -f
# Update the plugins if available
ibmcloud plugin update --all --force
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

# Valid Regions as of 20200306
if [ ! -z ${REGION} ]; then
    REGION=$(echo "${REGION}" | awk '{print tolower($0)}')
    case ${REGION} in
        "au-syd")
            # Sydney
            login_cmd="${login_cmd} -r ${REGION}"
            ;;
        "eu-de")
            # Frankfort
            login_cmd="${login_cmd} -r ${REGION}"
            ;;
        "eu-gb")
            # London
            login_cmd="${login_cmd} -r ${REGION}"
            ;;
        "in-che")
            # Chennai
            login_cmd="${login_cmd} -r ${REGION}"
            ;;
        "jp-osa")
            # Osaka
            login_cmd="${login_cmd} -r ${REGION}"
            ;;
        "jp-tok")
            # Tokyo
            login_cmd="${login_cmd} -r ${REGION}"
            ;;
        "kr-seo")
            # Seoul
            login_cmd="${login_cmd} -r ${REGION}"
            ;;
        "us-east")
            # Washington DC
            login_cmd="${login_cmd} -r ${REGION}"
            ;;
        "us-south")
            # Dallas
            login_cmd="${login_cmd} -r ${REGION}"
            ;;
        "us-south-test")
            # Dallas
            login_cmd="${login_cmd} -r ${REGION}"
            ;;
        *)
            echo "WARNING: Unknown region: ${REGION}"
            login_cmd="${login_cmd} --no-region"
            ;;
    esac
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
kubectx=$(kubectl config view -o jsonpath='{.current-context}')
cluster_name=$(echo "${kubectx}" | sed -e 's/\/admin//')
KUBECONFIG=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"${cluster_name}\")].cluster.certificate-authority}")
CERTS_DIR=$(dirname ${KUBECONFIG})

# Copy Calico config
mkdir -p /etc/calico
cp ${CERTS_DIR}/calicoctl.cfg /etc/calico/calicoctl.cfg

bash
