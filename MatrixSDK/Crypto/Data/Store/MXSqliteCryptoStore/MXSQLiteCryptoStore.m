// 
// Copyright 2021 The Matrix.org Foundation C.I.C
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import "MXSQLiteCryptoStore.h"
#import <MatrixSDK/MatrixSDK-Swift.h>
#import "MatrixSDKSwiftHeader.h"
#import <OLMKit/OLMKit.h>

@interface MXSQLiteCryptoStore ()
@property (nonatomic, strong) GRDBCoordinator* grdbCoordinator;
@property (nonatomic, strong) NSString* userId;
@property (nonatomic, strong) NSString* deviceId;
@end

@implementation MXSQLiteCryptoStore

- (instancetype)initWithCredentials:(MXCredentials *)credentials { 
  MXLogDebug(@"[MXSQLiteCryptoStore] initWithCredentials for %@:%@", credentials.userId, credentials.deviceId);
  
  self = [super init];
  if (self) {
    self.userId = credentials.userId;
    self.deviceId = credentials.deviceId;
    
    NSURL* sqliteUrl = [MXSQLiteFileUtils sqliteUrlFor:credentials.userId deviceId:credentials.deviceId];
    
    NSError* error = nil;
    self.grdbCoordinator = [[GRDBCoordinator alloc] initWithUrl:sqliteUrl error:&error];
    
    if (error) {
      MXLogDebug(@"[MXSQLiteCryptoStore] error creating sqlite connection to url: %@, error: %@", sqliteUrl, error);
      return nil;
    }
    
    MXGrdbOlmAccount *account = [self.grdbCoordinator accountIfExistsWithUserId:credentials.userId];
  
    if (!account) {
      return nil;
    }  else  {
      // Make sure the device id corresponds
      if (account.deviceId && ![account.deviceId isEqualToString:credentials.deviceId]) {
        MXLogDebug(@"[MXSQLiteCryptoStore] Credentials do not match");
        [MXSQLiteCryptoStore deleteStoreWithCredentials:credentials];
        self = [MXSQLiteCryptoStore createStoreWithCredentials:credentials];
        self.cryptoVersion = MXCryptoVersionLast;
      }
    }
  }
  
  return self;
}

@synthesize backupVersion;
@synthesize cryptoVersion;
@synthesize globalBlacklistUnverifiedDevices;

+ (BOOL)hasDataForCredentials:(MXCredentials*)credentials {
  NSURL* sqliteUrl = [MXSQLiteFileUtils sqliteUrlFor:credentials.userId deviceId:credentials.deviceId];
  NSError* error = nil;
  GRDBCoordinator* grdb = [[GRDBCoordinator alloc] initWithUrl:sqliteUrl error:&error];
  
  if (error) {
    MXLogDebug(@"[MXSQLiteCryptoStore] error opening sqlite db at %@: %@", sqliteUrl, error);
    return false;
  }
  
  MXGrdbOlmAccount* maybeAccount = [grdb accountIfExistsWithUserId:credentials.userId];
  if (maybeAccount) {
    return true;
  } else {
    return false;
  }
}

+ (instancetype)createStoreWithCredentials:(MXCredentials*)credentials {
  MXLogDebug(@"[MXSQLiteCryptoStore] createStore for %@:%@", credentials.userId, credentials.deviceId);
  
  NSURL* sqliteUrl = [MXSQLiteFileUtils sqliteUrlFor:credentials.userId deviceId:credentials.deviceId];
  NSURL* sqliteFolderUrl = [sqliteUrl URLByDeletingLastPathComponent];

  NSError* error = nil;
  
  [[NSFileManager defaultManager] createDirectoryAtURL:sqliteFolderUrl withIntermediateDirectories:true attributes:@{} error:&error];
  if (error) {
    MXLogDebug(@"[MXSQLiteCryptoStore] error creating store directory at url: %@, error: %@", sqliteFolderUrl, error);
    return nil;
  }

  
  GRDBCoordinator* grdb = [[GRDBCoordinator alloc] initWithUrl:sqliteUrl error:&error];
  if (error) {
    MXLogDebug(@"[MXSQLiteCryptoStore] error creating sqlite store at url: %@, error: %@", sqliteUrl, error);
    return nil;
  }
  
  [grdb createAccountWithUserId:credentials.userId deviceId:credentials.deviceId error:&error];
  if (error) {
    MXLogDebug(@"[MXSQLiteCryptoStore] error creating account for userId %@ at url: %@, error: %@", credentials.userId, sqliteUrl, error);
    return nil;
  }
  
  return [[MXSQLiteCryptoStore alloc] initWithCredentials:credentials];
}

