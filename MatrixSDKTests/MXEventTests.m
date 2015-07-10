/*
 Copyright 2014 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MatrixSDKTestsData.h"

#import "MXSession.h"

@interface MXEventTests : XCTestCase
{
    MXSession *mxSession;
}

@end

@implementation MXEventTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    if (mxSession)
    {
        [[MatrixSDKTestsData sharedData] closeMXSession:mxSession];
        mxSession = nil;
    }
    [super tearDown];
}

- (void)doTestWithMXEvents:(void (^)(MXRestClient *bobRestClient, NSString* roomId, NSArray *events, XCTestExpectation *expectation))readyToTest
{
    [[MatrixSDKTestsData sharedData] doMXRestClientTestWithBobAndARoomWithMessages:self readyToTest:^(MXRestClient *bobRestClient, NSString *roomId, XCTestExpectation *expectation) {

        [bobRestClient messagesForRoom:roomId from:nil to:nil limit:100 success:^(MXPaginationResponse *paginatedResponse) {

            NSAssert(0 < paginatedResponse.chunk.count, @"Cannot set up intial test conditions");

            readyToTest(bobRestClient, roomId, paginatedResponse.chunk, expectation);

        } failure:^(NSError *error) {
            XCTFail(@"The request should not fail - NSError: %@", error);
            [expectation fulfill];
        }];
    }];
}

- (void)testAge
{
    [self doTestWithMXEvents:^(MXRestClient *bobRestClient, NSString *roomId, NSArray *events, XCTestExpectation *expectation) {

        for (MXEvent *event in events)
        {
            NSUInteger age = event.age;
            XCTAssertGreaterThan(age, 0);

            uint64_t ageLocalTs = event.ageLocalTs;
            XCTAssertLessThan(ageLocalTs, [[NSDate date] timeIntervalSince1970] * 1000, @"The event must be older than the current Epoch time");

            XCTAssertLessThan(ABS(event.ageLocalTs - event.originServerTs), 1000, @"MXEvent.ageLocalTs and MXEvent.originServerTs values should be very close");

            // Wait a bit before checking `age` again
            [NSThread sleepForTimeInterval:0.1];

            NSUInteger newAge = event.age;
            XCTAssertGreaterThanOrEqual(newAge, age + 100, @"MXEvent.age should auto increase");

            uint64_t newAgeLocalTs = event.ageLocalTs;
            XCTAssertEqual(newAgeLocalTs, ageLocalTs, @"MXEvent.ageLocalTs must still be the same");
        }

        [expectation fulfill];
    }];
}

- (void)testIsState
{
    [[MatrixSDKTestsData sharedData] doMXRestClientTestWithBobAndARoomWithMessages:self readyToTest:^(MXRestClient *bobRestClient, NSString *roomId, XCTestExpectation *expectation) {
        
        mxSession = [[MXSession alloc] initWithMatrixRestClient:bobRestClient];

        [mxSession start:^{

            MXRoom *room = [mxSession roomWithRoomId:roomId];
            
            for (MXEvent *stateEvent in room.state.stateEvents)
            {
                XCTAssertTrue(stateEvent.isState, "All events in room.stateEvents must be states. stateEvent: %@", stateEvent);
            }
            
            
            __block NSUInteger eventCount = 0;
            [room listenToEventsOfTypes:@[kMXEventTypeStringRoomMessage] onEvent:^(MXEvent *event, MXEventDirection direction, MXRoomState *roomState) {
                
                eventCount++;
                XCTAssertFalse(event.isState, "Room messages are not states. message: %@", event);
                
            }];
            
            [room resetBackState];
            [room paginateBackMessages:100 complete:^() {
                
                XCTAssertGreaterThan(eventCount, 0, "We should have received events in registerEventListenerForTypes");
                
                [expectation fulfill];
                
            } failure:^(NSError *error) {
                XCTFail(@"The request should not fail - NSError: %@", error);
                [expectation fulfill];
            }];
            
        } failure:^(NSError *error) {
            XCTFail(@"The request should not fail - NSError: %@", error);
            [expectation fulfill];
        }];
    }];
}

// Make sure MXEvent is serialisable
- (void)testNSCoding
{
    [self doTestWithMXEvents:^(MXRestClient *bobRestClient, NSString *roomId, NSArray *events, XCTestExpectation *expectation) {

        for (MXEvent *event in events)
        {
            // Check unserialisation of a serialised event
            [NSKeyedArchiver archiveRootObject:event toFile:@"event"];
            MXEvent *event2 = [NSKeyedUnarchiver unarchiveObjectWithFile:@"event"];

            // XCTAssertEqualObjects will compare MXEvent.descriptions which
            // provide good enough object data signature
            XCTAssertEqualObjects(event.description, event2.description);
        }

        [expectation fulfill];
    }];
}

- (void)testOriginalDictionary
{
    [self doTestWithMXEvents:^(MXRestClient *bobRestClient, NSString *roomId, NSArray *events, XCTestExpectation *expectation) {

        for (MXEvent *event in events)
        {
            XCTAssertNil([event.originalDictionary objectForKey:@"event_type"], @"eventType is an information added by the SDK not sent by the home server");
            XCTAssertNil([event.originalDictionary objectForKey:@"age_local_ts"], @"ageLocalTs is an information added by the SDK not sent by the home server");
        }

        [expectation fulfill];
    }];
}

@end