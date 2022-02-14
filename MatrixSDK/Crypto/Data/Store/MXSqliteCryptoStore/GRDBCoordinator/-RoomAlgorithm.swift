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

extension GRDBCoordinator {
  
  public func retrieveRoomAlgorithmFor(_ roomId: String) -> String? {
    do {
      return try self.pool.read { db in
        try MXGrdbRoomAlgorithm
          .select(MXGrdbRoomAlgorithm.CodingKeys.algorithm)
          .filter(MXGrdbRoomAlgorithm.CodingKeys.id == roomId)
          .fetchOne(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving room algorithm for room ID \(roomId): \(error)")
      return nil
    }
  }
  
  public func retrieveBlacklistUnverifiedDevicesFor(_ roomId: String) -> Bool {
    do {
      return try self.pool.read { db in
        return try MXGrdbRoomAlgorithm
          .select(MXGrdbRoomAlgorithm.CodingKeys.blacklistUnverifiedDevices)
          .filter(MXGrdbRoomAlgorithm.CodingKeys.id == roomId)
          .fetchOne(db) ?? false
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Blacklist Unverified Devices for room ID \(roomId): \(error)")
      return false
    }
  }
  
  public func storeBlacklistUnverifiedDevicesForRoomId(_ roomId: String, blacklist: Bool) {
    do {
      try pool.write { db in
        
        let roomAlgorithm = try MXGrdbRoomAlgorithm.findOrCreate(id: roomId, db: db)
        roomAlgorithm.blacklistUnverifiedDevices = blacklist
        try roomAlgorithm.save(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing Blacklist Unverified Devices for room ID \(roomId): \(error)")
    }
  }
  
  public func storeAlgorithmForRoomId(_ roomId: String, algorithm: String) {
    do {
      try pool.write { db in
        
        let roomAlgorithm = try MXGrdbRoomAlgorithm.findOrCreate(id: roomId, db: db)
        roomAlgorithm.algorithm = algorithm
        try roomAlgorithm.save(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing algorithm for room ID \(roomId): \(error)")
    }
  }
}
