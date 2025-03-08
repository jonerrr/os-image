#!/usr/bin/env bash

set -euo pipefail

for vm in $(virsh list --all --name); do [ -n "$vm" ] && virsh dumpxml "$vm" >"/home/jonah/vms/${vm}.xml"; done
