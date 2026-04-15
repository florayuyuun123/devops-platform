FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    bash curl wget git vim nano less tree htop jq \
    net-tools iputils-ping dnsutils nmap netcat-openbsd tmux \
    python3 python3-pip ansible \
    openssh-client openssh-server \
    sudo man-db unzip conntrack \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -Ls \
    https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl && mv kubectl /usr/local/bin/

# minikube
RUN curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
    && chmod +x minikube && mv minikube /usr/local/bin/


# terraform
RUN wget -q https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip \
    && unzip terraform_1.7.0_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_1.7.0_linux_amd64.zip

# ttyd — browser-based terminal server
RUN curl -Lo /usr/local/bin/ttyd \
    https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 \
    && chmod +x /usr/local/bin/ttyd

# student user — no password needed inside sandbox
RUN useradd -m -s /bin/bash student \
    && echo "student:devops2024" | chpasswd \
    && usermod -aG sudo student \
    && echo "student ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "export PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '" > /etc/profile.d/99-colors.sh \
    && echo "alias ls='ls --color=auto'" >> /etc/profile.d/99-colors.sh \
    && rm -f /home/student/.bashrc

COPY welcome.sh /etc/profile.d/welcome.sh
RUN chmod +x /etc/profile.d/welcome.sh

WORKDIR /home/student
USER student

# Default command: serve a web terminal on port 7681
EXPOSE 7681
CMD ["ttyd", "-p", "7681", "tmux", "new-session", "-A", "-s", "devops", "bash", "--login"]
