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
  
  public func storeDevice(_ device: MXGrdbDevice) {
    do {
      try pool.write { db in
        
        let _ = try MXGrdbUser.findOrCreate(id: device.userId, db: db)
        
        try device.save(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing MXGrdbDevice for user ID \(device.userId): \(error)")
    }
  }
  
  
  public func storeDevicesFor(userId: String, devices: Array<MXGrdbDevice>) {
    do {
      try pool.write { db in
        
        let _ = try MXGrdbUser.findOrCreate(id: userId, db: db)
        
        try MXGrdbDevice
          .filter(MXGrdbDevice.CodingKeys.userId == userId)
          .deleteAll(db)
        
        try devices.forEach { device in
          try device.save(db)
        }
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing MXGrdbDevices for user ID \(userId): \(error)")
    }
  }
  
  public func retrieveAllDevicesBy(userId: String) -> [MXGrdbDevice] {
    do {
      return try pool.read { db in
        return try MXGrdbDevice
          .filter(MXGrdbDevice.CodingKeys.userId == userId)
          .fetchAll(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving MXGrdbDevices for user ID \(userId): \(error)")
      return []
    }
  }
  
  public func retrieveDeviceBy(deviceId: String, userId: String) -> MXGrdbDevice? {
    do {
      return try pool.read { db in
        return try MXGrdbDevice
          .filter(MXGrdbDevice.CodingKeys.userId == userId)
          .filter(MXGrdbDevice.CodingKeys.id == deviceId)
          .fetchOne(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving MXGrdbDevice for user ID \(userId): \(error)")
      return nil
    }
  }
  
  public func retrieveDeviceBy(identityKey: String) -> MXGrdbDevice? {
    do {
      return try pool.read { db in
        return try MXGrdbDevice
          .filter(MXGrdbDevice.CodingKeys.identityKey == identityKey)
          .fetchOne(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving MXGrdbDevice for identity key \(identityKey): \(error)")
      return nil
    }
  }
}
