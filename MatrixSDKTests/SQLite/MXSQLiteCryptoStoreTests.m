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
#import "MXTestDoubles.h"

@interface MXSQLiteCryptoStoreTests : XCTestCase
@property (nonatomic, strong) MXCredentials* credentials;
@end

@implementation MXSQLiteCryptoStoreTests

- (void)setUp {
  self.credentials = [[MXCredentials alloc] initForTestingWithUserId:@"exampleUserId" deviceId:@"exampleDeviceId"];
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

  XCTAssertNil([store deviceSyncToken]);
  
  [store storeDeviceSyncToken:@"newDeviceSyncToken"];
  XCTAssertEqualObjects(@"newDeviceSyncToken", [store deviceSyncToken]);
}

- (void)testStoreAndRetrieveGlobalBlacklistUnverifiedDevices {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  
  XCTAssertFalse([store globalBlacklistUnverifiedDevices]);
  
  [store setGlobalBlacklistUnverifiedDevices:true];
  XCTAssertTrue([store globalBlacklistUnverifiedDevices]);
}

- (void)testStoreAndRetrieveOLMAccount {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  
  XCTAssertNil([store account]);
  
  OLMAccount* olmAccount = [[OLMAccount alloc] initNewAccount];
  [store setAccount:olmAccount];
  
  OLMAccount* retrievedAccount = [store account];
  XCTAssertNotNil(retrievedAccount);
  XCTAssertEqualObjects(olmAccount.identityKeys, retrievedAccount.identityKeys);
  XCTAssertEqualObjects(olmAccount.oneTimeKeys, retrievedAccount.oneTimeKeys);
}

- (void)testStoreAndRetrieveDeviceTrackingStatus {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  
  XCTAssertNil([store account]);
  
  NSDictionary* dict = @{@"key": @1};
  [store storeDeviceTrackingStatus:dict];
  
  NSDictionary* retrievedDict = [store deviceTrackingStatus];
  XCTAssertNotNil(retrievedDict);
  XCTAssertEqualObjects(retrievedDict, dict);
}

- (void)testStoreAndRetrieveDevice {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];

  MXDeviceInfo* otherDevice = [[MXDeviceInfo alloc] initForTestingWithUserId:@"other user" deviceId:@"other device" identityKey:@"other identity key"];
  
  XCTAssertNil([store account]);
  XCTAssertNil([store deviceWithDeviceId:@"other device" forUser:@"other user"]);
  

  [store storeDeviceForUser:@"other user" device:otherDevice];
  
  MXDeviceInfo* retrievedDevice = [store deviceWithDeviceId:@"other device" forUser:@"other user"];
  XCTAssertNotNil(retrievedDevice);
  
  XCTAssertEqualObjects(retrievedDevice.keys, otherDevice.keys);
  XCTAssertEqualObjects(retrievedDevice.userId, otherDevice.userId);
  XCTAssertEqualObjects(retrievedDevice.userId, @"other user");
  XCTAssertEqualObjects(retrievedDevice.deviceId, otherDevice.deviceId);
  XCTAssertEqualObjects(retrievedDevice.deviceId, @"other device");
  XCTAssertEqualObjects(retrievedDevice.identityKey, otherDevice.identityKey);
  XCTAssertEqualObjects(retrievedDevice.identityKey, @"other identity key");
}

- (void)testStoreAndRetrieveDeviceWithIdentityKey {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  MXDeviceInfo* otherDevice = [[MXDeviceInfo alloc] initForTestingWithUserId:@"other user" deviceId:@"other device" identityKey:@"other identity key"];
  
  XCTAssertNil([store account]);
  XCTAssertNil([store deviceWithDeviceId:@"other device" forUser:@"other user"]);
  XCTAssertNil([store deviceWithIdentityKey:@"other identity key"]);
  

  [store storeDeviceForUser:@"other user" device:otherDevice];

  
  MXDeviceInfo* retrievedDevice = [store deviceWithIdentityKey:otherDevice.identityKey];
  XCTAssertNotNil(retrievedDevice);
  
  XCTAssertEqualObjects(retrievedDevice.keys, otherDevice.keys);
  XCTAssertEqualObjects(retrievedDevice.userId, otherDevice.userId);
  XCTAssertEqualObjects(retrievedDevice.userId, @"other user");
  XCTAssertEqualObjects(retrievedDevice.deviceId, otherDevice.deviceId);
  XCTAssertEqualObjects(retrievedDevice.deviceId, @"other device");
  XCTAssertEqualObjects(retrievedDevice.identityKey, otherDevice.identityKey);
  XCTAssertEqualObjects(retrievedDevice.identityKey, @"other identity key");
}

- (void)testStoreAndRetriveDeviceDictionary {

  MXDeviceInfo* otherDevice = [[MXDeviceInfo alloc] initForTestingWithUserId:@"other user" deviceId:@"other device" identityKey:@"other identity key"];
  MXDeviceInfo* thirdDevice = [[MXDeviceInfo alloc] initForTestingWithUserId:@"other user" deviceId:@"third device" identityKey:@"third identity key"];
  
  NSDictionary* allDevices = @{
    otherDevice.deviceId: otherDevice,
    thirdDevice.deviceId: thirdDevice
  };

  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  XCTAssertNil([store deviceWithIdentityKey:@"other identity key"]);
  XCTAssertNil([store deviceWithIdentityKey:@"third identity key"]);
  
  [store storeDevicesForUser:@"other user" devices:allDevices];
  
  XCTAssertNotNil([store deviceWithIdentityKey:@"other identity key"]);
  XCTAssertNotNil([store deviceWithIdentityKey:@"third identity key"]);
  XCTAssertNotNil([store deviceWithDeviceId:@"other device" forUser:@"other user"]);
  XCTAssertNotNil([store deviceWithDeviceId:@"third device" forUser:@"other user"]);
  
  NSDictionary* retrievedDevices = [store devicesForUser:@"other user"];
  XCTAssertNotNil(retrievedDevices);
  XCTAssertNotNil(retrievedDevices[@"other device"]);
  XCTAssertNotNil(retrievedDevices[@"third device"]);
}

-(void)testStoreAndRetrieveCrossSigningKeysData {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
//  MXCrossSigningInfo* info = [[MXCrossSigningInfo alloc] init];

//  info.userId = @"abc user";
  
//  [store storeCrossSigningKeys:info];
  
  // TODO: implement test inits for MXCrossSigningInfo
}

@end
