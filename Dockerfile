FROM alpine:latest
MAINTAINER Shaun Murakami (stmuraka@gmail.com)

ARG CALICOCTL_VERSION=3.1.3
ARG KUBECTL_VERSION=1.11.1

RUN apk update; \
    apk upgrade; \
    apk add \
        curl \
        bash \
        bash-completion

# update shell to bash
RUN sed -i -e '/^root/ s/\/bin\/ash/\/bin\/bash/' /etc/passwd; \
    echo "export PS1='\u@\h:\W \$ '" >> ~/.bashrc; \
    echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc; \
    echo "source /usr/local/ibmcloud/bx/bash_autocomplete" >> ~/.bashrc; \
    echo "source <(kubectl completion bash)" >> ~/.bashrc

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

# Add startup script
ADD start.sh /root/start.sh

# Start container
ENV API_KEY=""\
    API_ENDPOINT=""\
    CLUSTER=""\
    REGION=""

CMD ./start.sh
