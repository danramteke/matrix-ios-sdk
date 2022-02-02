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
  NSError* error = nil;
  
  [self.grdbCoordinator storeDeviceId:deviceId for:self.userId error:&error];
  
  if (error) {
    MXLogDebug(@"[MXSQLiteCryptoStore] error storing device ID for user ID: %@, error: %@", self.userId, error);
  }
}

- (NSString*)deviceId
{
  return [self.grdbCoordinator accountIfExistsWithUserId:self.userId].deviceId;
}
@end
