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


#import "MXTestDoubles.h"

@implementation MXDeviceInfo (ForTesting)

//@synthesize identityKey;
//@synthesize deviceId;

-(instancetype)initForTestingWithUserId:(NSString *)userId deviceId:(NSString *)deviceId identityKey:(NSString*)identityKey {
  self = [self initWithDeviceId:deviceId];
  if (self) {
    self.userId = userId;
    self.keys = @{
      [NSString stringWithFormat:@"curve25519:%@", deviceId]: identityKey,
    };
  }
  return self;
}

@end


@implementation MXCredentials  (ForTesting)

-(instancetype)initForTestingWithUserId:(NSString *)userId deviceId:(NSString *)deviceId {
  self = [super init];
  if (self) {
    self.userId = userId;
    self.deviceId = deviceId;
  }
  return self;
}

@end

@implementation MXCrossSigningInfo  (ForTesting)

-(instancetype)initForTestingWithUserId:(NSString *)userId  keys:(NSDictionary<NSString*, MXCrossSigningKey*>*)keys {
  self = [super init];
  if (self) {
    self.userId = userId;
    self.keys = keys;
    self.trustLevel = [MXUserTrustLevel new];
  }
  return self;
}

@end
