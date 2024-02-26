create-devbox:
    distrobox-create --name dev --image ghcr.io/jonerrr/devbox:latest --pull --nvidia --additional-flags '--publish-all'
firefox-gnome-theme:
    curl -s -o- https://raw.githubusercontent.com/rafaelmardojai/firefox-gnome-theme/master/scripts/install-by-curl.sh | bash
get-addons:
    wget wget https://gitlab.com/magnolia1234/bpc-uploads/-/raw/master/bypass_paywalls_clean-latest.xpi -P ~/Downloads/