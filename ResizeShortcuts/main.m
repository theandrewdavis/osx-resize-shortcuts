//
//  main.m
//  ResizeShortcuts
//
//  Created by Andrew Davis on 2/10/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#include <ApplicationServices/ApplicationServices.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

// alterkeys.c
// http://osxbook.com
//
// Complile using the following command line:
//     gcc -Wall -o alterkeys alterkeys.c -framework ApplicationServices
//
// You need superuser privileges to create the event tap, unless accessibility
// is enabled. To do so, select the "Enable access for assistive devices"
// checkbox in the Universal Access system preference pane.


// This callback will be invoked every time there is a keystroke.
//
CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    printf("Key code!\n");

    // Paranoid sanity check.
    if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp)) {
        return event;
    }

    // The incoming keycode.
    CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

    // Swap 'a' (keycode=0) and 'z' (keycode=6).
    if (keycode == (CGKeyCode)0) {
        keycode = (CGKeyCode)6;
    }
    else if (keycode == (CGKeyCode)6) {
        keycode = (CGKeyCode)0;
    }

    // Set the modified keycode field in the event.
    CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode, (int64_t)keycode);

    // We must return the event for it to be useful.
    return event;
}

/* Carbon includes everything necessary for Accessibilty API */
#include <Carbon/Carbon.h>

bool appIsAuthorized() {
    return AXAPIEnabled() || AXIsProcessTrusted();
}

void setForegroundWindowRect(CGRect rect) {
    pid_t pid;
    ProcessSerialNumber psn;
    AXUIElementRef app;
    AXUIElementRef window;
    AXValueRef axValue;

    // Get front app.
    GetFrontProcess(&psn);
    GetProcessPID(&psn, &pid);
    app = AXUIElementCreateApplication(pid);

    // Get front app's front window.
    AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute, (CFTypeRef *)&window);

    // Set window position.
    axValue = AXValueCreate(kAXValueCGPointType, &rect.origin);
    AXUIElementSetAttributeValue(window, kAXPositionAttribute, axValue);
    CFRelease(axValue);

    // Set window size.
    axValue = AXValueCreate(kAXValueCGSizeType, &rect.size);
    AXUIElementSetAttributeValue(window, kAXSizeAttribute, axValue);
    CFRelease(axValue);

    CFRelease(window);
    CFRelease(app);
}

int main(int argc, const char **argv) {
    int i;

    if (!appIsAuthorized()) {
        printf("Can't use accessibility API!\n");
        return 1;
    }

    /* Give the user 5 seconds to switch to another window, otherwise
     * only the terminal window will be used
     */
    for (i = 0; i < 5; i++) {
        sleep(1);
        printf("%d", i + 1);
        if (i < 4) {
            printf("...");
            fflush(stdout);
        } else {
            printf("\n");
        }
    }

    CGRect screenRect = [NSScreen mainScreen].visibleFrame;
    CGRect leftScreenHalf = CGRectMake(0, 0, screenRect.size.width / 2, screenRect.size.height);
    setForegroundWindowRect(leftScreenHalf);
    return 0;
}
