//
//  EntryDetailViewController.swift
//  JournalCoreData
//
//  Created by Spencer Curtis on 8/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class EntryDetailViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
    }
    
    @IBAction func saveEntry(_ sender: Any) {
        
        guard let title = titleTextField.text,
            let bodyText = bodyTextView.text else { return }
        
        var mood: String!
        
        switch moodSegmentedControl.selectedSegmentIndex {
        case 0:
            mood = Mood.bad.rawValue
        case 1:
            mood = Mood.neutral.rawValue
        case 2:
            mood = Mood.good.rawValue
        default:
            break
        }
        
        if let entry = entry {
            entryController?.update(entry: entry, title: title, bodyText: bodyText, mood: mood)
        } else {
            entryController?.createEntry(with: title, bodyText: bodyText, mood: mood)
        }
        
        // NEW
        // Ringing the bell
        NotificationCenter.default.post(name: .entryAddedUpdated, object: self)
        
        self.navigationController?.popViewController(animated: true)
    }
    
    private func updateViews() {
        guard let entry = entry,
            isViewLoaded else {
                title = "Create Entry"
                return
        }
        
        title = entry.title
        titleTextField.text = entry.title
        bodyTextView.text = entry.bodyText
        
        var segmentIndex = 0
        
        switch entry.mood {
        case Mood.bad.rawValue:
            segmentIndex = 0
        case Mood.neutral.rawValue:
            segmentIndex = 1
        case Mood.good.rawValue:
            segmentIndex = 2
        default:
            break
        }
        
        moodSegmentedControl.selectedSegmentIndex = segmentIndex
    }
    
    var entry: Entry? {
        didSet {
            updateViews()
        }
    }
    
    var entryController: EntryController?
    
    @IBOutlet weak var moodSegmentedControl: UISegmentedControl!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var bodyTextView: UITextView!
    
//    // MARK: - State Restoration
//      // Doesn't work because I can't change Entry: Encodable to Entry: Codable (this was a bad proj to try to use state restoration in)
//    override func encodeRestorableState(with coder: NSCoder) {
//        super.encodeRestorableState(with: coder)
//
//        // Entry -> Data -> Encode
//        guard let entry = entry else {return}
//        let entryData = try? PropertyListEncoder().encode(entry)
//        coder.encode(entryData, forKey: "entryData")
//    }
//
//    override func decodeRestorableState(with coder: NSCoder) {
//        super.decodeRestorableState(with: coder)
//
//        // Data -> Entry -> set entry variable
//        guard let entryData = coder.decodeObject(forKey: "entryData") as? Data else {return}
//
//        entry = try? PropertyListDecoder().decode(Entry.self, from: entryData)
//
//    }
}
// NEW
extension NSNotification.Name {
    
    static let entryAddedUpdated = NSNotification.Name("entryAdded/Updated")
}
