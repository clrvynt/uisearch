//
//  ViewController.swift
//  Search
//
//  Created by kalyankrishnamurthi on 3/20/16.
//  Copyright © 2016 KK. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

enum Category : String {
    case ExerciseType = "ExerciseType"
    case Intensity = "Intensity"
    case Mood = "Mood"
    case Location = "Location"
    
    var sortOrder: Int {
        switch self {
        case .ExerciseType:
            return 0
        case .Intensity:
            return 1
        case .Mood:
            return 2
        case .Location:
            return 3
        }
    }
    
    var color: UIColor {
        switch self {
        case .ExerciseType:
            return UIColor.blackColor()
        case .Intensity:
            return UIColor.redColor()
        case .Mood:
            return UIColor.blueColor()
        case .Location:
            return UIColor.brownColor()
        }
    }
}

func ==(left: ExerciseTag, right: ExerciseTag) -> Bool {
    if left.category == right.category {
        return left.name == right.name
    }
    else {
        return false
    }
}

struct ExerciseTag : Equatable, Hashable {
    var category: Category!
    var name: String!
    var hashValue: Int {
        return (category.rawValue + name).hashValue
    }
    
    static var allTags: [ExerciseTag] {
        return [ExerciseTag(category: .ExerciseType, name: "Running"),
            ExerciseTag(category: .ExerciseType, name: "Lifting Weights"),
            ExerciseTag(category: .ExerciseType, name: "Cycling"),
            ExerciseTag(category: .ExerciseType, name: "Skipping Rope"),
            ExerciseTag(category: .ExerciseType, name: "Swimming"),
            ExerciseTag(category: .ExerciseType, name: "Dancing"),
            ExerciseTag(category: .Intensity, name: "Low"),
            ExerciseTag(category: .Intensity, name: "Medium"),
            ExerciseTag(category: .Intensity, name: "High"),
            ExerciseTag(category: .Intensity, name: "Very High"),
            ExerciseTag(category: .Mood, name: "Relaxed"),
            ExerciseTag(category: .Mood, name: "Happy"),
            ExerciseTag(category: .Mood, name: "Sad"),
            ExerciseTag(category: .Mood, name: "Angry"),
            ExerciseTag(category: .Mood, name: "Neutral"),
            ExerciseTag(category: .Location, name: "Home"),
            ExerciseTag(category: .Location, name: "Neighborhood"),
            ExerciseTag(category: .Location, name: "At Work"),
            ExerciseTag(category: .Location, name: "Park")
        ]
    }
    static var randomTag: ExerciseTag {
        return allTags[Int(arc4random_uniform(19))]
    }
}

struct Exercise {
    var duration: Int!
    var date: NSDate!
    var tags: [ExerciseTag] = []
}

class ExerciseRowCell: UITableViewCell {
    @IBOutlet weak var durationLabel:UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
}

class ResultsViewController: UITableViewController {
    
    var resultsList: [Exercise] {
        // Generate a random list of 10 exercises between now and last week with 
        // duration between 10 mins and 100 mins
        let retList: [Exercise] =  (0...9).map { i in
            let randomDuration = Int(arc4random_uniform(91)) + 10
            let randomDate = NSDate().dateByAddingTimeInterval(-(Double(arc4random_uniform(7)) * 86400.0))
            // Generate upto 10 random tags
            let randomTags = (1...10).map { _ in ExerciseTag.randomTag }
            
            let aSet = Array(Set<ExerciseTag>(randomTags))
            return Exercise(duration: randomDuration, date: randomDate, tags: aSet)
            
        }
        return retList.sort { $0.0.date.compare($0.1.date) == .OrderedAscending }
    }
    
    // Used to display the exercise dates in the table headers
    let dateFormat : NSDateFormatter = {
        let df = NSDateFormatter()
        df.dateStyle = NSDateFormatterStyle.ShortStyle
        df.doesRelativeDateFormatting = true
        return df
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsList.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let ex = resultsList[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("exerciseRowCell", forIndexPath: indexPath) as! ExerciseRowCell
        cell.durationLabel.text = "\(ex.duration) minutes"
        let labelAttributedString = NSMutableAttributedString()
        let commaString = NSAttributedString(string: ", ")
        let tags = ex.tags.sort { tag1, tag2 in
            tag1.category.sortOrder > tag2.category.sortOrder
            }.map {
                NSAttributedString(string: $0.name, attributes: [NSForegroundColorAttributeName: $0.category.color])
        }
        for (idx, el) in tags.enumerate() {
            if idx < tags.count - 1 {
                labelAttributedString.appendAttributedString(el)
                labelAttributedString.appendAttributedString(commaString)
            }
            else {
                labelAttributedString.appendAttributedString(el)
            }
        }
        cell.tagsLabel.attributedText = labelAttributedString
        cell.tagsLabel.sizeToFit()
        return cell
    }
}

