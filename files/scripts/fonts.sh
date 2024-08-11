#!/usr/bin/env bash

set -oue pipefail

echo 'installing mscorefonts2'
wget 'https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm'
sudo rpm-ostree install -y msttcore-fonts-installer-2.6-1.noarch.rpm

