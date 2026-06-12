#import <Flutter/Flutter.h>
#import <GoogleMaps/GoogleMaps.h>
#import <objc/runtime.h>

// Safely reads a KVC value, returning nil instead of throwing when the key is
// not present on the receiver (different plugin versions expose different ivars).
static id MaypoleSafeValueForKey(id object, NSString *key) {
  if (object == nil) {
    return nil;
  }
  @try {
    return [object valueForKey:key];
  } @catch (NSException *exception) {
    return nil;
  }
}

static NSObject<FlutterBinaryMessenger> *MaypolePoiBridgeMessenger(id controller) {
  // google_maps_flutter_ios 2.17+ (FGMGoogleMapController) stores the messenger on
  // its Pigeon callback handler.
  id dartCallbackHandler = MaypoleSafeValueForKey(controller, @"dartCallbackHandler");
  id binaryMessenger = MaypoleSafeValueForKey(dartCallbackHandler, @"binaryMessenger");
  if ([binaryMessenger conformsToProtocol:@protocol(FlutterBinaryMessenger)]) {
    return binaryMessenger;
  }

  // Older plugin versions (FLTGoogleMapController) exposed a registrar instead.
  id registrar = MaypoleSafeValueForKey(controller, @"registrar");
  if ([registrar respondsToSelector:@selector(messenger)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id messenger = [registrar performSelector:@selector(messenger)];
#pragma clang diagnostic pop
    if ([messenger conformsToProtocol:@protocol(FlutterBinaryMessenger)]) {
      return messenger;
    }
  }

  return nil;
}

// The Dart side keys its channel on the numeric platform view id (e.g. "0").
// Pigeon stores its message channel suffix with a leading dot (e.g. ".0"), so we
// normalize by stripping a leading "." to match the Dart `GoogleMapController.mapId`.
static NSString *MaypoleNormalizeMapId(id value) {
  if (![value isKindOfClass:NSString.class] || [value length] == 0) {
    return nil;
  }
  NSString *suffix = (NSString *)value;
  if ([suffix hasPrefix:@"."]) {
    suffix = [suffix substringFromIndex:1];
  }
  return suffix.length > 0 ? suffix : nil;
}

static NSString *MaypolePoiBridgeMapId(id controller) {
  // Preferred: the raw pigeon suffix from the call/inspector handlers ("0").
  for (NSString *handlerKey in @[ @"callHandler", @"inspector" ]) {
    id handler = MaypoleSafeValueForKey(controller, handlerKey);
    NSString *mapId = MaypoleNormalizeMapId(MaypoleSafeValueForKey(handler, @"pigeonSuffix"));
    if (mapId != nil) {
      return mapId;
    }
  }

  // Fallback: the Pigeon callback handler's (dotted) message channel suffix.
  id dartCallbackHandler = MaypoleSafeValueForKey(controller, @"dartCallbackHandler");
  NSString *mapId =
      MaypoleNormalizeMapId(MaypoleSafeValueForKey(dartCallbackHandler, @"messageChannelSuffix"));
  if (mapId != nil) {
    return mapId;
  }

  return nil;
}

static void MaypolePoiBridgeDidTapPOI(id self,
                                      SEL _cmd,
                                      GMSMapView *mapView,
                                      NSString *placeID,
                                      NSString *name,
                                      CLLocationCoordinate2D location) {
  NSObject<FlutterBinaryMessenger> *messenger = MaypolePoiBridgeMessenger(self);
  NSString *mapId = MaypolePoiBridgeMapId(self);

  if (messenger == nil || mapId.length == 0 || placeID.length == 0) {
    NSLog(@"MaypoleGoogleMapPoiBridge: dropping POI tap (messenger=%@ mapId=%@ placeID=%@)",
          messenger != nil ? @"ok" : @"nil", mapId, placeID);
    return;
  }

  FlutterMethodChannel *channel = [FlutterMethodChannel
      methodChannelWithName:[NSString stringWithFormat:@"app.maypole/google_maps_poi_%@", mapId]
            binaryMessenger:messenger];

  NSDictionary<NSString *, id> *arguments = @{
    @"placeId" : placeID,
    @"name" : name ?: @"",
    @"location" : @{
      @"latitude" : @(location.latitude),
      @"longitude" : @(location.longitude),
    },
  };

  [channel invokeMethod:@"poi#onTap"
              arguments:arguments
                 result:^(id _Nullable result) {
                   if (result == FlutterMethodNotImplemented) {
                     NSLog(@"MaypoleGoogleMapPoiBridge: no Dart handler for poi#onTap on "
                           @"app.maypole/google_maps_poi_%@",
                           mapId);
                   } else if ([result isKindOfClass:[FlutterError class]]) {
                     FlutterError *error = (FlutterError *)result;
                     NSLog(@"MaypoleGoogleMapPoiBridge: Dart handler error: %@ / %@", error.code,
                           error.message);
                   }
                 }];
}

// Ensures the Google Maps Flutter controller class responds to the GMS POI tap
// delegate selector. Adding the method is idempotent across multiple map instances.
static void MaypoleEnsurePoiHandlerOnDelegate(id delegate) {
  if (delegate == nil) {
    return;
  }

  // Only hook the Google Maps Flutter controller, never arbitrary delegates.
  // Identify it either by class name or by the coordinate-tap delegate method the
  // controller already implements, so we are resilient to plugin renames.
  NSString *className = NSStringFromClass([delegate class]);
  BOOL isFlutterMapController =
      [className isEqualToString:@"FLTGoogleMapController"] ||
      ([className containsString:@"GoogleMap"] &&
       [delegate respondsToSelector:@selector(mapView:didTapAtCoordinate:)]);
  if (!isFlutterMapController) {
    return;
  }

  Class delegateClass = [delegate class];
  SEL poiTapSelector = @selector(mapView:didTapPOIWithPlaceID:name:location:);
  if ([delegateClass instancesRespondToSelector:poiTapSelector]) {
    return;
  }

  BOOL installed = class_addMethod(delegateClass,
                                   poiTapSelector,
                                   (IMP)MaypolePoiBridgeDidTapPOI,
                                   "v@:@@@{CLLocationCoordinate2D=dd}");
  NSLog(@"MaypoleGoogleMapPoiBridge: install POI handler on %@ %@",
        NSStringFromClass(delegateClass),
        installed ? @"succeeded" : @"failed");
}

// Original implementation of -[GMSMapView setDelegate:], captured during swizzling.
static void (*MaypoleOriginalSetMapDelegate)(id, SEL, id) = NULL;

static void MaypoleSwizzledSetMapDelegate(id self, SEL _cmd, id delegate) {
  // Install the POI handler before the delegate is assigned, so Google Maps sees
  // the controller respond to the POI selector even if it caches -respondsToSelector:.
  MaypoleEnsurePoiHandlerOnDelegate(delegate);
  if (MaypoleOriginalSetMapDelegate != NULL) {
    MaypoleOriginalSetMapDelegate(self, _cmd, delegate);
  }
}

void MaypoleInstallGoogleMapPoiBridge(void) {
  // FLTGoogleMapController is loaded lazily (only when the first map is created),
  // so we cannot patch it at app launch. Instead we swizzle GMSMapView's delegate
  // setter, which runs whenever the controller attaches itself to a map view.
  Class mapViewClass = NSClassFromString(@"GMSMapView");
  if (mapViewClass == Nil) {
    NSLog(@"MaypoleGoogleMapPoiBridge: GMSMapView class is not loaded");
    return;
  }

  SEL setDelegateSelector = @selector(setDelegate:);
  Method setDelegateMethod = class_getInstanceMethod(mapViewClass, setDelegateSelector);
  if (setDelegateMethod == NULL) {
    NSLog(@"MaypoleGoogleMapPoiBridge: GMSMapView has no setDelegate: method");
    return;
  }

  if (MaypoleOriginalSetMapDelegate != NULL) {
    NSLog(@"MaypoleGoogleMapPoiBridge: GMSMapView setDelegate: already swizzled");
    return;
  }

  MaypoleOriginalSetMapDelegate =
      (void (*)(id, SEL, id))method_getImplementation(setDelegateMethod);
  method_setImplementation(setDelegateMethod, (IMP)MaypoleSwizzledSetMapDelegate);
  NSLog(@"MaypoleGoogleMapPoiBridge: swizzled GMSMapView setDelegate:");
}
