#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag.
#endif

#import "springboard.h"

#import <dlfcn.h>
#import <notify.h>
#import <os/log.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import <rocketbootstrap/rocketbootstrap.h>


#define SB_SERVICE_NAME "com.darwindev.AltSpringBoard"
#define SBS_SERVICE_NAME "com.darwindev.AltSpringBoardServices"

#define SERVICE_SEND_TIMEOUT 3.0
#define SERVICE_RECV_TIMEOUT 3.0


#pragma mark -

#define SBSCopyFrontmostApplicationDisplayIdentifierMsgID 0x1000
#define SBSCopyApplicationDisplayIdentifiersMsgID 0x1001
#define SBSCopyDisplayIdentifierForProcessIDMsgID 0x1002
#define SBSCopyLocalizedApplicationNameForDisplayIdentifierMsgID 0x1003
#define SBSCopyIconImagePNGDataForDisplayIdentifierMsgID 0x1004
#define SBSCopyInfoForApplicationWithProcessIDMsgID 0x1005
#define SBSProcessIDForDisplayIdentifierMsgID 0x1006
#define SBSLaunchApplicationWithIdentifierMsgID 0x1100
#define SBSLaunchApplicationWithIdentifierAndLaunchOptionsMsgID 0x1101
#define SBSLaunchApplicationWithIdentifierAndURLAndLaunchOptionsMsgID 0x1102
#define SBSApplicationLaunchingErrorStringMsgID 0x1103


#pragma mark -

@interface SBApplication : NSObject
- (NSString *)bundleIdentifier;
@end

@interface SpringBoard : UIApplication
+ (SpringBoard *)sharedApplication;
- (SBApplication *)_accessibilityFrontMostApplication;
@end


#pragma mark -

__used
static AltSpringboardApi *AltGetSpringBoardServicesApi(void)
{
    static AltSpringboardApi *_api = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(void) {
        _api = _alt_get_springboard_api();
    });
    return _api;
}

__used
static CFMessagePortRef AltCreateSpringBoardRemotePort(void)
{
    return rocketbootstrap_cfmessageportcreateremote(kCFAllocatorDefault, CFSTR(SB_SERVICE_NAME));
}

__used
static CFMessagePortRef AltCreateSpringBoardServicesRemotePort(void)
{
    return rocketbootstrap_cfmessageportcreateremote(kCFAllocatorDefault, CFSTR(SBS_SERVICE_NAME));
}

