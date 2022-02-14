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

public final class MXGrdbUser: NSObject, Codable, FetchableRecord, PersistableRecord, TableRecord {
  
  public static let databaseTableName: String = "User"
  
  public var id: String
  public var crossSigningKeysData: Data?
  
  public init(id: String, crossSigningKeysData: Data?) {
    self.id = id
    self.crossSigningKeysData = crossSigningKeysData
  }
  
  public enum CodingKeys: String, CodingKey, ColumnExpression {
    case id
    case crossSigningKeysData
  }
  
  public class func findOrCreate(id: String, db: Database) throws -> Self {
    if let found = try Self
        .filter(Self.CodingKeys.id == id)
        .fetchOne(db) {
      return found
    } else {
      return try Self(id: id, crossSigningKeysData: nil)
        .saved(db)
    }
  }
}
