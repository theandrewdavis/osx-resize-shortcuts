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
#include <Carbon/Carbon.h>

CGEventRef cgEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);
void setForegroundWindowRect(CGRect rect);

int main(int argc, const char **argv) {
    CFMachPortRef eventTap;
    CFRunLoopSourceRef runLoopSource;

    // Make sure this app is authorized to use the accessibility API.
    if (!AXAPIEnabled() && !AXIsProcessTrusted()) {
        printf("Can't use accessibility API!\n");
        return 1;
    }

    // Set up a keyboard hook callback.
    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, CGEventMaskBit(kCGEventKeyUp), cgEventCallback, NULL);
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);
    CFRunLoopRun();
    return 0;
}

// Respond to keypresses and call window resize functions when needed.
CGEventRef cgEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    static const int kLeftKey = 123;
    static const int kRightKey = 124;
    static const int kUpKey = 126;

    CGEventFlags flags;
    CGKeyCode keycode;
    CGRect fullScreenRect;
    CGRect partialScreenRect;
    if (type == kCGEventKeyUp) {
        flags = CGEventGetFlags(event);
        if (flags & kCGEventFlagMaskCommand && flags & kCGEventFlagMaskAlternate) {
            keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
            switch (keycode) {
                case kLeftKey:
                    fullScreenRect = [NSScreen mainScreen].visibleFrame;
                    partialScreenRect = CGRectMake(0, 0, fullScreenRect.size.width / 2, fullScreenRect.size.height);
                    setForegroundWindowRect(partialScreenRect);
                    return NULL;
                case kRightKey:
                    fullScreenRect = [NSScreen mainScreen].visibleFrame;
                    partialScreenRect = CGRectMake(fullScreenRect.size.width / 2, 0, fullScreenRect.size.width / 2, fullScreenRect.size.height);
                    setForegroundWindowRect(partialScreenRect);
                    return NULL;
                case kUpKey:
                    setForegroundWindowRect([NSScreen mainScreen].visibleFrame);
                    return NULL;
            }
        }
    }
    return event;
}

// Resize the main window of the foreground app.
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