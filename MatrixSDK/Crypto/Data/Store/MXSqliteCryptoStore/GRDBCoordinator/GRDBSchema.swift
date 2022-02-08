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

final class GRDBSchema {
  var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()
    migrator.registerMigration("createInitialTables") { db in
      try db.create(table: "OlmAccount") { t in
        t.column("userId", .text).notNull()
        t.column("deviceId", .text).notNull()
        t.column("backupVersion", .text)
        t.column("deviceTrackingStatusData", .blob)
        t.column("deviceSyncToken", .text)
        t.column("globalBlacklistUnverifiedDevices", .boolean)
        t.column("olmAccountData", .blob)
        t.primaryKey(["userId"], onConflict: .rollback)
      }
      
      try db.create(table: "Device") { t in
        t.column("id", .text).notNull()
        t.column("userId", .text).notNull()
        t.column("identityKey", .text)
        t.column("data", .blob)
        t.primaryKey(["id", "userId"], onConflict: .rollback)
      }
      
      try db.create(table: "User") { t in
        t.column("id", .text).notNull()
        t.column("crossSigningKeysData", .blob)
        t.primaryKey(["id"], onConflict: .rollback)
      }
      
      try db.create(table: "RoomAlgorithm") { t in
        t.column("id", .text).notNull()
        t.column("algorithm", .text)
        t.column("blacklistUnverifiedDevices", .boolean)
        t.primaryKey(["id"], onConflict: .rollback)
      }
      
      try db.create(table: "OlmSession") { t in
        t.column("id", .text).notNull()
        t.column("deviceKey", .text)
        t.column("lastReceivedMessageTs", .double)
        t.column("olmSessionData", .blob)
      }
      
      try db.create(table: "OlmInboundGroupSession") { t in
        t.column("id", .text).notNull()
        t.column("senderKey", .text)
        t.column("olmInboundGroupSessionData", .blob)
        t.column("backedUp", .boolean)
        t.primaryKey(["id", "senderKey"], onConflict: .rollback)
      }
      
      try db.create(table: "OlmOutboundGroupSession") { t in
        t.column("roomId", .text).notNull()
        t.column("sessionId", .text)
        t.column("sessionData", .blob)
        t.column("creationTime", .double)
        t.primaryKey(["roomId"], onConflict: .rollback)
      }
      
      try db.create(table: "SharedOutboundSession") { t in
        t.column("roomId", .text).notNull()
        t.column("sessionId", .text)
        t.column("deviceId", .text)
        t.column("userId", .text)
        t.column("messageIndex", .integer)
      }
      
      try db.create(table: "OutgoingRoomKeyRequest") { t in
        t.column("id", .text).notNull()
        t.column("cancellationTxnId", .text)
        t.column("recipientsData", .blob)
        t.column("requestBodyString", .text)
        t.column("requestBodyHash", .text)
        t.column("state", .integer)
        t.primaryKey(["id"])
      }
      
      try db.create(table: "IncomingRoomKeyRequest") { t in
        t.column("id", .text).notNull()
        t.column("userId", .text)
        t.column("deviceId", .text)
        t.column("requestBodyData", .blob)
      }
      
      try db.create(table: "Secret") { t in
        t.column("id", .text).notNull()
        t.column("secret", .text)
        t.column("encryptedSecret", .blob)
        t.column("iv", .blob)
      }
    }
    return migrator
  }
}
