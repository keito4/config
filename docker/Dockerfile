FROM codercom/code-server

RUN sudo chown coder:coder /home/coder -R && sudo chmod 777 -R /home/coder
RUN sudo apt-get update && sudo apt-get install --no-install-recommends -y \
  curl \
  make \
  gcc \
  python3 \
  python-is-python3

ENV SHELL=/usr/bin/zsh

RUN mkdir /home/coder/develop
RUN mkdir -p /home/coder/.local/share/code-server/User
WORKDIR /home/coder/develop

ADD . /home/coder/config

RUN /home/coder/config/script/import.sh
