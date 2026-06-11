#import <Flutter/Flutter.h>
#import <GoogleMaps/GoogleMaps.h>
#import <objc/runtime.h>

static NSObject<FlutterBinaryMessenger> *MaypolePoiBridgeMessenger(id controller) {
  @try {
    NSObject<FlutterPluginRegistrar> *registrar = [controller valueForKey:@"registrar"];
    if ([registrar respondsToSelector:@selector(messenger)]) {
      return registrar.messenger;
    }
  } @catch (NSException *exception) {
    return nil;
  }

  return nil;
}

static NSString *MaypolePoiBridgeMapId(id controller) {
  @try {
    id callHandler = [controller valueForKey:@"callHandler"];
    id pigeonSuffix = [callHandler valueForKey:@"pigeonSuffix"];
    if ([pigeonSuffix isKindOfClass:NSString.class]) {
      return pigeonSuffix;
    }
  } @catch (NSException *exception) {
    return nil;
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

  if (messenger == nil || mapId.length == 0 || placeID.length == 0 || name.length == 0) {
    return;
  }

  FlutterMethodChannel *channel = [FlutterMethodChannel
      methodChannelWithName:[NSString stringWithFormat:@"app.maypole/google_maps_poi_%@", mapId]
            binaryMessenger:messenger];

  NSDictionary<NSString *, id> *arguments = @{
    @"placeId" : placeID,
    @"name" : name,
    @"location" : @{
      @"latitude" : @(location.latitude),
      @"longitude" : @(location.longitude),
    },
  };

  [channel invokeMethod:@"poi#onTap" arguments:arguments];
}

__attribute__((constructor)) static void MaypoleInstallGoogleMapPoiBridge(void) {
  Class controllerClass = NSClassFromString(@"FLTGoogleMapController");
  if (controllerClass == Nil) {
    return;
  }

  SEL poiTapSelector = @selector(mapView:didTapPOIWithPlaceID:name:location:);
  class_addMethod(controllerClass,
                  poiTapSelector,
                  (IMP)MaypolePoiBridgeDidTapPOI,
                  "v@:@@@{CLLocationCoordinate2D=dd}");
}
