I'm a big fan of the Windows 7 keyboard shortcuts that resize your current window. Since I do a lot of coding on a laptop screen, it's really important to be able to quickly show two windows side by side. I've been using [SizeUp](https://www.irradiatedsoftware.com/sizeup/) to mimic that behavior, but I knew it would be pretty simple to roll my own. So here it is, in about 110 lines of Objective-C. The exact keys used in Windows are already taken in OS X, so here's the keyboard shortcuts I used and their Windows equivalents:

Action|OS X|Windows 7
-------------------------
Fit window to left half of screen|Command+Option+Left|Windows+Left
Fit window to right half of screen|Command+Option+Right|Windows+Right
Fit window to whole screen|Command+Option+Up|Windows+Up

## Install
This will download the progam to /Applications, download a config file that will keep the program running across reboots, and start it up with `launchd`.
````
curl -o /Applications/ResizeShortcuts github.com/...
curl -o ~/Library/LaunchAgents/com.ResizeShortcuts.plist github.com/...
launchctl load ~/Library/LaunchAgents/com.ResizeShortcuts.plist
````

## Uninstall
This will un-schedule the program in `launchd` and delete the program files.
````
launchctl unload ~/Library/LaunchAgents/com.ResizeShortcuts.plist
rm -f /Applications/ResizeShortcuts ~/Library/LaunchAgents/com.ResizeShortcuts.plist
````
