set -oue pipefail

sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/org.gnome.Terminal.desktop
# systemctl enable dconf-update.service

# wget https://gitlab.com/magnolia1234/bpc-uploads/-/raw/master/bypass_paywalls_clean-latest.xpi
# unzip bypass_paywalls_clean-latest.xpi -d /usr/share/mozilla/extensions/{69f99f63-e703-4fda-9068-b716208bb0cd}/