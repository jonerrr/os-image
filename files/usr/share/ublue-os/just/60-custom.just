create-devbox:
    distrobox-create --name dev --image ghcr.io/jonerrr/devbox:latest --pull --nvidia --additional-flags '--publish-all'
firefox-gnome-theme:
    curl -s -o- https://raw.githubusercontent.com/rafaelmardojai/firefox-gnome-theme/master/scripts/install-by-curl.sh | bash
get-flatpaks:
    flatpak remote-add --if-not-exists GNOME-Nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo && flatpak remote-add --if-not-exists Valent https://valent.andyholmes.ca/valent.flatpakrepo && flatpak install ca.andyholmes.Valent
dconf:
    sudo dconf load / < /etc/dconf/db/local.d/05-default-keybinds
vm-gpu-kargs:
    sudo rpm-ostree kargs --append-if-missing="intel_iommu=on" --append-if-missing "iommu=pt" --append-if-missing "rd.driver.pre=vfio_pci" --append-if-missing="vfio-pci.ids=10de:1c03,10de:10f1"
vm-gpu-initramfs:
    sudo rpm-ostree initramfs --enable --arg="add-drivers" --arg="vfio-pci"
# /dev/i2c-6 is secondary monitor (HDMI = host, DP = guest)
# /dev/i2c-7 is first monitor (DP = host, HDMI = guest)
vm-display:
    ddcutil --bus 6 setvcp 60 0x01 & ddcutil --bus 7 setvcp 60 0x11 & wait
host-display:
    ddcutil --bus 6 setvcp 60 0x11 & ddcutil --bus 7 setvcp 60 0x01 & wait