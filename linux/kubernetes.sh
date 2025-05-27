## kubectl
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

## kubectx && kubens
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

## kustomize
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
sudo mv ./kustomize /usr/local/kustomize

## helmfile
wget https://github.com/roboll/helmfile/releases/download/v0.139.7/helmfile_linux_amd64
chmod +x helmfile_linux_amd64 && sudo mv helmfile_linux_amd64 /usr/local/bin/helmfile

## stern
wget https://github.com/wercker/stern/releases/download/1.11.0/stern_linux_amd64
chmod +x stern_linux_amd64
sudo mv stern_linux_amd64 /usr/local/bin/stern

## k9s
curl -sS https://webinstall.dev/k9s | bash
