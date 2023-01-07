#if __has_feature(objc_arc)
#error This file must not be compiled with ARC. Use -fno-objc-arc flag.
#endif

#import "springboard.h"
#import <dlfcn.h>


#define CHStringify_(x) #x
#define CHStringify(x) CHStringify_(x)

#define ALT_ASSIGN_SBS_FUNC(N) \
    api->N = dlsym (api->sbs, CHStringify (N)); \
    assert (api->N != NULL)
#define ALT_ASSIGN_SBS_CONSTANT(N) \
    str = dlsym (api->sbs, CHStringify (N)); \
    assert (str != NULL); \
    api->N = *str
#define ALT_ASSIGN_FBS_CONSTANT(N) \
    str = dlsym (api->fbs, CHStringify (N)); \
    assert (str != NULL); \
    api->N = *str

static AltSpringboardApi * alt_springboard_api = NULL;

AltSpringboardApi *
_alt_get_springboard_api (void)
{
  if (alt_springboard_api == NULL)
  {
    AltSpringboardApi * api = NULL;
    CFStringRef *str = nil;
    id (* objc_get_class_impl) (const char * name);

    api = (AltSpringboardApi *)calloc(1, sizeof(AltSpringboardApi));

    api->sbs = dlopen ("/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices", RTLD_GLOBAL | RTLD_LAZY);
    assert (api->sbs != NULL);

    api->fbs = dlopen ("/System/Library/PrivateFrameworks/FrontBoardServices.framework/FrontBoardServices", RTLD_GLOBAL | RTLD_LAZY);

    ALT_ASSIGN_SBS_FUNC (SBSCopyFrontmostApplicationDisplayIdentifier);
    ALT_ASSIGN_SBS_FUNC (SBSCopyApplicationDisplayIdentifiers);
    ALT_ASSIGN_SBS_FUNC (SBSCopyDisplayIdentifierForProcessID);
    ALT_ASSIGN_SBS_FUNC (SBSCopyLocalizedApplicationNameForDisplayIdentifier);
    ALT_ASSIGN_SBS_FUNC (SBSCopyIconImagePNGDataForDisplayIdentifier);
    ALT_ASSIGN_SBS_FUNC (SBSCopyInfoForApplicationWithProcessID);
    ALT_ASSIGN_SBS_FUNC (SBSProcessIDForDisplayIdentifier);
    ALT_ASSIGN_SBS_FUNC (SBSLaunchApplicationWithIdentifier);
    ALT_ASSIGN_SBS_FUNC (SBSLaunchApplicationWithIdentifierAndLaunchOptions);
    ALT_ASSIGN_SBS_FUNC (SBSLaunchApplicationWithIdentifierAndURLAndLaunchOptions);
    ALT_ASSIGN_SBS_FUNC (SBSApplicationLaunchingErrorString);

    ALT_ASSIGN_SBS_CONSTANT (SBSApplicationLaunchOptionUnlockDeviceKey);

    objc_get_class_impl = dlsym (RTLD_DEFAULT, "objc_getClass");
    assert (objc_get_class_impl != NULL);

    if (api->fbs != NULL)
    {
      api->FBSSystemService = objc_get_class_impl ("FBSSystemService");
      assert (api->FBSSystemService != nil);

      ALT_ASSIGN_FBS_CONSTANT (FBSOpenApplicationOptionKeyUnlockDevice);
      ALT_ASSIGN_FBS_CONSTANT (FBSOpenApplicationOptionKeyDebuggingOptions);

      ALT_ASSIGN_FBS_CONSTANT (FBSDebugOptionKeyArguments);
      ALT_ASSIGN_FBS_CONSTANT (FBSDebugOptionKeyEnvironment);
      ALT_ASSIGN_FBS_CONSTANT (FBSDebugOptionKeyStandardOutPath);
      ALT_ASSIGN_FBS_CONSTANT (FBSDebugOptionKeyStandardErrorPath);
      ALT_ASSIGN_FBS_CONSTANT (FBSDebugOptionKeyDisableASLR);
    }

    api->mcs = dlopen ("/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices", RTLD_GLOBAL | RTLD_LAZY);
    assert (api->mcs != NULL);

    api->LSApplicationProxy = objc_get_class_impl ("LSApplicationProxy");
    assert (api->LSApplicationProxy != nil);

    alt_springboard_api = api;
  }

  return alt_springboard_api;
}
