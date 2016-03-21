//
//  ViewController.swift
//  Search
//
//  Created by kk on 3/20/16.
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

extension NSDate {
    func truncated() -> NSDate {
        let truncatedSeconds = Int(self.timeIntervalSince1970 / 86400) * 86400
        return NSDate(timeIntervalSince1970: Double(truncatedSeconds))
    }
}

extension String {
    var stringsSplitByWhitespaceAndQuotes: [(String, Bool)] {
        let pattern = "[^\\s\"]+|\"(.+?)\""
        var range = self.startIndex..<self.endIndex
        var ret: [(String, Bool)] = []
        
        while range.startIndex < range.endIndex {
            if let match = self.rangeOfString(pattern, options:.RegularExpressionSearch, range: range, locale: nil) {
                let tempString = self.substringWithRange(match)
                if tempString.containsString("\"") {
                    ret.append((tempString, true))
                }
                else {
                    ret.append((tempString, false))
                }
                
                range = match.endIndex.advancedBy(1, limit: self.endIndex)..<self.endIndex
            }
            else {
                range = self.endIndex..<self.endIndex
            }
        }
        return ret
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
    
    static var allValues : [Category] {
        return [.ExerciseType, .Intensity, .Mood, .Location]
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

class DateSectionHeaderCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
}

class ExerciseRowCell: UITableViewCell {
    @IBOutlet weak var durationLabel:UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
}

protocol KSearchDelegate: class {
    var searchText: String? { get set }
    func showResultsController()
    func refreshData()
}

class ResultsViewController: UITableViewController, UISearchControllerDelegate, UISearchBarDelegate, KSearchDelegate {
    
    let resultsList: [Exercise] = {
        // Generate a random list of 10 exercises between now and last week with 
        // duration between 10 mins and 100 mins
        let retList: [Exercise] =  (0...9).map { i in
            let randomDuration = Int(arc4random_uniform(91)) + 10
            let randomDate = NSDate().dateByAddingTimeInterval(-(Double(arc4random_uniform(7)) * 86400.0))
            // Generate a few random tags
            let randomTags = (0...Int(arc4random_uniform(15))).map { _ in ExerciseTag.randomTag }
            // Filter to unique
            let aSet = Array(Set<ExerciseTag>(randomTags))
            return Exercise(duration: randomDuration, date: randomDate, tags: aSet)
            
        }
        return retList.sort { $0.0.date.compare($0.1.date) == .OrderedAscending }
    }()
    
    var filteredResultsList: [Exercise] = []
    
    var exerciseByDates: [NSDate: [Exercise]] {
        var dict: [NSDate: [Exercise]] = [:]
        for ex in filteredResultsList {
            let dt = ex.date.truncated()
            if dict.keys.contains(dt) {
                dict[dt] = dict[dt]! + [ex]
            }
            else {
                dict[dt] = [ex]
            }
        }
        return dict
    }
    
    var sortedDates: [NSDate] {
        return exerciseByDates.keys.sort { $0.0.compare($0.1) == .OrderedDescending }
    }
    
    // Used to display the exercise dates in the table headers
    let dateFormat : NSDateFormatter = {
        let df = NSDateFormatter()
        df.dateStyle = NSDateFormatterStyle.ShortStyle
        df.doesRelativeDateFormatting = true
        return df
    }()
    
    var searchController: UISearchController!
    var searchBarShouldBeginEditing = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        let searchResultsController = FilterViewController.instantiateFromStoryboard()
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.text = ""
        searchController.searchResultsUpdater = searchResultsController
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        self.definesPresentationContext = true
        
        searchResultsController.searchDelegate = self
        tableView.tableHeaderView = searchController.searchBar
        
        filteredResultsList = resultsList
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exerciseByDates[sortedDates[section]]!.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sortedDates.count
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("dateRowCell") as! DateSectionHeaderCell
        cell.dateLabel.text = dateFormat.stringFromDate(sortedDates[section])
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let ex = exerciseByDates[sortedDates[indexPath.section]]![indexPath.row]
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
    
    //MARK: KSearchDelegate
    func showResultsController() {
        searchController.searchResultsController?.view.hidden = false
    }
    
    var searchText: String? {
        get {
            return searchController.searchBar.text
        }
        set {
            if var currWords = searchController.searchBar.text?.stringsSplitByWhitespaceAndQuotes where currWords.count > 0 {
                currWords.removeLast()
                currWords.append(("\"\(newValue!)\"", true))
                searchController.searchBar.text = currWords.reduce("") { $0! + " " + $1.0 + " " }
            }
            else {
                searchController.searchBar.text = "\"\(newValue!)\" "
            }
        }
    }
    
    func refreshData() {
        if let wordList = searchController.searchBar.text?.stringsSplitByWhitespaceAndQuotes where wordList.count > 0 {
            let filteredReadings = resultsList.filter { v in
                return  wordList.reduce(false) { (a, s) in
                    a || v.tags.reduce(false) { (acc, tag) in
                        // does the string contain quotes .. then match full string
                        if s.0.containsString("\"") {
                            let tempString = s.0.stringByReplacingOccurrencesOfString("\"", withString: "").lowercaseString
                            return acc || tag.name.lowercaseString == tempString
                        }
                        else {
                            return acc || tag.name.lowercaseString.containsString(s.0.lowercaseString)
                        }
                    }
                }
            }
            filteredResultsList = filteredReadings
        }
        else {
            filteredResultsList = resultsList
        }
        tableView.reloadData()
    }

    //MARK: UISearchBarDelegate
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchBar.isFirstResponder() {
            searchBarShouldBeginEditing = false
        }
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        let ret = searchBarShouldBeginEditing
        searchBarShouldBeginEditing = true
        return ret
    }
}

protocol CategoryDelegate: class {
    func categoryWasChangedToIndex(idx: Int)
}

class CategoryHeaderCell: UITableViewCell {
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var categoryDelegate: CategoryDelegate? = nil
    
