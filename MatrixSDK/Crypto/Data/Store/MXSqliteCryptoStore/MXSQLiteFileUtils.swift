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

@objcMembers public class MXSQLiteFileUtils {
  
  public static let MXSQLiteCryptoStoreFolder = "MXSQLiteCryptoStore"
  public class func mxStoreFolder(for bundleIndentifier: String?) -> URL {
    
    if let applicationGroupIdentifier = MXSDKOptions.sharedInstance().applicationGroupIdentifier,
       let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupIdentifier) {
      return sharedContainerURL.appendingPathComponent(Self.MXSQLiteCryptoStoreFolder)
    } else {
      return MXSQLiteFileUtils.defaultStoreFolder(for: bundleIndentifier).appendingPathComponent(Self.MXSQLiteCryptoStoreFolder)
    }
  }
  
  public class func defaultStoreFolder(for bundleIdentifier: String?) -> URL {
#if TARGET_OS_TV
    return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
#elseif TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST
    return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
#else
    // On OS X it is, so put files in Application Support. If we aren't running
    // in a sandbox, put it in a subdirectory based on the bundle identifier
    // to avoid accidentally sharing files between applications
    let applicationSupportPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
    let applicationSupportURL = URL(fileURLWithPath: applicationSupportPath)
    guard nil == ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] else {
      return applicationSupportURL
    }
    
    return applicationSupportURL.appendingPathComponent(bundleIdentifier ?? Bundle.main.bundleIdentifier ?? Bundle.main.executableURL?.lastPathComponent ?? "")
    
#endif
  }
}
