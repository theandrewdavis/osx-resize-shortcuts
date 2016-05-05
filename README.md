I'm a big fan of the Windows 7 keyboard shortcuts that resize your current window. Since I do a lot of coding on a laptop screen, it's really important to be able to quickly show two windows side by side. I've been using [SizeUp](https://www.irradiatedsoftware.com/sizeup/) to mimic that behavior on OS X, but I knew it would be pretty simple to roll my own. So here it is, in about 110 lines of Objective-C. The exact keys used in Windows are already taken in OS X, so here's the keyboard shortcuts I used and their Windows equivalents:

Action|OS X|Windows 7
------|----|---------
Fit window to left half of screen|Command+Option+Left|Windows+Left
Fit window to right half of screen|Command+Option+Right|Windows+Right
Fit window to whole screen|Command+Option+Up|Windows+Up

### Install
This will download the progam to /Applications, download a config file that will keep the program running across reboots, give the program execute permissions, and start it up with `launchd`.
````
curl -L -o /Applications/ResizeShortcuts https://github.com/theandrewdavis/osx-resize-shortcuts/releases/download/0.3/ResizeShortcuts
curl -L -o ~/Library/LaunchAgents/com.ResizeShortcuts.plist https://github.com/theandrewdavis/osx-resize-shortcuts/releases/download/0.3/com.ResizeShortcuts.plist
chmod ug+x /Applications/ResizeShortcuts
launchctl load ~/Library/LaunchAgents/com.ResizeShortcuts.plist
````

### Uninstall
This will un-schedule the program in `launchd` and delete the program files.
````
launchctl unload ~/Library/LaunchAgents/com.ResizeShortcuts.plist
rm -f /Applications/ResizeShortcuts ~/Library/LaunchAgents/com.ResizeShortcuts.plist
````

### References
I wrote this with the help of the several excellent code samples and references below:
* [Tapping keyboard events](http://stackoverflow.com/questions/1776567/osx-quartz-event-taps-event-types-and-how-to-edit-events)
* [Resizing windows and the Accessibility API](http://stackoverflow.com/questions/614185/window-move-and-resize-apis-in-os-x)
* [Get the screen size](http://stackoverflow.com/questions/4982656/programmatically-get-screen-size-in-mac-os-x)
* [launchd](http://launchd.info/)
