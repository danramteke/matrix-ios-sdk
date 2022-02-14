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
public final class MXGrdbOutgoingRoomKeyRequest: NSObject, Codable, FetchableRecord, PersistableRecord, TableRecord {
  public static let databaseTableName: String = "OutgoingRoomKeyRequest"
  
  public var id: String
  public var cancellationTxnId: String?
  public var recipientsData: Data
  public var requestBodyString: String
  public var requestBodyHash: String
  public var state: UInt
  
  public init(id: String, cancellationTxnId: String?, recipientsData: Data, requestBodyString: String, requestBodyHash: String, state: UInt) {
    self.id = id
    self.cancellationTxnId = cancellationTxnId
    self.recipientsData = recipientsData
    self.requestBodyString = requestBodyString
    self.requestBodyHash = requestBodyHash
    self.state = state
  }
  
  public enum CodingKeys: String, CodingKey, ColumnExpression {
    case id, cancellationTxnId, recipientsData, requestBodyString, requestBodyHash, state
  }
}
