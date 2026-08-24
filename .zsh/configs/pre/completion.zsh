# Vagrant (compinit より前に fpath へ追加する必要がある)
for _vagrant_comp_dir in /opt/vagrant/embedded/gems/*/gems/vagrant-*/contrib/zsh(/N); do
  fpath=("$_vagrant_comp_dir" $fpath)
  break
done
unset _vagrant_comp_dir

# compinit: use cache within 24h, full security check once per day
autoload -Uz compinit
if [[ -n $HOME/.zcompdump(#qN.mh+24) ]]; then
  compinit -d $HOME/.zcompdump;
else
  compinit -C -d $HOME/.zcompdump;
fi;
