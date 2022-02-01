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
@end

@implementation MXSQLiteCryptoStore

- (instancetype)init {
  self = [super init];
  
  _grdbCoordinator = [[GRDBCoordinator alloc] init];
  return self;
}

@synthesize backupVersion;
@synthesize cryptoVersion;
@synthesize globalBlacklistUnverifiedDevices;

+ (BOOL)hasDataForCredentials:(MXCredentials*)credentials {
  return false;
}

//+ (instancetype)createStoreWithCredentials:(MXCredentials*)credentials {
//  NSString* fileName = [GRDBCoordinator fileNameWithUserId:credentials.userId andDeviceId:credentials.deviceId];
//  
//}

@end