    @IBAction func segmentPressed(control: UISegmentedControl) {
        if let delegate = categoryDelegate {
            delegate.categoryWasChangedToIndex(control.selectedSegmentIndex)
        }
    }
}

class FilterViewController: UITableViewController, UISearchResultsUpdating, CategoryDelegate {
    
    var filteredTags: [ExerciseTag] = []
    let tags = ExerciseTag.allTags
    var selectedCategoryIndex = 0
    var searchDelegate: KSearchDelegate? = nil
    
    class func instantiateFromStoryboard() -> FilterViewController {
        let v = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("FilterViewController") as! FilterViewController
        return v
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filteredTags = ExerciseTag.allTags
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        filterContent()
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTags.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("headerCell") as! CategoryHeaderCell
        cell.segmentedControl.removeAllSegments()
        cell.segmentedControl.insertSegmentWithTitle("All", atIndex: 0, animated: false)
        for (idx,cat) in Category.allValues.enumerate() {
            cell.segmentedControl.insertSegmentWithTitle(cat.rawValue, atIndex: (idx + 1), animated: false)
        }
        cell.segmentedControl.selectedSegmentIndex = selectedCategoryIndex
        cell.categoryDelegate = self
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let tag = filteredTags[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("tagCell", forIndexPath: indexPath)
        cell.textLabel?.text = tag.name
        cell.detailTextLabel?.text = tag.category.rawValue
        cell.accessoryType = .None
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tag = filteredTags[indexPath.row]
        searchDelegate?.searchText = tag.name
    }
    
    func filterContent() {
        // Filter by the right most word in search bar ..
        if let searchWords = searchDelegate?.searchText?.stringsSplitByWhitespaceAndQuotes where searchWords.count > 0 {
            filteredTags = tags.filter { tag in
                if selectedCategoryIndex == 0 {
                    return searchWordsInTag(searchWords, tag: tag, condition: true)
                }
                else {
                    return searchWordsInTag(searchWords, tag: tag, condition: (tag.category.sortOrder == selectedCategoryIndex - 1))
                }
            }
        }
        else {
            filteredTags = tags.filter { tag in
                if selectedCategoryIndex == 0 {
                    return true
                }
                else {
                    return tag.category.sortOrder == selectedCategoryIndex - 1
                }
            }
        }
        if let searchDelegate = self.searchDelegate {
            searchDelegate.refreshData()
        }
        tableView.reloadData()
    }
    
    private func searchWordsInTag(words: [(String, Bool)], tag: ExerciseTag, condition: Bool) -> Bool {
        if words.count > 0 {
            let b = words.reduce(false) {
                if $0.1.1 {
                    // This is a quoted string so do an absolute match after stripping the quotes.
                    let temp = $0.1.0.stringByReplacingOccurrencesOfString("\"", withString: "").lowercaseString
                    return $0.0 || (tag.name.lowercaseString == temp)
                }
                else {
                    return $0.0 || tag.name.lowercaseString.containsString($0.1.0.lowercaseString)
                }
            }
            return condition && b
        }
        else {
            return condition
        }
    }

    //MARK: CategoryDelegate
    func categoryWasChangedToIndex(idx: Int) {
        selectedCategoryIndex = idx
        filterContent()
    }
    
    //MARK: UISearchResultsUpdating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let q = searchDelegate?.searchText where !q.isEmpty {
            // do nothing
        }
        else {
            searchDelegate?.showResultsController()
        }
        filterContent()
    }
}



