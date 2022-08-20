export GOPATH=$HOME/go

export GOROOT="$(go env GOROOT)"
export GOOS="$(go env GOOS)"
export GOARCH="$(go env GOARCH)"
export CGO_ENABLED=1
export GO111MODULE=on
export GOBIN=$GOPATH/bin
export GO15VENDOREXPERIMENT=1
export NVIM_GO_LOG_FILE=$XDG_DATA_HOME/go

export PATH=$GOBIN:$GOROOT/bin:$PATH
