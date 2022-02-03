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
  OLMAccount* olmAccount = [self account];
  if (olmAccount) {
    block(olmAccount);
    [self setAccount:olmAccount];
  } else {
    MXLogError(@"[MXSQLiteCryptoStore] performAccountOperationWithBlock. Error: Cannot build OLMAccount");
    block(nil);
  } 
}

- (BOOL)globalBlacklistUnverifiedDevices {
  return [self.grdbCoordinator retrieveGlobalBlacklistUnverifiedDevicesFor:self.userId];
}

- (void)setGlobalBlacklistUnverifiedDevices:(BOOL)globalBlacklistUnverifiedDevices
{
  [self.grdbCoordinator storeGlobalBlacklistUnverifiedDevices:globalBlacklistUnverifiedDevices for:self.userId];
}
@end
