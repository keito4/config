sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
usermod -aG nordvpn $USER
nordvpn login
# nordvpn login --callback "nordvpn://login?"

nordvpn set meshnet on
nordvpn whitelist add port 22
nordvpn whitelist add port 80
nordvpn whitelist add port 443
nordvpn whitelist add port 6443
# nordvpn whitelist add subnet 192.168.0.119/32

sudo apt install nodejs
curl -L https://npmjs.org/install.sh | sudo sh

