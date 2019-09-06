# linuxkit-mac80211_hwsim

Container for the WiFi hardware simulator &amp; associated kernel modules built against linuxkit kernels.

# Using

## Determine your kernel version

`docker run --rm alpine:latest uname -r`

Then use the result as a tag below, rather than "latest".

## From docker hub

Just run it like so:

`docker run --rm -v /lib/modules:/lib/modules --cap-add CAP_SYS_MODULE singelet/linuxkit-mac80211_hwsim:latest`

## In linuxkit

Add this to your .yml:

```
 - name: mac80211_hwsim
    image: singelet/linuxkit-mac80211_hwsim:latest
    command: ["/bin/sh", "/probe.sh"]
    binds:
     - /lib/modules:/lib/modules
    capabilities:
     - CAP_SYS_MODULE
```
