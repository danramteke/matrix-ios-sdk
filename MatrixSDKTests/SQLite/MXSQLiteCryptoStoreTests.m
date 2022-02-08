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
#import "MXOlmSession.h"
#import "MXLog.h"
#import "MXCryptoTools.h"

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
  
  __block BOOL blockDidRun = false;
  [store performAccountOperationWithBlock:^(OLMAccount *olmAccount) {
    XCTAssertNotNil(olmAccount);
    blockDidRun = true;
  }];
  XCTAssertTrue(blockDidRun);
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

-(void)testStoreAndRetrieveRoomAlgorithm {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  
  XCTAssertNil([store algorithmForRoom:@"room id"]);
  [store storeAlgorithmForRoom:@"room id" algorithm:@"shortest path"];
  XCTAssertEqualObjects(@"shortest path", [store algorithmForRoom:@"room id"]);
}

-(void)testStoreAndRetrieveRoomBlacklist {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  
  XCTAssertFalse([store blacklistUnverifiedDevicesInRoom:@"room id"]);
  [store storeBlacklistUnverifiedDevicesInRoom:@"room id" blacklist:true];
  XCTAssertTrue([store blacklistUnverifiedDevicesInRoom:@"room id"]);
}

-(void)testStoreAndRetrieveOlmSession {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  
  OLMAccount* account = [[OLMAccount alloc] initNewAccount];
  OLMSession* olmSession = [[OLMSession alloc] initOutboundSessionWithAccount:account theirIdentityKey:@"YXJzdG5lc3RuaXJudGlzTklybnRpclNUZU5JYQo=" theirOneTimeKey:@"YXJzdG5lc3RuaXJudGlzTklybnRpclNUZU5JYQo=" error:nil];
  // TODO: how to create a correct an olm session?
  MXOlmSession* mxolmSession = [[MXOlmSession alloc] initWithOlmSession:olmSession];

  [store storeSession:mxolmSession forDevice:@"device"];
  
  MXOlmSession* retrievedSession = [store sessionWithDevice:@"device" andSessionId:olmSession.sessionIdentifier];
  XCTAssertNotNil(retrievedSession);
  XCTAssertEqualObjects(retrievedSession.session.sessionIdentifier, olmSession.sessionIdentifier);
  
  
  //block
  __block BOOL blockDidRun = false;
  [store performSessionOperationWithDevice:@"device" andSessionId:olmSession.sessionIdentifier block:^(MXOlmSession *blockSession) {
    XCTAssertNotNil(blockSession);
    blockDidRun = true;
  }];
  XCTAssertTrue(blockDidRun);
  
  //all
  NSArray<MXOlmSession*>* sessions = [store sessionsWithDevice:@"device"];
  XCTAssertEqual(sessions.count, 1);
  
}

