//
//  TaskController.swift
//  Tasks
//
//  Created by Spencer Curtis on 4/27/20.
//  Copyright © 2020 Andrew R Madsen. All rights reserved.
//

import Foundation
import CoreData

enum NetworkError: Error {
    case noIdentifier
    case otherError
    case noData
    case noDecode
    case noEncode
    case noRep
}

class TaskController {
    
    typealias CompletionHandler = (Result<Bool, NetworkError>) -> Void
    
    let baseURL = URL(string: "https://tasks-3f211.firebaseio.com/")!
    
    func put(task: Task, completion: @escaping CompletionHandler) {
        
        // Check to make sure an id exists, otherwise we can't PUT the Task to a unique place in Firebase
        
        guard let identifier = task.identifier else {
            completion(.failure(.noIdentifier))
            return
        }
        
        let requestURL = baseURL
            .appendingPathComponent(identifier.uuidString)
            .appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        
        // Turn the Task into a TaskRepresentation, then TR into JSON.
        
        do {
            guard let taskRepresentation = task.taskRepresentation else {
                completion(.failure(.noRep))
                return
            }
            
            request.httpBody = try JSONEncoder().encode(taskRepresentation)
        } catch {
            NSLog("Error encoding task \(task): \(error)")
            completion(.failure(.noEncode))
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            
            if let error = error {
                NSLog("Error PUTting task to server: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.otherError))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(true))
            }
        }.resume()
    }
    
    func fetchTasksFromServer(completion: @escaping CompletionHandler = { _ in }) {
        
        let requestURL = baseURL.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            
            if let error = error {
                NSLog("Error fetching tasks: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.otherError))
                }
                return
            }
            
            guard let data = data else {
                NSLog("Error: No data returned from data task")
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
         
            // Pull the JSON out of the data, and turn it into [TaskRepresentation]
            do {
                let taskRepresentations = try JSONDecoder().decode([String: TaskRepresentation].self, from: data).map({ $0.value })
            
                // Figure out which task representations don't exist in Core Data, so we can add them, and figure out which ones have changed
                try self.updateTasks(with: taskRepresentations)
                
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            } catch {
                NSLog("Error decoding task representations: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.noDecode))
                }
            }
        }.resume()
    }
    
    func updateTasks(with representations: [TaskRepresentation]) throws {
        
        let identifiersToFetch = representations.compactMap({ UUID(uuidString: $0.identifier) })
        
        let representationsByID = Dictionary(uniqueKeysWithValues:
            zip(identifiersToFetch, representations)
        )
        
        // Make a copy of the representationsByID for later use
        var tasksToCreate = representationsByID
        
        // Ask Core Data to find any tasks with these identifiers
        
        // if identifiersToFetch.contains(someTaskInCoreData)
        let predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
        
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = predicate
        
        let context = CoreDataStack.shared.mainContext
        
        do {
            
            // This will only fetch the tasks that match the criteria in our predicate
            let existingTasks = try context.fetch(fetchRequest)
            
            // Let's update the tasks that already exist in Core Data
            
            for task in existingTasks {
                
                guard let id = task.identifier,
                    let representation = representationsByID[id] else { continue }
                
                task.name = representation.name
                task.notes = representation.notes
                task.complete = representation.complete
                task.priority = representation.priority
                
                // If we updated the task, that means we don't need to make a copy of it. It already exists in Core Data, so remove it from the tasks we still need to create
                tasksToCreate.removeValue(forKey: id)
            }
            
            // Add the tasks that don't exist
            for representation in tasksToCreate.values {
                Task(taskRepresentation: representation, context: context)
            }
            
        } catch {
            NSLog("Error fetching tasks for UUIDs: \(error)")
        }
        
        try self.saveToPersistentStore()
    }
    
    
    func saveToPersistentStore() throws {
        let moc = CoreDataStack.shared.mainContext
        try moc.save()
    }
}
