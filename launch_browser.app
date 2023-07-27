#!/bin/sh

# pocketbook system apps this script uses
browser=/ebrmain/cramfs/bin/browser.app
netagent=/ebrmain/cramfs/bin/netagent

# Exit function to restore original network conditions and browser settings
function restore {
 # if this script turned on WIFI, on exit turn off
 if [ "${wifi}" == "1" ]; then $netagent net off; fi
 # if this script turned off flight mode, checks for BT and turns off
 if [ "${flmode}" == "1" ]; then
   # BT on and connected - do nothing
   if [ -d "/sys/class/bluetooth/hci0/hci0:1" ]; then :
   # BT on and not connected
   elif [ -d "/sys/class/bluetooth/hci0" ]; then
     $netagent flightmode on
	 $netagent bt on
   # BT off
   else $netagent flightmode on
   fi
 fi
}
trap restore 0

# check flight mode off
if [ "$(netagent flightmode status)" == "flight mode = activated" ]; then
  flmode=1
  $netagent flightmode off
fi

# check wifi on
if [ ! -d "/sys/class/net/eth0" ]; then
  wifi=1
  $netagent net on
fi

dialog 1 "" "Connecting, please wait..." "" & sleep 1; kill "$!"

# check connected to wifi network - device connects to last used and available network
if [[ $(cat /sys/class/net/eth0/carrier) == 0 ]]; then
  sleep 5
  while [[ $(cat /sys/class/net/eth0/carrier) == 0 ]]; do
    dialog 5 "" "Still attempting to connect to a wireless network!  Wait?" "Yes" "No"
    if [ $? != 1 ]; then exit; fi
    $netagent connect
    sleep 3
  done
fi

# check internet connected
function internet {
  test="$(curl -Is  http://www.google.com | head -n 1)"
  test="${test:13:2}"
}
i=0
internet; if [ "$test" != "OK" ]; then
  sleep 3
  internet; while [ "$test" != "OK" ]; do
    let i++
    dialog 3 "" "No internet!  Wait?" "Yes" "No"
    if [ $? != 1 ]; then exit; fi
	# on third failed conenction prompts to connect to different network
	if [ "$i" == "3" ]; then $netagent connect; fi
    sleep 3
	internet
  done
fi

$browser https://www.mobileread.com/forums

exit 0