-(void)testStoreAndRetrieveInboundOlmGroupSession {
  
  OLMAccount* aliceAccount = [[OLMAccount alloc] initNewAccount];
  OLMAccount* bobAccount = [[OLMAccount alloc] initNewAccount];

  NSError *error;
  
  OLMOutboundGroupSession *aliceSession = [[OLMOutboundGroupSession alloc] initOutboundGroupSession];
  XCTAssertGreaterThan(aliceSession.sessionIdentifier.length, 0);
  XCTAssertGreaterThan(aliceSession.sessionKey.length, 0);
  XCTAssertEqual(aliceSession.messageIndex, 0);

  NSString *sessionKey = aliceSession.sessionKey;
  
  NSString *message = @"Hello!";
  NSString *aliceToBobMsg = [aliceSession encryptMessage:message error:&error];
  
  XCTAssertEqual(aliceSession.messageIndex, 1);
  XCTAssertGreaterThanOrEqual(aliceToBobMsg.length, 0);
  XCTAssertNil(error);
  
  OLMInboundGroupSession *bobSession = [[OLMInboundGroupSession alloc] initInboundGroupSessionWithSessionKey:sessionKey error:&error];
  XCTAssertEqualObjects(aliceSession.sessionIdentifier, bobSession.sessionIdentifier);
  XCTAssertNil(error);
  
  
  MXMegolmSessionData* aliceSessionData = [[MXMegolmSessionData alloc] init];
  aliceSessionData.senderKey = aliceAccount.identityKeys[@"curve25519"];
  aliceSessionData.sessionId = aliceSession.sessionIdentifier;
  aliceSessionData.sessionKey = sessionKey;


  MXOlmInboundGroupSession* mxInboundGroupSession1 = [[MXOlmInboundGroupSession alloc]      initWithSessionKey:sessionKey];
  mxInboundGroupSession1.session = bobSession; // TODO: make a test init for these properties
  mxInboundGroupSession1.senderKey = bobAccount.identityKeys[@"curve25519"];
  
  NSArray<MXOlmInboundGroupSession *>* sessions = @[
    mxInboundGroupSession1,
  ];
  
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  [store storeInboundGroupSessions:sessions];
  XCTAssertEqual(sessions.count, 1);
  XCTAssertEqual([store inboundGroupSessionsCount:false], 1);
  
  [store storeInboundGroupSessions:sessions];
  XCTAssertEqual([store inboundGroupSessionsCount:false], 1, @"saving again should not increase count");
  
  MXOlmInboundGroupSession* retrievedInboundSession = [store inboundGroupSessionWithId:mxInboundGroupSession1.session.sessionIdentifier andSenderKey:mxInboundGroupSession1.senderKey];
  XCTAssertNotNil(retrievedInboundSession);
  XCTAssertEqualObjects(retrievedInboundSession.senderKey, mxInboundGroupSession1.senderKey);
  
  //in transaction
  __block BOOL blockDidRun = false;
  [store performSessionOperationWithGroupSessionWithId:mxInboundGroupSession1.session.sessionIdentifier senderKey:mxInboundGroupSession1.senderKey block:^(MXOlmInboundGroupSession *blockSession) {
    XCTAssertNotNil(blockSession);
    blockDidRun = true;
  }];
  XCTAssertTrue(blockDidRun);
  
  //all
  NSArray<MXOlmInboundGroupSession *>* retrievedSessions = [store inboundGroupSessions];
  XCTAssertEqual(retrievedSessions.count, 1);
  XCTAssertEqualObjects(retrievedSessions.firstObject.senderKey, mxInboundGroupSession1.senderKey);
  
  //backup
  NSArray<MXOlmInboundGroupSession *>* retrievedInboundSessionNeedingBackup = [store inboundGroupSessionsToBackup:1];
  XCTAssertEqual(retrievedInboundSessionNeedingBackup.count, 1);
  [store markBackupDoneForInboundGroupSessions:retrievedInboundSessionNeedingBackup];
  XCTAssertEqual(0, [store inboundGroupSessionsToBackup:1].count);
  [store resetBackupMarkers];
  XCTAssertEqual(1, [store inboundGroupSessionsToBackup:1].count);
  
  //remove
  [store removeInboundGroupSessionWithId:mxInboundGroupSession1.session.sessionIdentifier andSenderKey:mxInboundGroupSession1.senderKey];
  XCTAssertEqual([store inboundGroupSessionsCount:false], 0);
}

-(void)testStoreAndRetrieveOutboundOlmGroupSession {
  OLMOutboundGroupSession *aliceSession = [[OLMOutboundGroupSession alloc] initOutboundGroupSession];
  XCTAssertGreaterThan(aliceSession.sessionIdentifier.length, 0);
  XCTAssertGreaterThan(aliceSession.sessionKey.length, 0);
  XCTAssertEqual(aliceSession.messageIndex, 0);
  
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  MXOlmOutboundGroupSession* mxSession = [store storeOutboundGroupSession:aliceSession withRoomId:@"Alice Room ID"];
  XCTAssertEqualObjects(mxSession.roomId, @"Alice Room ID");
  
  MXOlmOutboundGroupSession* retrievedMxSession = [store outboundGroupSessionWithRoomId:@"Alice Room ID"];
  XCTAssertEqualObjects(retrievedMxSession.roomId, @"Alice Room ID");
  XCTAssertEqualObjects(retrievedMxSession.sessionKey, aliceSession.sessionKey);
  
  NSArray<MXOlmOutboundGroupSession*>* retrievedMxSessions = [store outboundGroupSessions];
  XCTAssertNotNil(retrievedMxSessions);
  XCTAssertEqualObjects([retrievedMxSessions firstObject].roomId, @"Alice Room ID");
  XCTAssertEqualObjects([retrievedMxSessions firstObject].sessionKey, aliceSession.sessionKey);
  
  [store removeOutboundGroupSessionWithRoomId:@"Alice Room ID"];
  XCTAssertEqual(0, [store outboundGroupSessions].count);
}

