//
//  ViewController.swift
//  TranslationHelper
//
//  Created by Sean Calkins on 8/16/21.
//

import Cocoa

class ViewController: NSViewController {

    // MARK: - @IBOutlets
    @IBOutlet weak var startDelimiter: NSTextField!
    @IBOutlet weak var endDelimiter: NSTextField!
    @IBOutlet var sourceTextView: NSTextView!
    @IBOutlet var destinationTextView: NSTextView!
    @IBOutlet weak var button: NSButton!
    @IBOutlet weak var formatSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var languagePopup: NSPopUpButton!
    
    // MARK: - Properties
    let iOS = ("\" = \"", "\";")
    let Android = ("\">", "</string>")
    let JSON = ("\": \"","\",")
    let source: SwiftGoogleTranslate.Language = SwiftGoogleTranslate.Language(language: "en", name: "English")
    var target: SwiftGoogleTranslate.Language = SwiftGoogleTranslate.Language(language: "en", name: "English")
    var languages: [SwiftGoogleTranslate.Language] = []
    var delimiters: (String, String) = ("\">", "</string>")
    var itemsToBeTranslated: [String] = []
    var translatedValues: [String] = []
    var currentIndex = 0
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        startDelimiter.isEnabled = false
        endDelimiter.isEnabled = false
        SwiftGoogleTranslate.shared.start(with: "YOUR_API_KEY_HERE")
        languagePopup.removeAllItems()
        fetchLanguages()
    }

    override var representedObject: Any? {
        didSet {
            
        }
    }

    @IBAction func translateTapped(_ sender: NSButtonCell) {
        if formatSegmentedControl.indexOfSelectedItem == 3 {
            delimiters = (startDelimiter.stringValue, endDelimiter.stringValue)
        }
        translateText()
    }
    
    @IBAction func segmemtedControlChanged(_ sender: NSSegmentedCell) {
        switch sender.selectedSegment {
        case 0:
            delimiters = iOS
            startDelimiter.isEnabled = false
            endDelimiter.isEnabled = false
            startDelimiter.stringValue = ""
            endDelimiter.stringValue = ""
        case 1:
            delimiters = Android
            startDelimiter.isEnabled = false
            endDelimiter.isEnabled = false
            startDelimiter.stringValue = ""
            endDelimiter.stringValue = ""
        case 2:
            delimiters = JSON
            startDelimiter.isEnabled = false
            endDelimiter.isEnabled = false
            startDelimiter.stringValue = ""
            endDelimiter.stringValue = ""
        default:
            startDelimiter.isEnabled = true
            endDelimiter.isEnabled = true
        }
    }
    
    @IBAction func itemSelected(_ sender: NSPopUpButton) {
        self.target = languages[sender.indexOfSelectedItem]
    }
    
}

// MARK: - Helper
extension ViewController {
    
    func translateText() {
        button.isEnabled = false
        itemsToBeTranslated = sourceTextView.string.components(separatedBy: delimiters.1)
        print(sourceTextView.string)
        print(itemsToBeTranslated.count)
        print(delimiters)
        translatedValues = []
        currentIndex = 0
        translatePhrases {
            DispatchQueue.main.async {
                self.button.isEnabled = true
                self.destinationTextView.string = self.translatedValues.joined()
            }
        }
    }
    
    func translatePhrases(completion: @escaping () -> ()) {
        if currentIndex == itemsToBeTranslated.count {
            completion()
        } else {
            let item = itemsToBeTranslated[currentIndex]
            print(item)
            guard let phrase = item.components(separatedBy: delimiters.0).last else { return }
            if phrase.replacingOccurrences(of: " ", with: "") == "" || phrase.replacingOccurrences(of: "\n", with: "") == "" {
                currentIndex += 1
                translatePhrases(completion: completion)
            } else {
                translatePhrase(phrase: phrase) { translatedPhrase in
                    if let translatedPhrase = translatedPhrase {
                        let translation = item.replacingOccurrences(of: "\(self.delimiters.0)\(phrase)", with: "\(self.delimiters.0)\(translatedPhrase)")
                        self.translatedValues.append("\(translation)\(self.delimiters.1)")
                        self.currentIndex += 1
                        self.translatePhrases(completion: completion)
                    }
                }
            }
        }
    }
    
    func doThing(phrase: String, completion: @escaping (String?) -> ()) {
        translatePhrase(phrase: phrase, completion: completion)
    }
    
    
}

// MARK: - Web Requests
extension ViewController {
    
    func fetchLanguages() {
        SwiftGoogleTranslate.shared.languages { languages, error in
            self.languages = languages ?? []
            let languageTitles = self.languages.map { "\($0.name) (\($0.language))" }
            if let language = self.languages.first {
                self.target = language
            }
            DispatchQueue.main.async {
                self.languagePopup.addItems(withTitles: languageTitles)
            }
        }
    }
    
    func translatePhrase(phrase: String, completion: @escaping (String?) -> ()) {
        if phrase.replacingOccurrences(of: " ", with: "") == "" || phrase.replacingOccurrences(of: "\n", with: "") == "" {
            completion(nil)
        }
        SwiftGoogleTranslate.shared.translate(phrase, target.language, source.language) { translatedPhrase, error in
            completion(translatedPhrase)
        }
    }
   
}
