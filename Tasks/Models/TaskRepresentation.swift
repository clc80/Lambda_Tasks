//
//  TaskRepresentation.swift
//  Tasks
//
//  Created by Spencer Curtis on 4/27/20.
//  Copyright © 2020 Andrew R Madsen. All rights reserved.
//

import Foundation

// The bridge between our NSManagedObject Task and the Task in JSON form from the server

struct TaskRepresentation: Codable {
    var complete: Bool
    var identifier: String
    var name: String
    var notes: String?
    var priority: String
}
