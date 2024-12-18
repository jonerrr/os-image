set -oue pipefail

curl -LO https://raw.githubusercontent.com/creativeprojects/resticprofile/master/install.sh
chmod +x install.sh
./install.sh -b /usr/bin