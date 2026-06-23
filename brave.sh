#!/bin/bash

defaults write com.brave.Browser HomepageIsNewTabPage -bool true
defaults write com.brave.Browser BackgroundModeEnabled -bool false
defaults write com.brave.Browser BraveRewardsDisabled -bool true
defaults write com.brave.Browser BraveWalletDisabled -bool true
defaults write com.brave.Browser BraveVPNDisabled -bool true
defaults write com.brave.Browser BraveAIChatEnabled -bool false
defaults write com.brave.Browser TorDisabled -bool true
defaults write com.brave.Browser PasswordManagerEnabled -bool false
defaults write com.brave.Browser NewTabPageLocation -string "https://search.brave.com"

# Disable Tor browsing
defaults write com.brave.Browser TorDisabled -bool true

# Disable Leo AI
defaults write com.brave.Browser BraveAIChatEnabled -bool false
defaults write com.brave.Browser BraveLeoEnabled -bool false
defaults write com.brave.Browser BraveChatEnabled -bool false
defaults write com.brave.Browser BraveAIEnabled -bool false

# Disable Brave Wallet
defaults write com.brave.Browser BraveWalletDisabled -bool true
defaults write com.brave.Browser CryptoWalletEnabled -bool false

# Disable Brave Rewards
defaults write com.brave.Browser BraveRewardsDisabled -bool true

# Disable Brave VPN
defaults write com.brave.Browser BraveVPNDisabled -bool true

defaults write com.brave.Browser HomepageIsNewTabPage -bool true
