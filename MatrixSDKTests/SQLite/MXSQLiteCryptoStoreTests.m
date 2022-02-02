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

#import <XCTest/XCTest.h>
#import "MXSQLiteCryptoStore.h"
#import "MXCredentials.h"
#import <OLMKit/OLMKit.h>


@implementation MXCredentials

-(instancetype)initWithUserId:(NSString *)userId deviceId:(NSString *)deviceId {
  self = [super init];
  if (self) {
    self.userId = userId;
    self.deviceId = deviceId;
  }
  return self;
}

@end

@interface MXSQLiteCryptoStoreTests : XCTestCase

@property (nonatomic, strong) MXCredentials* credentials;

@end

@implementation MXSQLiteCryptoStoreTests

- (void)setUp {
  self.credentials = [[MXCredentials alloc] initWithUserId:@"exampleUserId" deviceId:@"exampleDeviceId"];
  [MXSQLiteCryptoStore deleteAllStores];
}

- (void)tearDown {
  self.credentials = nil;
  [MXSQLiteCryptoStore deleteAllStores];
}

- (void)test_hasDataForCredentials_falseInitially {
  BOOL result = [MXSQLiteCryptoStore hasDataForCredentials:self.credentials];
  XCTAssertFalse(result);
}

- (void)testCreateStore {
  [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  XCTAssertTrue([MXSQLiteCryptoStore hasDataForCredentials:self.credentials]);
}

- (void)testStoreAndRetrieveDeviceId {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  XCTAssertTrue([MXSQLiteCryptoStore hasDataForCredentials:self.credentials]);
  XCTAssertEqualObjects(self.credentials.deviceId, [store deviceId]);
  
  [store storeDeviceId:@"new-device-id"];
  XCTAssertEqualObjects(@"new-device-id", [store deviceId]);
}

- (void)testStoreAndRetrieveDeviceSyncToken{
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];

  XCTAssertEqualObjects(nil, [store deviceSyncToken]);
  
  [store storeDeviceSyncToken:@"newDeviceSyncToken"];
  XCTAssertEqualObjects(@"newDeviceSyncToken", [store deviceSyncToken]);
}

- (void)testStoreAndRetrieveOLMAccount {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  
  XCTAssertEqualObjects(nil, [store account]);
  
  OLMAccount* olmAccount = [[OLMAccount alloc] initNewAccount];
  [store setAccount:olmAccount];
  
  OLMAccount* retrievedAccount = [store account];
  XCTAssertNotNil(retrievedAccount);
  XCTAssertEqualObjects(olmAccount.identityKeys, retrievedAccount.identityKeys);
  XCTAssertEqualObjects(olmAccount.oneTimeKeys, retrievedAccount.oneTimeKeys);
}

@end