__used
static CFDataRef AltSpringBoardCallback(CFMessagePortRef port, SInt32 messageID, CFDataRef data, void *info)
{
#if DEBUG
    NSArray *arguments = nil;
    if (data)
    {
        CFPropertyListRef argumentsList = 
            CFPropertyListCreateWithData(kCFAllocatorDefault, data, kCFPropertyListImmutable, NULL, NULL);
        if (argumentsList && CFGetTypeID(argumentsList) == CFArrayGetTypeID())
            arguments = (NSArray *)CFBridgingRelease(argumentsList);
    }
#endif
    
    CFPropertyListRef returnObj = NULL;
    if (messageID == SBSCopyFrontmostApplicationDisplayIdentifierMsgID)
    {
        NSString *bundleIdentifier = 
            [[(SpringBoard *)[objc_getClass("SpringBoard") sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier];
        returnObj = (CFPropertyListRef)CFBridgingRetain(bundleIdentifier);
    }

#if DEBUG
    os_log_debug(OS_LOG_DEFAULT, SB_SERVICE_NAME " %{public}d %{public}@ -> %{public}@", messageID, arguments, returnObj);
#endif

    if (!returnObj)
        return NULL;
    
    CFDataRef returnData =
        CFPropertyListCreateData(kCFAllocatorDefault, returnObj, kCFPropertyListBinaryFormat_v1_0, 0, NULL);
    CFRelease(returnObj);

    return returnData;
}

__used
static CFDataRef AltSpringBoardServicesCallback(CFMessagePortRef port, SInt32 messageID, CFDataRef data, void *info)
{
#if DEBUG
    os_log_debug(OS_LOG_DEFAULT, SBS_SERVICE_NAME " %{public}@ %{public}d %{public}@", port, messageID, data);
#endif

    NSArray *arguments = nil;
    if (data)
    {
        CFPropertyListRef argumentsList = 
            CFPropertyListCreateWithData(kCFAllocatorDefault, data, kCFPropertyListImmutable, NULL, NULL);
        if (argumentsList && CFGetTypeID(argumentsList) == CFArrayGetTypeID())
            arguments = (NSArray *)CFBridgingRelease(argumentsList);
    }

    CFPropertyListRef returnObj = NULL;
    if (messageID == SBSCopyApplicationDisplayIdentifiersMsgID)
    {
        if (arguments.count != 2) return NULL;
        returnObj = (CFPropertyListRef)AltGetSpringBoardServicesApi()->SBSCopyApplicationDisplayIdentifiers([arguments[0] boolValue], [arguments[1] boolValue]);
    }
    else if (messageID == SBSCopyDisplayIdentifierForProcessIDMsgID)
    {
        if (arguments.count != 1) return NULL;
        returnObj = (CFPropertyListRef)AltGetSpringBoardServicesApi()->SBSCopyDisplayIdentifierForProcessID([arguments[0] unsignedIntValue]);
    }
    else if (messageID == SBSCopyLocalizedApplicationNameForDisplayIdentifierMsgID)
    {
        if (arguments.count != 1) return NULL;
        returnObj = (CFPropertyListRef)AltGetSpringBoardServicesApi()->SBSCopyLocalizedApplicationNameForDisplayIdentifier((__bridge CFStringRef)arguments[0]);
    }
    else if (messageID == SBSCopyIconImagePNGDataForDisplayIdentifierMsgID)
    {
        if (arguments.count != 1) return NULL;
        returnObj = (CFPropertyListRef)AltGetSpringBoardServicesApi()->SBSCopyIconImagePNGDataForDisplayIdentifier((__bridge CFStringRef)arguments[0]);
    }
    else if (messageID == SBSCopyInfoForApplicationWithProcessIDMsgID)
    {
        if (arguments.count != 1) return NULL;
        returnObj = (CFPropertyListRef)AltGetSpringBoardServicesApi()->SBSCopyInfoForApplicationWithProcessID([arguments[0] unsignedIntValue]);
    }
    else if (messageID == SBSProcessIDForDisplayIdentifierMsgID)
    {
        if (arguments.count != 1) return NULL;
        returnObj = (CFPropertyListRef)CFBridgingRetain(@(AltGetSpringBoardServicesApi()->SBSProcessIDForDisplayIdentifier((__bridge CFStringRef)arguments[0])));
    }
    else if (messageID == SBSLaunchApplicationWithIdentifierMsgID)
    {
        if (arguments.count != 1) return NULL;
        returnObj = (CFPropertyListRef)CFBridgingRetain(@(AltGetSpringBoardServicesApi()->SBSLaunchApplicationWithIdentifier((__bridge CFStringRef)arguments[0])));
    }
    else if (messageID == SBSLaunchApplicationWithIdentifierAndLaunchOptionsMsgID)
    {
        if (arguments.count != 3) return NULL;
        returnObj = (CFPropertyListRef)CFBridgingRetain(@(AltGetSpringBoardServicesApi()->SBSLaunchApplicationWithIdentifierAndLaunchOptions((__bridge CFStringRef)arguments[0], (__bridge CFDictionaryRef)arguments[1], [arguments[2] boolValue])));
    }
    else if (messageID == SBSLaunchApplicationWithIdentifierAndURLAndLaunchOptionsMsgID)
    {
        if (arguments.count != 5) return NULL;
        returnObj = (CFPropertyListRef)CFBridgingRetain(@(AltGetSpringBoardServicesApi()->SBSLaunchApplicationWithIdentifierAndURLAndLaunchOptions((__bridge CFStringRef)arguments[0], (__bridge CFURLRef)arguments[1], (__bridge CFDictionaryRef)arguments[2], (__bridge CFDictionaryRef)arguments[3], [arguments[4] boolValue])));
    }
    else if (messageID == SBSApplicationLaunchingErrorStringMsgID)
    {
        if (arguments.count != 1) return NULL;
        returnObj = (CFPropertyListRef)AltGetSpringBoardServicesApi()->SBSApplicationLaunchingErrorString([arguments[0] unsignedIntValue]);
    }

#if DEBUG
    os_log_debug(OS_LOG_DEFAULT, SBS_SERVICE_NAME " %{public}d %{public}@ -> %{public}@", messageID, arguments, returnObj);
#endif

    if (!returnObj)
        return NULL;
    
    CFDataRef returnData =
        CFPropertyListCreateData(kCFAllocatorDefault, returnObj, kCFPropertyListBinaryFormat_v1_0, 0, NULL);
    CFRelease(returnObj);

    return returnData;
}


#pragma mark -

CF_EXTERN_C_BEGIN
CFStringRef SBSCopyFrontmostApplicationDisplayIdentifier(void);
CFArrayRef SBSCopyApplicationDisplayIdentifiers(BOOL active, BOOL debuggable);
CFStringRef SBSCopyDisplayIdentifierForProcessID(UInt32 pid);
CFStringRef SBSCopyLocalizedApplicationNameForDisplayIdentifier(CFStringRef identifier);
CFDataRef SBSCopyIconImagePNGDataForDisplayIdentifier(CFStringRef identifier);
CFDictionaryRef SBSCopyInfoForApplicationWithProcessID(UInt32 pid);
UInt32 SBSProcessIDForDisplayIdentifier(CFStringRef identifier);
UInt32 SBSLaunchApplicationWithIdentifier(CFStringRef identifier);
UInt32 SBSLaunchApplicationWithIdentifierAndLaunchOptions(CFStringRef identifier, CFDictionaryRef options, BOOL suspended);
UInt32 SBSLaunchApplicationWithIdentifierAndURLAndLaunchOptions(CFStringRef identifier, CFURLRef url, CFDictionaryRef params, CFDictionaryRef options, BOOL suspended);
CFStringRef SBSApplicationLaunchingErrorString(UInt32 error);
CFStringRef SBSApplicationLaunchOptionUnlockDeviceKey = CFSTR("unlockDevice");
CF_EXTERN_C_END


#pragma mark -

CFStringRef SBSCopyFrontmostApplicationDisplayIdentifier(void)
{
    if (@available(iOS 15.0, *))
    {
        CFMessagePortRef remotePort = AltCreateSpringBoardRemotePort();
        if (!remotePort) return NULL;
        
        CFDataRef returnData = NULL;
        SInt32 status =
            CFMessagePortSendRequest(remotePort,
                                    SBSCopyFrontmostApplicationDisplayIdentifierMsgID,
                                    NULL,
                                    SERVICE_SEND_TIMEOUT,
                                    SERVICE_RECV_TIMEOUT,
                                    kCFRunLoopDefaultMode,
                                    &returnData);
        CFRelease(remotePort);
        
        if (status != kCFMessagePortSuccess)
            return NULL;

        CFPropertyListRef propertyList =
            CFPropertyListCreateWithData(kCFAllocatorDefault, returnData, kCFPropertyListImmutable, NULL, NULL);
        CFRelease(returnData);

        if (!propertyList) return NULL;

        if (CFGetTypeID(propertyList) != CFStringGetTypeID()) {
            CFRelease(propertyList);
            return NULL;
        }

        return (CFStringRef) propertyList;
    }
    else
    {
        return AltGetSpringBoardServicesApi()->SBSCopyFrontmostApplicationDisplayIdentifier();
    }
}

CFArrayRef SBSCopyApplicationDisplayIdentifiers(BOOL active, BOOL debuggable)
{
    if (@available(iOS 15.0, *))
    {
        CFMessagePortRef remotePort = AltCreateSpringBoardServicesRemotePort();
        if (!remotePort) return NULL;

        CFArrayRef arguments = (__bridge CFArrayRef)@[@(active), @(debuggable)];
        CFDataRef argumentsData = 
            CFPropertyListCreateData(kCFAllocatorDefault, arguments, kCFPropertyListBinaryFormat_v1_0, 0, NULL);

        CFDataRef returnData = NULL;
        SInt32 status =
            CFMessagePortSendRequest(remotePort,
                                    SBSCopyApplicationDisplayIdentifiersMsgID,
                                    argumentsData,
                                    SERVICE_SEND_TIMEOUT,
                                    SERVICE_RECV_TIMEOUT,
                                    kCFRunLoopDefaultMode,
                                    &returnData);
        CFRelease(remotePort);
        CFRelease(argumentsData);

        if (status != kCFMessagePortSuccess)
            return NULL;

        CFPropertyListRef propertyList =
            CFPropertyListCreateWithData(kCFAllocatorDefault, returnData, kCFPropertyListImmutable, NULL, NULL);
        CFRelease(returnData);

        if (!propertyList) return NULL;

        if (CFGetTypeID(propertyList) != CFArrayGetTypeID()) {
            CFRelease(propertyList);
            return NULL;
        }

        return (CFArrayRef) propertyList;
    }
    else
    {
        return AltGetSpringBoardServicesApi()->SBSCopyApplicationDisplayIdentifiers(active, debuggable);
    }
}

CFStringRef SBSCopyDisplayIdentifierForProcessID(UInt32 pid)
{
    if (pid <= 1) return NULL;
    if (@available(iOS 15.0, *))
    {
        CFMessagePortRef remotePort = AltCreateSpringBoardServicesRemotePort();
        if (!remotePort) return NULL;

        CFArrayRef arguments = (__bridge CFArrayRef)@[@(pid)];
        CFDataRef argumentsData = 
            CFPropertyListCreateData(kCFAllocatorDefault, arguments, kCFPropertyListBinaryFormat_v1_0, 0, NULL);

        CFDataRef returnData = NULL;
        SInt32 status =
            CFMessagePortSendRequest(remotePort,
                                    SBSCopyDisplayIdentifierForProcessIDMsgID,
                                    argumentsData,
                                    SERVICE_SEND_TIMEOUT,
                                    SERVICE_RECV_TIMEOUT,
                                    kCFRunLoopDefaultMode,
                                    &returnData);
        CFRelease(remotePort);
        CFRelease(argumentsData);

        if (status != kCFMessagePortSuccess)
            return NULL;

        CFPropertyListRef propertyList =
            CFPropertyListCreateWithData(kCFAllocatorDefault, returnData, kCFPropertyListImmutable, NULL, NULL);
        CFRelease(returnData);

        if (!propertyList) return NULL;

        if (CFGetTypeID(propertyList) != CFStringGetTypeID()) {
            CFRelease(propertyList);
            return NULL;
        }

        return (CFStringRef) propertyList;
    }
    else
    {
        return AltGetSpringBoardServicesApi()->SBSCopyDisplayIdentifierForProcessID(pid);
    }
}

CFStringRef SBSCopyLocalizedApplicationNameForDisplayIdentifier(CFStringRef identifier)
{
    if (!identifier) return NULL;
    if (@available(iOS 15.0, *))
    {
        CFMessagePortRef remotePort = AltCreateSpringBoardServicesRemotePort();
        if (!remotePort) return NULL;

        CFArrayRef arguments = (__bridge CFArrayRef)@[(__bridge NSString *)identifier];
        CFDataRef argumentsData = 
            CFPropertyListCreateData(kCFAllocatorDefault, arguments, kCFPropertyListBinaryFormat_v1_0, 0, NULL);

        CFDataRef returnData = NULL;
        SInt32 status =
            CFMessagePortSendRequest(remotePort,
                                    SBSCopyLocalizedApplicationNameForDisplayIdentifierMsgID,
                                    argumentsData,
                                    SERVICE_SEND_TIMEOUT,
                                    SERVICE_RECV_TIMEOUT,
                                    kCFRunLoopDefaultMode,
                                    &returnData);
        CFRelease(remotePort);
        CFRelease(argumentsData);

        if (status != kCFMessagePortSuccess)
            return NULL;

        CFPropertyListRef propertyList =
            CFPropertyListCreateWithData(kCFAllocatorDefault, returnData, kCFPropertyListImmutable, NULL, NULL);
        CFRelease(returnData);

        if (!propertyList) return NULL;

        if (CFGetTypeID(propertyList) != CFStringGetTypeID()) {
            CFRelease(propertyList);
            return NULL;
        }

        return (CFStringRef) propertyList;
    }
    else
    {
        return AltGetSpringBoardServicesApi()->SBSCopyLocalizedApplicationNameForDisplayIdentifier(identifier);
    }
}

CFDataRef SBSCopyIconImagePNGDataForDisplayIdentifier(CFStringRef identifier)
{
    if (!identifier) return NULL;
    if (@available(iOS 15.0, *))
    {
        CFMessagePortRef remotePort = AltCreateSpringBoardServicesRemotePort();
        if (!remotePort) return NULL;

        CFArrayRef arguments = (__bridge CFArrayRef)@[(__bridge NSString *)identifier];
        CFDataRef argumentsData = 
            CFPropertyListCreateData(kCFAllocatorDefault, arguments, kCFPropertyListBinaryFormat_v1_0, 0, NULL);

        CFDataRef returnData = NULL;
        SInt32 status =
            CFMessagePortSendRequest(remotePort,
                                    SBSCopyIconImagePNGDataForDisplayIdentifierMsgID,
                                    argumentsData,
                                    SERVICE_SEND_TIMEOUT,
                                    SERVICE_RECV_TIMEOUT,
                                    kCFRunLoopDefaultMode,
                                    &returnData);
        CFRelease(remotePort);
        CFRelease(argumentsData);

        if (status != kCFMessagePortSuccess)
            return NULL;

        CFPropertyListRef propertyList =
            CFPropertyListCreateWithData(kCFAllocatorDefault, returnData, kCFPropertyListImmutable, NULL, NULL);
        CFRelease(returnData);

        if (!propertyList) return NULL;

        if (CFGetTypeID(propertyList) != CFDataGetTypeID()) {
            CFRelease(propertyList);
            return NULL;
        }

        return (CFDataRef) propertyList;
    }
    else
    {
        return AltGetSpringBoardServicesApi()->SBSCopyIconImagePNGDataForDisplayIdentifier(identifier);
    }
}

CFDictionaryRef SBSCopyInfoForApplicationWithProcessID(UInt32 pid)
{
    if (pid <= 1) return NULL;
    if (@available(iOS 15.0, *))
    {
        CFMessagePortRef remotePort = AltCreateSpringBoardServicesRemotePort();
        if (!remotePort) return NULL;

        CFArrayRef arguments = (__bridge CFArrayRef)@[@(pid)];
        CFDataRef argumentsData = 
            CFPropertyListCreateData(kCFAllocatorDefault, arguments, kCFPropertyListBinaryFormat_v1_0, 0, NULL);

        CFDataRef returnData = NULL;
        SInt32 status =
            CFMessagePortSendRequest(remotePort,
                                    SBSCopyInfoForApplicationWithProcessIDMsgID,
                                    argumentsData,
                                    SERVICE_SEND_TIMEOUT,
                                    SERVICE_RECV_TIMEOUT,
                                    kCFRunLoopDefaultMode,
                                    &returnData);
        CFRelease(remotePort);
        CFRelease(argumentsData);

        if (status != kCFMessagePortSuccess)
            return NULL;

        CFPropertyListRef propertyList =
            CFPropertyListCreateWithData(kCFAllocatorDefault, returnData, kCFPropertyListImmutable, NULL, NULL);
        CFRelease(returnData);

        if (!propertyList) return NULL;

        if (CFGetTypeID(propertyList) != CFDictionaryGetTypeID()) {
            CFRelease(propertyList);
            return NULL;
        }

        return (CFDictionaryRef) propertyList;
    }
    else
    {
        return AltGetSpringBoardServicesApi()->SBSCopyInfoForApplicationWithProcessID(pid);
    }
}

UInt32 SBSLaunchApplicationWithIdentifier(CFStringRef identifier)
{
    if (!identifier) return 0;
    if (@available(iOS 15.0, *))
    {
        CFMessagePortRef remotePort = AltCreateSpringBoardServicesRemotePort();
        if (!remotePort) return 0;

        CFArrayRef arguments = (__bridge CFArrayRef)@[(__bridge NSString *)identifier];
        CFDataRef argumentsData = 
            CFPropertyListCreateData(kCFAllocatorDefault, arguments, kCFPropertyListBinaryFormat_v1_0, 0, NULL);

        CFDataRef returnData = NULL;
        SInt32 status =
            CFMessagePortSendRequest(remotePort,
                                    SBSLaunchApplicationWithIdentifierMsgID,
                                    argumentsData,
                                    SERVICE_SEND_TIMEOUT,
                                    SERVICE_RECV_TIMEOUT,
                                    kCFRunLoopDefaultMode,
                                    &returnData);
        CFRelease(remotePort);
        CFRelease(argumentsData);

        if (status != kCFMessagePortSuccess)
            return 0;

        CFPropertyListRef propertyList =
            CFPropertyListCreateWithData(kCFAllocatorDefault, returnData, kCFPropertyListImmutable, NULL, NULL);
        CFRelease(returnData);

        if (!propertyList) return 0;

        if (CFGetTypeID(propertyList) != CFNumberGetTypeID()) {
            CFRelease(propertyList);
            return 0;
        }

        UInt32 pid = 0;
        CFNumberGetValue((CFNumberRef) propertyList, kCFNumberSInt32Type, &pid);
        CFRelease(propertyList);

        return pid;
    }
    else
    {
        return AltGetSpringBoardServicesApi()->SBSLaunchApplicationWithIdentifier(identifier);
    }
}

UInt32 SBSLaunchApplicationWithIdentifierAndLaunchOptions(CFStringRef identifier, CFDictionaryRef options, BOOL suspended)
{
    if (!identifier) return 0;
    if (@available(iOS 15.0, *))
    {
        CFMessagePortRef remotePort = AltCreateSpringBoardServicesRemotePort();
        if (!remotePort) return 0;

        CFArrayRef arguments = (__bridge CFArrayRef)@[(__bridge NSString *)identifier, (__bridge NSDictionary *)options, @(suspended)];
        CFDataRef argumentsData = 
            CFPropertyListCreateData(kCFAllocatorDefault, arguments, kCFPropertyListBinaryFormat_v1_0, 0, NULL);

        CFDataRef returnData = NULL;
        SInt32 status =
            CFMessagePortSendRequest(remotePort,
                                    SBSLaunchApplicationWithIdentifierAndLaunchOptionsMsgID,
                                    argumentsData,
                                    SERVICE_SEND_TIMEOUT,
                                    SERVICE_RECV_TIMEOUT,
                                    kCFRunLoopDefaultMode,
                                    &returnData);
        CFRelease(remotePort);
        CFRelease(argumentsData);

        if (status != kCFMessagePortSuccess)
            return 0;

        CFPropertyListRef propertyList =
            CFPropertyListCreateWithData(kCFAllocatorDefault, returnData, kCFPropertyListImmutable, NULL, NULL);
        CFRelease(returnData);

        if (!propertyList) return 0;

        if (CFGetTypeID(propertyList) != CFNumberGetTypeID()) {
            CFRelease(propertyList);
            return 0;
        }

        UInt32 pid = 0;
        CFNumberGetValue((CFNumberRef) propertyList, kCFNumberSInt32Type, &pid);
        CFRelease(propertyList);

        return pid;
    }
    else
    {
        return AltGetSpringBoardServicesApi()->SBSLaunchApplicationWithIdentifierAndLaunchOptions(identifier, options, suspended);
    }
}

UInt32 SBSLaunchApplicationWithIdentifierAndURLAndLaunchOptions(CFStringRef identifier, CFURLRef url, CFDictionaryRef params, CFDictionaryRef options, BOOL suspended)
{
    if (!identifier) return 0;
    if (@available(iOS 15.0, *))
    {
        CFMessagePortRef remotePort = AltCreateSpringBoardServicesRemotePort();
        if (!remotePort) return 0;

        CFArrayRef arguments = (__bridge CFArrayRef)@[(__bridge NSString *)identifier, (__bridge NSURL *)url, (__bridge NSDictionary *)params, (__bridge NSDictionary *)options, @(suspended)];
        CFDataRef argumentsData = 
            CFPropertyListCreateData(kCFAllocatorDefault, arguments, kCFPropertyListBinaryFormat_v1_0, 0, NULL);

        CFDataRef returnData = NULL;
        SInt32 status =
            CFMessagePortSendRequest(remotePort,
                                    SBSLaunchApplicationWithIdentifierAndURLAndLaunchOptionsMsgID,
                                    argumentsData,
                                    SERVICE_SEND_TIMEOUT,
                                    SERVICE_RECV_TIMEOUT,
                                    kCFRunLoopDefaultMode,
                                    &returnData);
        CFRelease(remotePort);
        CFRelease(argumentsData);

        if (status != kCFMessagePortSuccess)
            return 0;

        CFPropertyListRef propertyList =
            CFPropertyListCreateWithData(kCFAllocatorDefault, returnData, kCFPropertyListImmutable, NULL, NULL);
        CFRelease(returnData);

        if (!propertyList) return 0;

        if (CFGetTypeID(propertyList) != CFNumberGetTypeID()) {
            CFRelease(propertyList);
            return 0;
        }

        UInt32 pid = 0;
        CFNumberGetValue((CFNumberRef) propertyList, kCFNumberSInt32Type, &pid);
        CFRelease(propertyList);

        return pid;
    }
    else
    {
        return AltGetSpringBoardServicesApi()->SBSLaunchApplicationWithIdentifierAndURLAndLaunchOptions(identifier, url, params, options, suspended);
    }
}

CFStringRef SBSApplicationLaunchingErrorString(UInt32 error)
{
    if (@available(iOS 15.0, *))
    {
        CFMessagePortRef remotePort = AltCreateSpringBoardServicesRemotePort();
        if (!remotePort) return NULL;

        CFArrayRef arguments = (__bridge CFArrayRef)@[@(error)];
        CFDataRef argumentsData = 
            CFPropertyListCreateData(kCFAllocatorDefault, arguments, kCFPropertyListBinaryFormat_v1_0, 0, NULL);

        CFDataRef returnData = NULL;
        SInt32 status =
            CFMessagePortSendRequest(remotePort,
                                    SBSApplicationLaunchingErrorStringMsgID,
                                    argumentsData,
                                    SERVICE_SEND_TIMEOUT,
                                    SERVICE_RECV_TIMEOUT,
                                    kCFRunLoopDefaultMode,
                                    &returnData);
        CFRelease(remotePort);
        CFRelease(argumentsData);

        if (status != kCFMessagePortSuccess)
            return NULL;

        CFPropertyListRef propertyList =
            CFPropertyListCreateWithData(kCFAllocatorDefault, returnData, kCFPropertyListImmutable, NULL, NULL);
        CFRelease(returnData);

        if (!propertyList) return NULL;

        if (CFGetTypeID(propertyList) != CFStringGetTypeID()) {
            CFRelease(propertyList);
            return NULL;
        }

        return (CFStringRef) propertyList;
    }
    else
    {
        return AltGetSpringBoardServicesApi()->SBSApplicationLaunchingErrorString(error);
    }
}


#pragma mark - Constructor

#import <libSandy.h>

static const char *MyExecutablePath(void)
{
    static char *executablePath = NULL;
    if (!executablePath)
    {
        uint32_t executablePathSize = 0;
        _NSGetExecutablePath(NULL, &executablePathSize);
        executablePath = (char *)calloc(1, executablePathSize);
        if (0 == _NSGetExecutablePath(executablePath, &executablePathSize))
        {
            /* Resolve Symbolic Links */
            char realExecutablePath[PATH_MAX] = {0};
            if (realpath(executablePath, realExecutablePath) != NULL)
            {
                free(executablePath);
                executablePath = strdup(realExecutablePath);
            }
            
            /* Supports Procursus */
            if (strncmp("/private/preboot" "/", executablePath, sizeof("/private/preboot")) == 0)
            {
                const char *littlePtr = strstr(executablePath, "/procursus" "/");
                if (littlePtr != NULL)
                {
                    char *suffixPtr = strdup(littlePtr + sizeof("/procursus") - 1);
                    free(executablePath);
                    char *markPtr = (char *)calloc(1, strlen(suffixPtr) + sizeof(JB_PREFIX));
                    markPtr = strcat(strcat(markPtr, JB_PREFIX), suffixPtr);
                    free(suffixPtr);
                    executablePath = markPtr;
                }
            }
        }
    }
    
    return executablePath;
}

static __attribute__((constructor)) void CHConstructor_AltSpringBoardServices(void)
{
    const char *processName = MyExecutablePath();
    if (strncmp("/usr/sbin/", processName, sizeof("/usr/sbin/") - 1) != 0 &&
        strncmp("/usr/libexec/", processName, sizeof("/usr/libexec/") - 1) != 0 &&
        strncmp("/System/Library/Frameworks/", processName, sizeof("/System/Library/Frameworks/") - 1) != 0 &&
        strncmp("/System/Library/PrivateFrameworks/", processName, sizeof("/System/Library/PrivateFrameworks/") - 1) != 0 &&
        strncmp("/System/Library/CoreServices/", processName, sizeof("/System/Library/CoreServices/") - 1) != 0 &&
        strncmp("/Applications/", processName, sizeof("/Applications/") - 1) != 0)
        return;
    
    @autoreleasepool
    {
        NSString *executableName = [[NSProcessInfo processInfo] processName];
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

        if ([executableName isEqualToString:@"MobileGestaltHelper"])
        {   /* Server Process - MobileGestaltHelper (alternative to SpringBoardServices) */
            
            void *sandyHandle = dlopen(JB_PREFIX "/usr/lib/libsandy.dylib", RTLD_LAZY);
            if (sandyHandle)
            {
                int (*__dyn_libSandy_applyProfile)(const char *profileName) = (int (*)(const char *))dlsym(sandyHandle, "libSandy_applyProfile");
                if (__dyn_libSandy_applyProfile)
                {
                    int sandyStatus = __dyn_libSandy_applyProfile(SBS_SERVICE_NAME);
                    if (sandyStatus == kLibSandyErrorXPCFailure)
                        os_log_error(OS_LOG_DEFAULT, "[" SBS_SERVICE_NAME "] Failed to apply sandbox profile: %{public}d", sandyStatus);
                    else
                        os_log_info(OS_LOG_DEFAULT, "[" SBS_SERVICE_NAME "] Successfully applied sandbox profile");
                }
            }
            
            AltGetSpringBoardServicesApi();
            
            static CFMessagePortRef _localPort = NULL;
            _localPort = CFMessagePortCreateLocal(nil, CFSTR(SBS_SERVICE_NAME), AltSpringBoardServicesCallback, NULL, NULL);
            if (_localPort)
            {
                CFRunLoopSourceRef runLoopSource = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _localPort, 0);
                if (runLoopSource)
                {
                    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
                    CFRelease(runLoopSource);
                    rocketbootstrap_cfmessageportexposelocal(_localPort);
                }

                os_log_info(OS_LOG_DEFAULT, "server %{public}@ initialized %{public}@ %{public}s, pid = %{public}d",
                            _localPort, bundleIdentifier ?: executableName, processName, getpid());
            }
        }
        else if ([bundleIdentifier isEqualToString:@"com.apple.springboard"])
        {   /*  Server Process - SpringBoard
             *  
             *  We made SpringBoard as another server process because some APIs of 
             *  SpringBoardServices are deprecated. So we will get these results directly
             *  from the final data source - SpringBoard.
             */
            
            static CFMessagePortRef _localPort = NULL;
            _localPort = CFMessagePortCreateLocal(kCFAllocatorDefault, CFSTR(SB_SERVICE_NAME), AltSpringBoardCallback, NULL, NULL);
            if (_localPort)
            {
                CFRunLoopSourceRef runLoopSource = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _localPort, 0);
                if (runLoopSource)
                {
                    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
                    CFRelease(runLoopSource);
                    rocketbootstrap_cfmessageportexposelocal(_localPort);
                }

                os_log_info(OS_LOG_DEFAULT, "server %{public}@ initialized %{public}@ %{public}s, pid = %{public}d",
                        _localPort, bundleIdentifier ?: executableName, processName, getpid());
            }
        }
        else
        {   /*  Client Process - any other process
             *  
             *  On iOS 15 and above, we are unable to access SpringBoardServices directly 
             *  due to the lacking of credentials. Also, the SpringBoard process is unable
             *  to access SpringBoardServices because itself works as the data source of that.
             *  Here is a workaround to access SpringBoardServices via a middleman process.
             */
            
            if (@available(iOS 15.0, *)) {}
            else AltGetSpringBoardServicesApi();
        }
    }
}