+(void)deleteAllStores {
  [MXSQLiteFileUtils deleteAllStores];
}

- (void)storeDeviceId:(NSString*)deviceId
{
  [self.grdbCoordinator storeDeviceIdObjc:deviceId for:self.userId];
}

- (NSString*)deviceId
{
  return [self.grdbCoordinator retrieveDeviceIdObjcFor:self.userId];
}

/**
 Store the sync token corresponding to the device list.
 
 This is used when starting the client, to get a list of the users who
 have changed their device list since the list time we were running.
 
 @param deviceSyncToken the token.
 */
- (void)storeDeviceSyncToken:(NSString*)deviceSyncToken {
  [self.grdbCoordinator storeDeviceSyncTokenObjc:deviceSyncToken for:self.userId];
}

/**
 Get the sync token corresponding to the device list.
 
 @return the token.
 */
- (NSString*)deviceSyncToken {
  return [self.grdbCoordinator retrieveDeviceSyncTokenObjcFor:self.userId];
}

- (OLMAccount*)account
{
  NSData* data = [self.grdbCoordinator retrieveOlmAccountDataObjcFor:self.userId];
  if (data) {
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
  } else {
    return nil;
  }
}

- (void)setAccount:(OLMAccount*)olmAccount {
  NSDate* startDate = [NSDate date];
  NSData* data = [NSKeyedArchiver archivedDataWithRootObject:olmAccount];
  [self.grdbCoordinator storeOlmAccountDataObjc:data for:self.userId];
  MXLogDebug(@"[MXSQLiteCryptoStore] storeAccount in %.3fms", [[NSDate date] timeIntervalSinceDate:startDate] * 1000);
}

/**
 Perform an action that will advance the olm account state.
 
 Some cryptographic operations update the internal state of the olm account. They must be executed
 into this method to make those operations atomic. This method stores the new olm account state
 when the block retuns,
 The implementation must call the block before returning. It must be multi-thread and multi-process safe.
 
 @param block the block where olm operations can be safely made.
 */
- (void)performAccountOperationWithBlock:(void (^)(OLMAccount *olmAccount))block {
  
  [self.grdbCoordinator performOlmAccountTransactionWithUserId:self.userId block:^(MXGrdbOlmAccount * _Nullable  grdbAccount) {
    
    if (grdbAccount.olmAccountData) {
      OLMAccount *olmAccount = [NSKeyedUnarchiver unarchiveObjectWithData:grdbAccount.olmAccountData];
      block(olmAccount);
      grdbAccount.olmAccountData = [NSKeyedArchiver archivedDataWithRootObject:olmAccount];
    } else {
      MXLogError(@"[MXSQLiteCryptoStore] performAccountOperationWithBlock. Error: Cannot build OLMAccount");
      block(nil);
    }
  }];
}

- (BOOL)globalBlacklistUnverifiedDevices {
  return [self.grdbCoordinator retrieveGlobalBlacklistUnverifiedDevicesFor:self.userId];
}

- (void)setGlobalBlacklistUnverifiedDevices:(BOOL)globalBlacklistUnverifiedDevices {
  [self.grdbCoordinator storeGlobalBlacklistUnverifiedDevices:globalBlacklistUnverifiedDevices for:self.userId];
}

