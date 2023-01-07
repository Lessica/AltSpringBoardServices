#ifndef __ALT_DARWIN_SPRINGBOARD_H__
#define __ALT_DARWIN_SPRINGBOARD_H__

#import <Foundation/Foundation.h>

typedef struct _AltSpringboardApi AltSpringboardApi;
typedef void (^ FBSOpenResultCallback) (NSError * error);

typedef enum _FBProcessKillReason
{
  FBProcessKillReasonUnknown,
  FBProcessKillReasonUser,
  FBProcessKillReasonPurge,
  FBProcessKillReasonGracefulPurge,
  FBProcessKillReasonThermal,
  FBProcessKillReasonNone,
  FBProcessKillReasonShutdown,
  FBProcessKillReasonLaunchTest,
  FBProcessKillReasonInsecureDrawing
} FBProcessKillReason;

@interface FBSSystemService : NSObject

+ (FBSSystemService *)sharedService;

- (pid_t)pidForApplication:(NSString *)identifier;
- (void)openApplication:(NSString *)identifier
                options:(NSDictionary *)options
             clientPort:(mach_port_t)port
             withResult:(FBSOpenResultCallback)result;
- (void)openURL:(NSURL *)url
    application:(NSString *)identifier
        options:(NSDictionary *)options
     clientPort:(mach_port_t)port
     withResult:(FBSOpenResultCallback)result;
- (void)terminateApplication:(NSString *)identifier
                   forReason:(FBProcessKillReason)reason
                   andReport:(BOOL)report
             withDescription:(NSString *)description;

- (mach_port_t)createClientPort;
- (void)cleanupClientPort:(mach_port_t)port;

@end

@interface LSApplicationProxy : NSObject

+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)identifier;

- (NSString *)shortVersionString;
- (NSString *)bundleVersion;
- (NSURL *)bundleURL;
- (NSURL *)dataContainerURL;
- (NSDictionary <NSString *, NSURL *> *)groupContainerURLs;
- (id)entitlementValueForKey:(NSString *)key ofClass:(Class)klass;

@end

struct _AltSpringboardApi
{
  void * sbs;
  void * fbs;
  void * mcs;

  CFStringRef (* SBSCopyFrontmostApplicationDisplayIdentifier) (void);
  CFArrayRef (* SBSCopyApplicationDisplayIdentifiers) (BOOL active, BOOL debuggable);
  CFStringRef (* SBSCopyDisplayIdentifierForProcessID) (UInt32 pid);
  CFStringRef (* SBSCopyLocalizedApplicationNameForDisplayIdentifier) (CFStringRef identifier);
  CFDataRef (* SBSCopyIconImagePNGDataForDisplayIdentifier) (CFStringRef identifier);
  CFDictionaryRef (* SBSCopyInfoForApplicationWithProcessID) (UInt32 pid);
  UInt32 (* SBSProcessIDForDisplayIdentifier) (CFStringRef identifier);
  UInt32 (* SBSLaunchApplicationWithIdentifier) (CFStringRef identifier);
  UInt32 (* SBSLaunchApplicationWithIdentifierAndLaunchOptions) (CFStringRef identifier, CFDictionaryRef options, BOOL suspended);
  UInt32 (* SBSLaunchApplicationWithIdentifierAndURLAndLaunchOptions) (CFStringRef identifier, CFURLRef url, CFDictionaryRef params, CFDictionaryRef options, BOOL suspended);
  CFStringRef (* SBSApplicationLaunchingErrorString) (UInt32 error);

  CFStringRef SBSApplicationLaunchOptionUnlockDeviceKey;

  CFStringRef FBSOpenApplicationOptionKeyUnlockDevice;
  CFStringRef FBSOpenApplicationOptionKeyDebuggingOptions;

  CFStringRef FBSDebugOptionKeyArguments;
  CFStringRef FBSDebugOptionKeyEnvironment;
  CFStringRef FBSDebugOptionKeyStandardOutPath;
  CFStringRef FBSDebugOptionKeyStandardErrorPath;
  CFStringRef FBSDebugOptionKeyDisableASLR;

  id FBSSystemService;
  id LSApplicationProxy;
};

OBJC_EXTERN AltSpringboardApi * _alt_get_springboard_api (void);

#endif
