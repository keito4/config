FROM codercom/code-server

RUN sudo chown coder:coder /home/coder -R && sudo chmod 777 -R /home/coder
RUN sudo apt-get update && sudo apt-get install --no-install-recommends -y \
  curl \
  make

ENV SHELL /usr/bin/zsh
RUN curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | zsh

ENV GO_VERSION 1.18
RUN curl -L https://dl.google.com/go/go$GO_VERSION.linux-arm64.tar.gz -o /tmp/go.tar.gz \
  && sudo tar -C /usr/local/ -xzf /tmp/go.tar.gz \
  && rm /tmp/go.tar.gz

ADD ./zsh /home/coder/.zsh
ADD ./sh/.zprofile /home/coder/.zprofile
ADD ./sh/.zshrc /home/coder/.zshrc

RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-370.0.0-linux-arm.tar.gz \
  && tar -zxvf google-cloud-sdk-370.0.0-linux-arm.tar.gz \
  && sudo ./google-cloud-sdk/install.sh -q --usage-reporting false --rc-path ~/.zshrc --path-update true \
  && rm google-cloud-sdk-370.0.0-linux-arm.tar.gz

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
  && chmod +x kubectl \
  && sudo mv kubectl /usr/local/bin

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
  && chmod +x get_helm.sh \
  && ./get_helm.sh \
  && rm get_helm.sh

RUN /usr/local/go/bin/go install github.com/x-motemen/ghq@latest

RUN mkdir /home/coder/develop
RUN mkdir -p /home/coder/.local/share/code-server/User
WORKDIR /home/coder/develop

ADD . /home/coder/config
ADD ./vscode/settings.json /home/coder/.local/share/code-server/User/settings.json
ADD ./vscode/keybindings.json /home/coder/.local/share/code-server/User/keybindings.json

