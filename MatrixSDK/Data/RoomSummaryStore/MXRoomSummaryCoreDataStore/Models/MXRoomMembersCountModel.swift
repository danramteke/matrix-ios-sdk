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
import CoreData

@objc(MXRoomMembersCountModel)
public class MXRoomMembersCountModel: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MXRoomMembersCountModel> {
        return NSFetchRequest<MXRoomMembersCountModel>(entityName: "MXRoomMembersCountModel")
    }

    @NSManaged public var members: Int16
    @NSManaged public var joined: Int16
    @NSManaged public var invited: Int16
    
    internal static func from(roomMembersCount membersCount: MXRoomMembersCount) -> MXRoomMembersCountModel {
        let model = MXRoomMembersCountModel()
        
        model.members = Int16(membersCount.members)
        model.joined = Int16(membersCount.joined)
        model.invited = Int16(membersCount.invited)
        
        return model
    }
    
}