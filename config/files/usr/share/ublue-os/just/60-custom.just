import '100-bling.just'
# Include some of your custom scripts here!
create-devbox:
    distrobox-create --name dev --image ghcr.io/jonerrr/devbox:latest --nvidia --additional-flags '--publish-all'

       
