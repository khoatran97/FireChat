//
//  ConversationProtocol.swift
//  FireChat
//
//  Created by Khoa Huu Tran on 07/06/2018.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import Foundation

protocol ConversationDelegate {
    func SetChatView(conversation: Conversation)
}

protocol GroupDelegate {
    func setChatGroup(group: Group)
}
