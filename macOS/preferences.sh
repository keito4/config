# com.apple.dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock largesize -float 100
defaults write com.apple.finder AppleShowAllFiles -boolean true

# Additional preferences can be added below

killall Dock
killall SystemUIServer
killall Finder