-(void)testStoreAndRetrieveUserDeviceMapOfMessageIndex {
  
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  [store storeDeviceForUser:@"user 1" device:[[MXDeviceInfo alloc] initForTestingWithUserId:@"user 1" deviceId:@"device 1-1" identityKey:@"device 1-1 key"]];
  [store storeDeviceForUser:@"user 1" device:[[MXDeviceInfo alloc] initForTestingWithUserId:@"user 1" deviceId:@"device 1-2" identityKey:@"device 1-2 key"]];
  [store storeDeviceForUser:@"user 2" device:[[MXDeviceInfo alloc] initForTestingWithUserId:@"user 2" deviceId:@"device 2-1" identityKey:@"device 2-1 key"]];

  MXUsersDevicesMap* map = [[MXUsersDevicesMap alloc] init];
  [map setObject:@(11) forUser:@"user 1" andDevice:@"device 1-1"];
  [map setObject:@(12) forUser:@"user 1" andDevice:@"device 1-2"];
  [map setObject:@(21) forUser:@"user 2" andDevice:@"device 2-1"];
  
  [store storeSharedDevices:map messageIndex:95 forOutboundGroupSessionInRoomWithId:@"room id" sessionId:@"session id"];
  
  // retrieve full map
  MXUsersDevicesMap* retrievedMap = [store sharedDevicesForOutboundGroupSessionInRoomWithId:@"room id" sessionId:@"session id"];
  XCTAssertEqual(retrievedMap.count, map.count);
  XCTAssertEqualObjects([retrievedMap objectForDevice:@"device 1-1" forUser:@"user 1"], @(95));
  XCTAssertEqualObjects([retrievedMap objectForDevice:@"device 1-2" forUser:@"user 1"], @(95));
  XCTAssertEqualObjects([retrievedMap objectForDevice:@"device 2-1" forUser:@"user 2"], @(95));
  XCTAssertNil([retrievedMap objectForDevice:@"device 99" forUser:@"user 199"]);
  
  XCTAssertEqualObjects([store messageIndexForSharedDeviceInRoomWithId:@"room id" sessionId:@"session id" userId:@"user 1" deviceId:@"device 1-1"], @(95));
  XCTAssertEqualObjects([store messageIndexForSharedDeviceInRoomWithId:@"room id" sessionId:@"session id" userId:@"user 1" deviceId:@"device 1-2"], @(95));
  XCTAssertEqualObjects([store messageIndexForSharedDeviceInRoomWithId:@"room id" sessionId:@"session id" userId:@"user 2" deviceId:@"device 2-1"], @(95));
}


-(void)testStoreAndRetriveBackupVersion {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  XCTAssertNil([store backupVersion]);
  [store setBackupVersion:@"example"];
  XCTAssertEqualObjects([store backupVersion], @"example");
}

-(void)testOutgoingRoomKeyRequest {
  MXSQLiteCryptoStore* store = [MXSQLiteCryptoStore createStoreWithCredentials:self.credentials];
  MXOutgoingRoomKeyRequest* request = [[MXOutgoingRoomKeyRequest alloc] init];
  request.state = MXRoomKeyRequestStateCancellationPendingAndWillResend;
  request.requestId = @"request id";
  request.recipients = @[
    @{
      @"userId": @"1",
      @"deviceId": @"1",
    },
    @{
      @"userId": @"2",
      @"deviceId": @"2",
    }
  ];
  request.requestBody = @{
    @"algorithm": @"lru",
    @"roomId": @"55",
    @"sessionId": @"session id",
    @"senderKey": @"sender key"
  };
  
  [store storeOutgoingRoomKeyRequest:request];
  
  MXOutgoingRoomKeyRequest* retrievedRequest = [store outgoingRoomKeyRequestWithState:MXRoomKeyRequestStateCancellationPendingAndWillResend];
  XCTAssertNotNil(retrievedRequest);
  XCTAssertEqualObjects(request.recipients, retrievedRequest.recipients);
  
  NSArray<MXOutgoingRoomKeyRequest*>* allRetrievedRequests = [store allOutgoingRoomKeyRequestsWithState:MXRoomKeyRequestStateCancellationPendingAndWillResend];
  XCTAssertEqual(1, allRetrievedRequests.count);
  XCTAssertEqualObjects(request.recipients, [allRetrievedRequests firstObject].recipients);
  
  MXOutgoingRoomKeyRequest* retrievedRequestWithBody = [store outgoingRoomKeyRequestWithRequestBody:request.requestBody];
  XCTAssertNotNil(retrievedRequestWithBody);
  XCTAssertEqualObjects(request.recipients, retrievedRequestWithBody.recipients);
}
@end
