//
//  TaskTableViewCell.swift
//  Tasks
//
//  Created by Ben Gohlke on 2/25/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var completedButton: UIButton!
    
    // MARK: - Properties
    
    static let reuseIdentifier = "TaskCell"
    
    var task: Task? {
        didSet {
            updateViews()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func toggleComplete(_ sender: UIButton) {
        task?.complete.toggle()
        
        guard let task = task else { return }
        
        completedButton.setImage((task.complete) ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle"),for: .normal)
        
        do {
            try CoreDataStack.shared.mainContext.save()
        } catch {
            NSLog("Error saving managed object context: \(error)")
        }
    }

    // MARK: - Private
    
    private func updateViews() {
        guard let task = task else { return }
        
        taskNameLabel.text = task.name
        completedButton.setImage((task.complete) ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle"),for: .normal)
    }
}
