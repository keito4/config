# com.apple.dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock largesize -float 100
defaults write com.apple.finder AppleShowAllFiles -boolean true

# TODO: Add other preferences here

killall Dock
killall Dockkillall SystemUIServer
killall Dockkillall Finder
