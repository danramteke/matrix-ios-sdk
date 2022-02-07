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

extension GRDBCoordinator {
  
  public func retrieveSharedOutboundSessionWithRoomId(_ roomId: String, sessionId: String) -> MXGrdbSharedOutboundSession? {
    do {
      return try self.pool.read { db in
        return try MXGrdbSharedOutboundSession
          .filter(MXGrdbSharedOutboundSession.CodingKeys.roomId == roomId)
          .filter(MXGrdbSharedOutboundSession.CodingKeys.sessionId == sessionId)
//          ._including(optional: <#T##_SQLAssociation#>)
          .fetchOne(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Shared Outbound Session for room ID \(roomId): \(error)")
      return nil
    }
  }
}
