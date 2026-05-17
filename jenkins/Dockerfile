FROM jenkins/jenkins:lts-jdk17

USER root

RUN apt-get update && apt-get install -y \
    python3 python3-pip curl unzip wget jq less && \
    apt-get clean

RUN curl -fsSL https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_arm64.zip -o /tmp/tf.zip && \
    unzip /tmp/tf.zip -d /usr/local/bin/ && rm /tmp/tf.zip

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

USER jenkins
