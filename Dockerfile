FROM alpine:latest
MAINTAINER Shaun Murakami (stmuraka@gmail.com)

ARG CALICOCTL_VERSION=anonymous
ARG KUBECTL_VERSION=1.31.0
ARG HELM3_VERSION=3.15.4
ARG OC_VERSION=4.16.10

RUN apk update; \
    apk upgrade; \
    apk add --no-cache \
        curl \
        bash \
        bash-completion \
        sudo \
        jq \
        yq \
        docker \
        vim

# update shell to bash
RUN sed -i -e '/^root/ s/\/bin\/ash/\/bin\/bash/' /etc/passwd; \
    echo "export PS1='\u@\h:\W \$ '" >> ~/.bashrc; \
    echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc; \
    echo "source /usr/local/ibmcloud/autocomplete/bash_autocomplete" >> ~/.bashrc; \
    echo "source <(kubectl completion bash)" >> ~/.bashrc

# add aliases
RUN echo "" >> ~/.bashrc; \
    echo "# Aliases" >> ~/.bashrc; \
    echo "alias ic='ibmcloud'" >> ~/.bashrc; \
    echo "alias iks='ibmcloud ks'" >> ~/.bashrc; \
    echo "alias ioc='ibmcloud oc'" >> ~/.bashrc; \
    echo "alias icr='ibmcloud cr'" >> ~/.bashrc; \
    echo "alias k='kubectl'" >> ~/.bashrc; \
    echo "alias c='calicoctl'" >> ~/.bashrc; \
    echo "alias h='helm'" >> ~/.bashrc; \
    echo "alias oc='/lib/ld-musl-x86_64.so.1 --library-path /lib /usr/local/bin/oc'" >> ~/.bashrc; \
    echo "alias odo='/lib/ld-musl-x86_64.so.1 --library-path /lib /usr/local/bin/odo'" >> ~/.bashrc

# Fix vi mapping
RUN rm /usr/bin/vi; \
    ln -s /usr/bin/vim /usr/bin/vi

WORKDIR /root/

# Install IBM Cloud CLI
RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

# Install plugins: IKS, ICR, ICF, COS, VPC, observability
RUN ibmcloud plugin install \
    container-service \
    container-registry \
    cloud-functions \
#    cloud-object-storage \
    vpc-infrastructure \
    observe-service

# Download kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# Download calicoctl
ADD https://github.com/projectcalico/calicoctl/releases/download/v${CALICOCTL_VERSION}/calicoctl-linux-amd64 /usr/local/bin/calicoctl
RUN chmod +x /usr/local/bin/calicoctl

# Download helm v3
ADD https://get.helm.sh/helm-v${HELM3_VERSION}-linux-amd64.tar.gz /tmp/helm3.tar.gz
RUN tar -C /tmp -zxvf /tmp/helm3.tar.gz \
 && mv /tmp/linux-amd64/helm /usr/local/bin/helm-v${HELM3_VERSION} \
 && rm -f /tmp/helm3.tar.gz \
 && rm -rf /tmp/linux-amd64

# Download oc
ADD https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux-${OC_VERSION}.tar.gz /tmp/oc.tar.gz
RUN tar -C /tmp -zxvf /tmp/oc.tar.gz \
 && mv /tmp/oc /usr/local/bin/oc \
 && rm -f /tmp/oc.tar.gz kubectl README.md

# Download odo (OpenShift Do) client
ADD https://mirror.openshift.com/pub/openshift-v4/clients/odo/latest/odo-linux-amd64 /usr/local/bin/odo
RUN chmod 755 /usr/local/bin/odo

# Add startup script
ADD start.sh /root/start.sh

# Start container
ENV API_KEY=""\
    API_ENDPOINT=""\
    ACCOUNT_ID=""\
    CLUSTER=""\
    HELM="3"\
    REGION=""\
    RESOURCE_GROUP=""\
    USERNAME=""\
    SSO=""\
    TEST=""

CMD ./start.sh
