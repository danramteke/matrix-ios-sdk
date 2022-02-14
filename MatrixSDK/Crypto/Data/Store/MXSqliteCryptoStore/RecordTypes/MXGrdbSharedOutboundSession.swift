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

import Foundation

@objcMembers
public final class MXGrdbSharedOutboundSession: NSObject, Codable, FetchableRecord, PersistableRecord, TableRecord {
  public static let databaseTableName: String = "SharedOutboundSession"
  
  public var roomId: String
  public var sessionId: String
  public var deviceId: String
  public var userId: String
  public var messageIndex: UInt
  
  public init(roomId: String, sessionId: String, deviceId: String, userId: String, messageIndex: UInt) {
    self.roomId = roomId
    self.sessionId = sessionId
    self.deviceId = deviceId
    self.userId = userId
    self.messageIndex = messageIndex
  }
  
  public enum CodingKeys: String, CodingKey, ColumnExpression {
    case roomId, sessionId, deviceId, userId, messageIndex
  }
}