- (void)storeDeviceForUser:(NSString*)userId device:(MXDeviceInfo*)device {
  NSDate* startDate = [NSDate date];
  NSData* deviceData = [NSKeyedArchiver archivedDataWithRootObject:device];
  
  MXGrdbDevice* grdbDevice = [[MXGrdbDevice alloc] initWithId:device.deviceId
                                                       userId:userId
                                                  identityKey:device.identityKey
                                                         data:deviceData];
  
  [self.grdbCoordinator storeDevice:grdbDevice];
  
  MXLogDebug(@"[MXSQLiteCryptoStore] storeDeviceForUser in %.3fms", [[NSDate date] timeIntervalSinceDate:startDate] * 1000);
}

- (MXDeviceInfo*)deviceWithDeviceId:(NSString*)deviceId forUser:(NSString*)userId {
  MXGrdbDevice* grdbDevice = [self.grdbCoordinator retrieveDeviceByDeviceId:deviceId userId:userId];
  if (grdbDevice) {
    return [NSKeyedUnarchiver unarchiveObjectWithData:grdbDevice.data];
  }
  
  return nil;
}

- (MXDeviceInfo*)deviceWithIdentityKey:(NSString*)identityKey {
  MXGrdbDevice* grdbDevice = [self.grdbCoordinator retrieveDeviceByIdentityKey:identityKey];
  if (grdbDevice)  {
    return [NSKeyedUnarchiver unarchiveObjectWithData:grdbDevice.data];
  }
  
  return nil;
}

- (void)storeDevicesForUser:(NSString*)userId devices:(NSDictionary<NSString*, MXDeviceInfo*>*)devices {
  NSDate *startDate = [NSDate date];
  
  
  NSMutableArray<MXGrdbDevice*>* grdbDevices = [NSMutableArray array];
  
  [devices enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, MXDeviceInfo * _Nonnull obj, BOOL * _Nonnull stop) {
    NSData* deviceData = [NSKeyedArchiver archivedDataWithRootObject:obj];
    MXGrdbDevice* grdbDevice = [[MXGrdbDevice alloc] initWithId:obj.deviceId
                                                         userId:userId
                                                    identityKey:obj.identityKey
                                                           data:deviceData];
    [grdbDevices addObject:grdbDevice];
  }];
  
  [self.grdbCoordinator storeDevicesForUserId:userId devices:grdbDevices];
  
  MXLogDebug(@"[MXSQLiteCryptoStore] storeDevicesForUser (count: %tu) in %.3fms", devices.count, [[NSDate date] timeIntervalSinceDate:startDate] * 1000);
}

- (NSDictionary<NSString*, MXDeviceInfo*>*)devicesForUser:(NSString*)userId {
  NSMutableDictionary<NSString*, MXDeviceInfo*>* devicesForUser = [NSMutableDictionary dictionary];
  NSArray<MXGrdbDevice*>* retrieved = [self.grdbCoordinator retrieveAllDevicesByUserId:userId];
  if (retrieved) {
    [retrieved enumerateObjectsUsingBlock:^(MXGrdbDevice * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      
      MXDeviceInfo* deviceInfo = [NSKeyedUnarchiver unarchiveObjectWithData:obj.data];
      devicesForUser[deviceInfo.deviceId] = deviceInfo;
    }];
  }
  return devicesForUser;
}

- (NSDictionary<NSString*, NSNumber*>*)deviceTrackingStatus
{
  NSData* data = [self.grdbCoordinator retrieveDeviceTrackingStatusDataFor:self.userId];
  if (data) {
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
  }
  
  return nil;
}

- (void)storeDeviceTrackingStatus:(NSDictionary<NSString*, NSNumber*>*)statusMap
{
  NSData* data = [NSKeyedArchiver archivedDataWithRootObject:statusMap];
  [self.grdbCoordinator storeDeviceTrackingStatusData:data for:self.userId];
}

- (MXCrossSigningInfo*)crossSigningKeysForUser:(NSString*)userId
{
  MXCrossSigningInfo *crossSigningKeys;
  
  NSData* data = [self.grdbCoordinator retrieveCrossSigningKeysDataForUserId:userId];
  if (data) {
    crossSigningKeys = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  }
  
  return crossSigningKeys;
}

