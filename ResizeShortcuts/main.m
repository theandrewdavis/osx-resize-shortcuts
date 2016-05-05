//
//  main.m
//  ResizeShortcuts
//
//  Created by Andrew Davis on 2/10/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#include <AppKit/AppKit.h>

CGEventRef keypressCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);
void setForegroundWindowRect(CGRect rect);

int main(int argc, const char **argv) {
    CFMachPortRef eventTap;
    CGEventMask eventMask;
    CFRunLoopSourceRef runLoopSource;

    // Make sure this app is authorized to use the accessibility API.
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    if (!AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options)) {
        printf("Can't use accessibility API!\n");
        return 1;
    }

    // Set up a keyboard hook callback.
    eventMask = CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventKeyDown);
    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, keypressCallback, NULL);
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);
    CFRunLoopRun();
    return 0;
}

// Respond to keypresses and call window resize functions when needed.
CGEventRef keypressCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    static const int kLeftKey = 123;
    static const int kRightKey = 124;
    static const int kUpKey = 126;

    CGEventFlags flags;
    CGKeyCode keycode;
    CGRect fullScreenRect;
    CGRect partialScreenRect;

    flags = CGEventGetFlags(event);
    keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

    // Skip keypresses that don't have command and alt pressed.
    if (!(flags & kCGEventFlagMaskCommand) || !(flags & kCGEventFlagMaskAlternate)) {
        return event;
    }

    // Skip keypresses that aren't left, up, or right.
    if (keycode != kLeftKey && keycode != kRightKey && keycode != kUpKey) {
        return event;
    }

    // Block command-alt-arrow keydown events.
    if (type == kCGEventKeyDown) {
        return NULL;
    }

    // Resize windows on command-alt-arrow keyup events and block further key processing.
    switch (keycode) {
        case kLeftKey:
            fullScreenRect = [NSScreen mainScreen].visibleFrame;
            partialScreenRect = CGRectMake(0, 0, fullScreenRect.size.width / 2, fullScreenRect.size.height);
            setForegroundWindowRect(partialScreenRect);
            break;
        case kRightKey:
            fullScreenRect = [NSScreen mainScreen].visibleFrame;
            partialScreenRect = CGRectMake(fullScreenRect.size.width / 2, 0, fullScreenRect.size.width / 2, fullScreenRect.size.height);
            setForegroundWindowRect(partialScreenRect);
            break;
        case kUpKey:
            setForegroundWindowRect([NSScreen mainScreen].visibleFrame);
            break;
    }
    return NULL;
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