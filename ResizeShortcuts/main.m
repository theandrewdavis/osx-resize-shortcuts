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

static bool amIAuthorized ()
{
    if (AXAPIEnabled() != 0) {
        /* Yehaa, all apps are authorized */
        return true;
    }
    /* Bummer, it's not activated, maybe we are trusted */
    if (AXIsProcessTrusted() != 0) {
        /* Good news, we are already trusted */
        return true;
    }
    /* Crap, we are not trusted...
     * correct behavior would now be to become a root process using
     * authorization services and then call AXMakeProcessTrusted() to make
     * ourselves trusted, then restart... I'll skip this here for
     * simplicity.
     */
    return false;
}


static AXUIElementRef getFrontMostApp ()
{
    pid_t pid;
    ProcessSerialNumber psn;

    GetFrontProcess(&psn);
    GetProcessPID(&psn, &pid);
    return AXUIElementCreateApplication(pid);
}


int main(int argc, const char **argv) {
    int i;
    AXValueRef temp;
    CGSize windowSize;
    CGPoint windowPosition;
    CFStringRef windowTitle;
    AXUIElementRef frontMostApp;
    AXUIElementRef frontMostWindow;

    if (!amIAuthorized()) {
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

    /* Here we go. Find out which process is front-most */
    frontMostApp = getFrontMostApp();

    /* Get the front most window. We could also get an array of all windows
     * of this process and ask each window if it is front most, but that is
     * quite inefficient if we only need the front most window.
     */
    AXUIElementCopyAttributeValue(
                                  frontMostApp, kAXFocusedWindowAttribute, (CFTypeRef *)&frontMostWindow
                                  );

    /* Get the title of the window */
    AXUIElementCopyAttributeValue(
                                  frontMostWindow, kAXTitleAttribute, (CFTypeRef *)&windowTitle
                                  );

    /* Get the window size and position */
    AXUIElementCopyAttributeValue(
                                  frontMostWindow, kAXSizeAttribute, (CFTypeRef *)&temp
                                  );
    AXValueGetValue(temp, kAXValueCGSizeType, &windowSize);
    CFRelease(temp);

    AXUIElementCopyAttributeValue(
                                  frontMostWindow, kAXPositionAttribute, (CFTypeRef *)&temp
                                  );
    AXValueGetValue(temp, kAXValueCGPointType, &windowPosition);
    CFRelease(temp);

    /* Print everything */
    printf("\n");
    CFShow(windowTitle);
    printf(
           "Window is at (%f, %f) and has dimension of (%f, %f)\n",
           windowPosition.x,
           windowPosition.y,
           windowSize.width,
           windowSize.height
           );

    /* Move the window to the right by 25 pixels */
    windowPosition.x += 25;
    temp = AXValueCreate(kAXValueCGPointType, &windowPosition);
    AXUIElementSetAttributeValue(frontMostWindow, kAXPositionAttribute, temp);
    CFRelease(temp);
    
    /* Clean up */
    CFRelease(frontMostWindow);
    CFRelease(frontMostApp);
    return 0;
}



int main(int argc, const char **argv) {

    @autoreleasepool {
        NSLog(@"Hello, world!");

        NSArray *windows = CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID));
        for (NSDictionary *windowInfo in windows) {
            NSString *windowPid = windowInfo[(__bridge NSString*)kCGWindowOwnerPID];
            NSString *windowName = windowInfo[(__bridge NSString*)kCGWindowOwnerName];
            NSLog(@"pid %@ name %@", windowPid, windowName);
        }
    }

/*    CFMachPortRef      eventTap;
    CGEventMask        eventMask;
    CFRunLoopSourceRef runLoopSource;

    // Create an event tap. We are interested in key presses.
    eventMask = ((1 << kCGEventKeyDown) | (1 << kCGEventKeyUp));
    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, myCGEventCallback, NULL);
    if (!eventTap) {
        fprintf(stderr, "failed to create event tap\n");
        exit(1);
    }

    // Create a run loop source.
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);

    // Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);

    // Enable the event tap.
    CGEventTapEnable(eventTap, true); */

    // Set it all running.
    CFRunLoopRun();

    return 0;
}