- (void)storeCrossSigningKeys:(MXCrossSigningInfo*)crossSigningInfo
{
  NSData* data = [NSKeyedArchiver archivedDataWithRootObject:crossSigningInfo];
  [self.grdbCoordinator storeCrossSigningKeysWithData:data for:crossSigningInfo.userId];
}

- (NSArray<MXCrossSigningInfo *> *)crossSigningKeys
{
  NSMutableArray<MXCrossSigningInfo*> *crossSigningKeys = [NSMutableArray array];
  NSArray<NSData*>* datas = [self.grdbCoordinator retrieveAllCrossSigningKeysData];
  
  for (NSData* data in datas) {
    [crossSigningKeys addObject:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
  }
  
  return crossSigningKeys;
}

- (NSString*)algorithmForRoom:(NSString*)roomId {
  return [self.grdbCoordinator retrieveRoomAlgorithmFor:roomId];
}

- (BOOL)blacklistUnverifiedDevicesInRoom:(NSString *)roomId {
  return [self.grdbCoordinator retrieveBlacklistUnverifiedDevicesFor:roomId];
}

- (void)storeAlgorithmForRoom:(NSString*)roomId algorithm:(NSString*)algorithm {
  [self.grdbCoordinator storeAlgorithmForRoomId:roomId algorithm:algorithm];
}

- (void)storeBlacklistUnverifiedDevicesInRoom:(NSString *)roomId blacklist:(BOOL)blacklist {
  [self.grdbCoordinator storeBlacklistUnverifiedDevicesForRoomId:roomId blacklist:blacklist];
}

- (void)storeSession:(MXOlmSession*)session forDevice:(NSString*)deviceKey {
  
  NSDate* startDate = [NSDate date];
  
  NSData* olmSessionData = [NSKeyedArchiver archivedDataWithRootObject:session.session];
  
  MXGrdbOlmSession* grdbSession = [[MXGrdbOlmSession alloc] init];
  grdbSession.deviceKey = deviceKey;
  grdbSession.id = session.session.sessionIdentifier;
  grdbSession.olmSessionData = olmSessionData;
  [self.grdbCoordinator storeOlmSession:grdbSession];
  
  MXLogDebug(@"[MXRealmCryptoStore] storeSession in %.3fms", [[NSDate date] timeIntervalSinceDate:startDate] * 1000);
}

- (MXOlmSession*)sessionWithDevice:(NSString*)deviceKey andSessionId:(NSString*)sessionId {
  MXGrdbOlmSession* grdbSession = [self.grdbCoordinator retrieveOlmSessionForSessionId:sessionId deviceKey:deviceKey];
  
  MXOlmSession *mxOlmSession;
  if (grdbSession.olmSessionData) {
    OLMSession *olmSession = [NSKeyedUnarchiver unarchiveObjectWithData:grdbSession.olmSessionData];
    
    mxOlmSession = [[MXOlmSession alloc] initWithOlmSession:olmSession];
    mxOlmSession.lastReceivedMessageTs = grdbSession.lastReceivedMessageTs;
  }
  return mxOlmSession;
}

- (void)performSessionOperationWithDevice:(NSString*)deviceKey andSessionId:(NSString*)sessionId block:(void (^)(MXOlmSession *olmSession))block
{
  
  [self.grdbCoordinator performOlmSessionTransactionForSessionId:sessionId deviceKey:deviceKey block:^(MXGrdbOlmSession * _Nullable grdbSession) {
    if (grdbSession.olmSessionData) {
      OLMSession *olmSession = [NSKeyedUnarchiver unarchiveObjectWithData:grdbSession.olmSessionData];
      
      MXOlmSession* mxOlmSession = [[MXOlmSession alloc] initWithOlmSession:olmSession];
      mxOlmSession.lastReceivedMessageTs = grdbSession.lastReceivedMessageTs;
      
      block(mxOlmSession);
      
      grdbSession.olmSessionData = [NSKeyedArchiver archivedDataWithRootObject:mxOlmSession.session];
    } else {
      MXLogError(@"[MXSqliteCryptoStore] performOlmSessionTransactionForSessionId. Error: olm session %@ not found", sessionId);
      block(nil);
    }
  }];
}
@end
