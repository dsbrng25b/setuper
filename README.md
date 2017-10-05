# Installation


* load keymap `loadkeys sg`
* set up wlan
```shell
ip link set wlp3s0 up
iw dev wlp3s0 scan | less # look for ssids
wpa_supplicant -i wlp3s0 -c <( wpa_passphrase "SSID" "PASSWORD" ) -B
dhcpcd wlp3s0
```
* get install script `curl -O https://raw.githubusercontent.com/dsbrng25b/setuper/master/base.sh`
* run install script `sh base.sh`
