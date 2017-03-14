//
//  ViewController.swift
//  iShowcaseExample
//
//  Created by Rahul Iyer on 14/10/15.
//  Copyright © 2015 rahuliyer. All rights reserved.
//

import UIKit
import iShowcase

class ViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, iShowcaseDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backgroundColor: UITextField!
    @IBOutlet weak var titleColor: UITextField!
    @IBOutlet weak var detailsColor: UITextField!
    @IBOutlet weak var highlightColor: UITextField!

    let tableData = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
    var showcase: iShowcase!
    var custom: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupShowcase()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        UIView.animate(withDuration: duration, animations: {
            if let showcase = self.showcase {
                showcase.setNeedsLayout()
            }
        })
    }

    @IBAction func barButtonClick(_ sender: UIBarButtonItem) {
        showcase.setupShowcaseForBarButtonItem(sender, title: "Bar Button Example", subtitle: "This example highlights the Bar Button Item")
        showcase.show()
    }

    @IBAction func defaultShowcaseClick(_ sender: UIButton) {
        showcase.setupShowcaseForView(sender, title: "Default", subtitle: "This is default iShowcase with long long long long long long long long text")
        showcase.show()
    }

    @IBAction func multipleShowcaseClick(_ sender: UIButton) {
        defaultShowcaseClick(sender)
    }

    @IBAction func tableViewShowcaseClick(_ sender: UIButton) {
        showcase.setupShowcaseForTableView(tableView, title: "UITableView", subtitle: "This is default position example")
        showcase.show()
    }

    @IBAction func customShowcaseClick(_ sender: UIButton) {
        if backgroundColor.text!.characters.count > 0 {
            showcase.coverColor = UIColor.colorFromHexString(backgroundColor.text!)
        }

        if titleColor.text!.characters.count > 0 {
            showcase.titleLabel.textColor = UIColor.colorFromHexString(titleColor.text!)
        }

        if detailsColor.text!.characters.count > 0 {
            showcase.detailsLabel.textColor = UIColor.colorFromHexString(detailsColor.text!)
        }

        if highlightColor.text!.characters.count > 0 {
            showcase.highlightColor = UIColor.colorFromHexString(highlightColor.text!)
        }

        custom = true
        showcase.type = .circle
        showcase.setupShowcaseForView(sender, title: "Custom", subtitle: "This is custom iShowcase")

        // Uncomment this to show the showcase only once after 1st run
        // showcase.singleShotId = 47
        showcase.show()

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        }
        if let cell = cell {
            cell.textLabel!.text = tableData[(indexPath as NSIndexPath).row]
        }
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showcase.textBackgroundColor = UIColor.gray
        
        showcase.setupShowcaseForTableView(tableView, withIndexPath: indexPath, title: "UITableView", subtitle: "This is sequence example 1")
        showcase.setupShowcaseForTableView(tableView, withIndexPath: indexPath.row > 3 ? IndexPath(row: indexPath.row - 1, section: indexPath.section) : IndexPath(row: indexPath.row + 1, section: indexPath.section), title: "UITableView", subtitle: "This is sequence example 2")
        showcase.show()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    fileprivate func setupShowcase() {
        showcase = iShowcase()
        showcase.delegate = self
    }

    func iShowcaseDismissed(_ showcase: iShowcase) {
        if custom {
            setupShowcase()
            custom = false
        }
    }

}

