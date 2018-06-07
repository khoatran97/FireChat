//
//  Constants.swift
//  FireChat
//
//  Created by Khoa Huu Tran on 6/6/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import Firebase

struct Constants
{
    struct refs
    {
        static let databaseRoot = Database.database().reference()
        static let databaseUsers = databaseRoot.child("Users")
        static let databaseConversations = databaseRoot.child("Conversations")
    }
}
