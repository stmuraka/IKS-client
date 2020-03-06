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
    ibmcloud cs clusters
    echo ""
    read -p 'Which cluster? ' cluster
else
    cluster=${CLUSTER}
fi

# Setup cluster config
cluster_config=$(ibmcloud cs cluster-config ${cluster} --admin | grep '^export')
eval ${cluster_config}
eval $(echo ${cluster_config} | awk '{print $2}')
echo "Cluster config stored in: ${cluster_config}"

# Get ETCD_URL
ETCD_URL=$(kubectl get cm -n kube-system calico-config -o yaml | grep "etcd_endpoints:" | awk '{ print $2 }')
CERTS_DIR=$(dirname $KUBECONFIG)
capem_file=$(ls `dirname $KUBECONFIG` | grep "ca-")

# Setup Calico config
mkdir -p /etc/calico
cat <<- EOF > /etc/calico/calicoctl.cfg
apiVersion: projectcalico.org/v3
kind: CalicoAPIConfig
metadata:
spec:
    datastoreType: etcdv3
    etcdEndpoints: ${ETCD_URL}
    etcdKeyFile: ${CERTS_DIR}/admin-key.pem
    etcdCertFile: ${CERTS_DIR}/admin.pem
    etcdCACertFile: ${CERTS_DIR}/${capem_file}
EOF

bash
