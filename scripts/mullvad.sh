#!/bin/bash
sudo tee -a /etc/yum.repos.d/mullvad.repo << 'EOF'
[mullvad-stable]
name=Mullvad VPN
baseurl=https://repository.mullvad.net/rpm/stable/$basearch
type=rpm
enabled=1
gpgcheck=1
gpgkey=https://repository.mullvad.net/rpm/mullvad-keyring.asc
EOF
