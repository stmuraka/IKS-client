#!/bin/sh

set -e

# Update the cli if available
ibmcloud update -f
# Update the plugins if available
ibmcloud plugin update container-service -r Bluemix
ibmcloud plugin update container-registry -r Bluemix
echo ""

# Login to IBM Cloud
login_cmd="ibmcloud login"

if [ ! -z ${API_KEY} ]; then
    login_cmd="${login_cmd} --apikey ${API_KEY}"
fi
if [ ! -z ${API_ENDPOINT} ]; then
    login_cmd="${login_cmd} -a ${API_ENDPOINT}"
fi
if [ ! -z ${ACCOUNT_ID} ]; then
    login_cmd="${login_cmd} -c ${ACCOUNT_ID}"
fi
if [ ! -z ${USERNAME} ]; then
    echo "User: ${USERNAME}"
    login_cmd="${login_cmd} -u ${USERNAME}"
fi
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
