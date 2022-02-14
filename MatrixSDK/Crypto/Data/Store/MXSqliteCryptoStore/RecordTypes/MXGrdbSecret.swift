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
public final class MXGrdbSecret: NSObject, Codable, FetchableRecord, PersistableRecord, TableRecord {
  public static let databaseTableName: String = "Secret"

  public var id: String
  public var secret: String?
  public var encryptedSecret: Data?
  public var iv: Data?
  
  public enum CodingKeys: String, CodingKey, ColumnExpression {
    case id, secret, encryptedSecret, iv
  }

  public init(id: String, secret: String?, encryptedSecret: Data?, iv: Data?) {
    self.id = id
    self.secret = secret
    self.encryptedSecret = encryptedSecret
    self.iv = iv
  }
}
