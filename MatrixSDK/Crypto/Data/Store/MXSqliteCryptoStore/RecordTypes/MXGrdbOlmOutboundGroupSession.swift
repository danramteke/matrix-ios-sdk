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
public final class MXGrdbOlmOutboundGroupSession: NSObject, Codable, FetchableRecord, PersistableRecord, TableRecord {
  public static let databaseTableName: String = "OlmOutboundGroupSession"
  
  public var roomId: String
  public var sessionId: String
  public var creationTime: TimeInterval
  public var sessionData: Data
  
  public init(roomId: String, sessionId: String, sessionData: Data) {
    self.roomId = roomId
    self.sessionId = sessionId
    self.sessionData = sessionData
    self.creationTime = Date().timeIntervalSince1970
  }
  
  public enum CodingKeys: String, CodingKey, ColumnExpression {
    case roomId, sessionId
    case creationTime
    case sessionData
  }
}
