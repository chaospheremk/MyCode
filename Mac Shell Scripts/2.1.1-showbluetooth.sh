#!/bin/sh
for user in $(users)
do
    check=sudo -u "$user" defaults read /Users/<username>/Library/Preferences/com.apple.systemuiserver menuExtras | grep Bluetooth.menu
    if [ -z "$check" ]
    then
        sudo -u "$user" defaults write /Users/<username>/Library/Preferences/com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"
    fi
done