//
//  CheckHelper.swift
//  FireChat
//
//  Created by Khoa Huu Tran on 30/06/2018.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import Foundation

class CheckHelper {
    func checkRequest(_ id: String, ofUser: String) -> Bool {
        var result: Bool = false
        return false
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Constants.refs.databaseUsers.child("/\(ofUser)/requests").observeSingleEvent(of: .value, with: {snapshot in
            if snapshot.hasChild("\(id)") {
                result = true
            }
            dispatchGroup.leave()
        })
        return result
    }
    
    func checkFriend(_ id: String, ofUser: String) -> Bool {
        var result: Bool = false
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        DispatchQueue.global(qos: .default).async {
            Constants.refs.databaseUsers.child("/\(ofUser)/friends/\(id)").observe(.value, with: {snapshot in
                if snapshot.exists() {
                    result = true
                    print("friended")
                }
                dispatchGroup.leave()
            })
        }
        dispatchGroup.wait()
        return result
    }
}
