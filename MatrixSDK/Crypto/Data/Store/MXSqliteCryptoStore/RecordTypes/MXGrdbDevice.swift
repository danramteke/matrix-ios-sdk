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
public class MXGrdbDevice: NSObject, Codable, FetchableRecord, PersistableRecord, TableRecord {
  
  public static let databaseTableName: String = "Device"
  
  public var id: String
  public var userId: String
  public var identityKey: String
  public var data: Data

  public init(id: String,
              userId: String,
              identityKey: String,
              data: Data) {
    self.id = id
    self.userId = userId
    self.identityKey = identityKey
    self.data = data
  }
  
  public enum CodingKeys: String, CodingKey, ColumnExpression {
    case id
    case identityKey
    case data
    case userId
  }
}
