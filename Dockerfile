FROM alpine:latest
MAINTAINER Shaun Murakami (stmuraka@gmail.com)

ARG CALICOCTL_VERSION=3.11.1
ARG KUBECTL_VERSION=1.16.4
ARG HELM_VERSION=2.16.1

RUN apk update; \
    apk upgrade; \
    apk add \
        curl \
        bash \
        bash-completion \
        sudo \
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
    echo "alias icr='ibmcloud cr'" >> ~/.bashrc; \
    echo "alias k='kubectl'" >> ~/.bashrc; \
    echo "alias c='calicoctl'" >> ~/.bashrc; \
    echo "alias h='helm'" >> ~/.bashrc

WORKDIR /root/

# Install IBM Cloud CLI
RUN curl -fsSL https://clis.ng.bluemix.net/install/linux | sh

# Install IKS plugin
RUN ibmcloud plugin install container-service -r Bluemix

# Install ICR plugin
RUN ibmcloud plugin install container-registry -r Bluemix

# Download kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# Download calicoctl
ADD https://github.com/projectcalico/calicoctl/releases/download/v${CALICOCTL_VERSION}/calicoctl-linux-amd64 /usr/local/bin/calicoctl
RUN chmod +x /usr/local/bin/calicoctl

# Download helm
ADD https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz /tmp/helm.tar.gz
RUN tar -C /tmp -zxvf /tmp/helm.tar.gz \
 && if [[ -f /tmp/linux-amd64/tiller ]]; then \
     mv /tmp/linux-amd64/tiller /usr/local/bin/tiller-v${HELM_VERSION} \
     && ln -s /usr/local/bin/tiller-v${HELM_VERSION} /usr/local/bin/tiller; \
     fi \
 && mv /tmp/linux-amd64/helm /usr/local/bin/helm-v${HELM_VERSION} \
 && ln -s /usr/local/bin/helm-v${HELM_VERSION} /usr/local/bin/helm \
 && rm -f /tmp/helm.tar.gz \
 && rm -rf /tmp/linux-amd64

# Add startup script
ADD start.sh /root/start.sh

# Start container
ENV API_KEY=""\
    API_ENDPOINT=""\
    ACCOUNT_ID=""\
    CLUSTER=""\
    REGION=""\
    USERNAME=""\
    TEST=""

CMD ./start.sh
