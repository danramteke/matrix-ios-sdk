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
import GRDB

@objcMembers
public class MXGrdbOlmAccount: NSObject, Codable, FetchableRecord, PersistableRecord {
  
  public static var databaseTableName: String = "OlmAccount"
  
  public var deviceId: String
  public var userId: String
  
  public init(deviceId: String, userId: String) {
    self.deviceId = deviceId
    self.userId = userId
  }
  
  public required init(row: Row) {
    deviceId = row[CodingKeys.deviceId]
    userId = row[CodingKeys.userId]
  }
  
  public enum CodingKeys: String, CodingKey, ColumnExpression {
    case deviceId, userId
  }
}
