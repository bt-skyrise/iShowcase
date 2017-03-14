//
//  iShowcase.swift
//  iShowcase
//
//  Created by Rahul Iyer on 12/10/15.
//  Modified by Konrad Roj on 01/03/17.
//
//  Copyright © 2015 rahuliyer. All rights reserved.
//

import UIKit
import Foundation

@objc public protocol iShowcaseDelegate: NSObjectProtocol {
    /**
     Called when the showcase is displayed
     
     - showcase: The instance of the showcase displayed
     */
    @objc optional func iShowcaseShown(_ showcase: iShowcase)
    /**
     Called when the showcase is removed from the view
     
     - showcase: The instance of the showcase removed
     */
    @objc optional func iShowcaseDismissed(_ showcase: iShowcase)
    /**
     Called when the showcase is canceled
     
     - showcase: The instance of the showcase
     */
    @objc optional func iShowcaseCancelled(_ showcase: iShowcase)
    /**
     Called when the next showcase is shown
     
     - showcase: The instance of the showcase
     */
    @objc optional func iShowcaseNextCaseShown(_ showcase: iShowcase, currentTipNumber: Int)
}

@objc open class iShowcase: UIView {
    // MARK: Properties
    
    /// Label to show the title of the showcase
    open var titleLabel: UILabel!
    /// Label to show the description of the showcase
    open var detailsLabel: UILabel!
    /// Background of labels
    open var textBackgroundView: UIView!
    /// Label to show the title of the showcase
    open var closeButton: UIButton!
    /// Background of labels
    open var counter: UIPageControl!
    /// Color of the background for the showcase. Default is black
    open var coverColor: UIColor!
    /// Alpha of the background of the showcase. Default is 0.75
    open var coverAlpha: CGFloat!
    /// Color of the showcase highlight. Default is #1397C5
    open var highlightColor: UIColor!
    /// Color of the labels background.
    open var textBackgroundColor: UIColor?
    /// Inner showcase radius
    open var innerShowcaseRadius: CGFloat = 1.0
    /// Outer showcase radius
    open var outerShowcaseRadius: CGFloat = 4.0
    /// Type of the showcase to be created. Default is Rectangle
    open var type: TYPE!
    /// Radius of the circle with iShowcase type Circle. Default radius is 25
    open var radius: Float!
    /// Single Shot ID for iShowcase
    open var singleShotId: Int64!
    /// Delegate for handling iShowcase callbacks
    open var delegate: iShowcaseDelegate?
    
    /**
     Type of the highlight for the showcase
     
     - CIRCLE:    Creates a circular highlight around the view
     - RECTANGLE: Creates a rectangular highligh around the view
     */
    @objc public enum TYPE: Int {
        case circle = 0
        case rectangle = 1
    }
    
    fileprivate enum REGION: Int {
        case top = 0
        case left = 1
        case bottom = 2
        case right = 3
        
        static func regionFromInt(_ region: Int) -> REGION {
            switch region {
            case 0:
                return .top
            case 1:
                return .left
            case 2:
                return .bottom
            case 3:
                return .right
            default:
                return .top
            }
        }
    }
    
    fileprivate var containerView: UIView!
    fileprivate var showcaseRect: CGRect!
    fileprivate var region: REGION!
    fileprivate var targetViews = [UIView]()
    fileprivate var titles = [String]()
    fileprivate var subtitles = [String]()
    fileprivate var showcaseImageView: UIImageView!
    fileprivate var lastPoint = CGPoint(x: 0, y: 0)
    
    fileprivate var numberOfTips = 0
    fileprivate var currentTip = 0
    
    // MARK: Initialize
    
    /**
     Initialize an instance of iShowcae
     */
    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        setup()
    }
    
    /**
     This method is not supported
     */
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Public
    
    /**
     Position the views on the screen for display
     */
    open override func layoutSubviews() {
        super.layoutSubviews()
        if showcaseImageView != nil {
            recycleViews()
        }
        
        if let view = targetViews.first {
            showcaseRect = view.convert(view.bounds, to: containerView)
            draw()
            
            addSubview(showcaseImageView)
            addSubview(textBackgroundView)
            addSubview(counter)
            addSubview(titleLabel)
            
            titleLabel.text = titles.first
            addSubview(detailsLabel)
            detailsLabel.text = subtitles.first
            addSubview(closeButton)
            closeButton.addTarget(self, action: #selector(pressCloseButton(button:)), for: .touchUpInside)
        }
        
        addGestureRecognizer(getGestureRecgonizer())
    }
    
    /**
     Close button action
     */
    func pressCloseButton(button: UIButton) {
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.alpha = 0
        }, completion: { (_) -> Void in
            for view in self.containerView.subviews {
                view.isUserInteractionEnabled = true
            }
            self.recycleViews()
            self.removeFromSuperview()
            
            if let delegate = self.delegate {
                if delegate.responds(to: #selector(iShowcaseDelegate.iShowcaseCancelled(_:))) {
                    delegate.iShowcaseCancelled!(self)
                }
            }
        })
    }
    
    /**
     Setup the showcase for a view
     
     - parameter view:    The view to be highlighted
     */
    open func setupShowcaseForView(_ view: UIView, title: String, subtitle: String) {
        targetViews.append(view)
        titles.append(title)
        subtitles.append(subtitle)
        if targetViews.count == 1 {
            setupShowcaseForLocation(view.convert(view.bounds, to: containerView))
            titleLabel.text = title
            detailsLabel.text = subtitle
        }
        
        numberOfTips = numberOfTips + 1
    }
    
    /**
     Setup showcase for the item at 1st position (0th index) of the table
     
     - parameter tableView: Table whose item is to be highlighted
     */
    open func setupShowcaseForTableView(_ tableView: UITableView, title: String, subtitle: String) {
        setupShowcaseForTableView(tableView, withIndexOfItem: 0, andSectionOfItem: 0, title: title, subtitle: subtitle)
    }
    
    /**
     Setup showcase for the item at the given indexpath
     
     - parameter tableView: Table whose item is to be highlighted
     - parameter indexPath: IndexPath of the item to be highlighted
     */
    open func setupShowcaseForTableView(_ tableView: UITableView, withIndexPath indexPath: IndexPath, title: String, subtitle: String) {
        setupShowcaseForTableView(tableView, withIndexOfItem: (indexPath as NSIndexPath).row, andSectionOfItem: (indexPath as NSIndexPath).section, title: title, subtitle: subtitle)
    }
    
    /**
     Setup showcase for the item at the given index in the given section of the table
     
     - parameter tableView: Table whose item is to be highlighted
     - parameter row:       Index of the item to be highlighted
     - parameter section:   Section of the item to be highlighted
     */
    open func setupShowcaseForTableView(_ tableView: UITableView, withIndexOfItem row: Int, andSectionOfItem section: Int, title:String, subtitle: String) {
        let indexPath = IndexPath(row: row, section: section)
        
        titles.append(title)
        subtitles.append(subtitle)
        
        if let view = tableView.cellForRow(at: indexPath) {
            targetViews.append(view)
        }
        
        if targetViews.count == 1 {
            setupShowcaseForLocation(tableView.convert(tableView.rectForRow(at: indexPath), to: containerView))
            titleLabel.text = title
            detailsLabel.text = subtitle
        }
        
        numberOfTips = numberOfTips + 1
    }
    
    /**
     Setup showcase for the Bar Button in the Navigation Bar
     
     - parameter barButtonItem: Bar button to be highlighted
     */
    open func setupShowcaseForBarButtonItem(_ barButtonItem: UIBarButtonItem, title: String, subtitle: String) {
        setupShowcaseForView(barButtonItem.value(forKey: "view") as! UIView, title: title, subtitle: subtitle)
    }
    
    /**
     Setup showcase to highlight a particular location on the screen
     
     - parameter location: Location to be highlighted
     */
    open func setupShowcaseForLocation(_ location: CGRect) {
        showcaseRect = location
    }
    
    /**
     Display the iShowcase
     */
    open func show() {
        if singleShotId != -1 && UserDefaults.standard.bool(forKey: String(format: "iShowcase-%ld", singleShotId)) {
            return
        }
        
        self.alpha = 1
        for view in containerView.subviews {
            view.isUserInteractionEnabled = false
        }
        
        UIView.transition(with: containerView, duration: 0.5, animations: { () -> Void in
            self.containerView.addSubview(self)
        }) { (_) -> Void in
            if let delegate = self.delegate {
                if delegate.responds(to: #selector(iShowcaseDelegate.iShowcaseShown)) {
                    delegate.iShowcaseShown!(self)
                }
            }
        }
    }
    
    // MARK: Private
    
    fileprivate func setup() {
        self.backgroundColor = UIColor.clear
        containerView = UIApplication.shared.delegate!.window!
        coverColor = UIColor.black
        highlightColor = UIColor.colorFromHexString("#1397C5")
        coverAlpha = 0.75
        type = .rectangle
        radius = 25
        singleShotId = -1
        
        // Setup title label defaults
        titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        titleLabel.numberOfLines = 0
        
        // Setup details label defaults
        detailsLabel = UILabel()
        detailsLabel.font = UIFont.systemFont(ofSize: 16)
        detailsLabel.textColor = UIColor.white
        detailsLabel.textAlignment = .center
        detailsLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        detailsLabel.numberOfLines = 0
        
        // Setup label background
        textBackgroundView = UIView()
        
        // Setup page control defaults
        counter = UIPageControl()
        counter.currentPageIndicatorTintColor = UIColor.white
        counter.pageIndicatorTintColor = UIColor.darkGray
        
        // Setup close button defaults
        closeButton = UIButton()
        closeButton.setTitle("X", for: .normal)
        closeButton.setTitleColor(UIColor.white, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
    }
    
    fileprivate func draw() {
        setupBackground()
        calculateRegion()
        setupText()
    }
    
    fileprivate func setupBackground() {
        UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size,
                                               false, UIScreen.main.scale)
        var context: CGContext? = UIGraphicsGetCurrentContext()
        context?.setFillColor(coverColor.cgColor)
        context?.fill(containerView.bounds)
        
        if type == .rectangle {
            if let showcaseRect = showcaseRect {
                
                // Outer highlight
                let highlightRect = CGRect(
                    x: showcaseRect.origin.x - 15,
                    y: showcaseRect.origin.y - 15,
                    width: showcaseRect.size.width + 30,
                    height: showcaseRect.size.height + 30)
                
                context?.setShadow(offset: CGSize.zero, blur: 10, color: highlightColor.cgColor)
                context?.setFillColor(coverColor.cgColor)
                context?.setStrokeColor(highlightColor.cgColor)
                context?.setLineWidth(3)
                context?.addPath(UIBezierPath(roundedRect: highlightRect, cornerRadius: outerShowcaseRadius).cgPath)
                context?.drawPath(using: .fillStroke)
                
                // Inner highlight
                context?.setLineWidth(3)
                context?.addPath(UIBezierPath(roundedRect: showcaseRect, cornerRadius: innerShowcaseRadius).cgPath)
                context?.drawPath(using: .fillStroke)
                
                let showcase = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                // Clear region
                UIGraphicsBeginImageContext((showcase?.size)!)
                showcase?.draw(at: CGPoint.zero)
                context = UIGraphicsGetCurrentContext()
                context?.clear(showcaseRect)
            }
        } else {
            if let showcaseRect = showcaseRect {
                let center = CGPoint(
                    x: showcaseRect.origin.x + showcaseRect.size.width / 2.0,
                    y: showcaseRect.origin.y + showcaseRect.size.height / 2.0)
                
                // Draw highlight
                context?.setLineWidth(2.54)
                context?.setShadow(offset: CGSize.zero, blur: 10, color: highlightColor.cgColor)
                context?.setFillColor(coverColor.cgColor)
                context?.setStrokeColor(highlightColor.cgColor)
                context?.addArc(center: center, radius: CGFloat(radius * 2), startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: false)
                context?.drawPath(using: .fillStroke)
                context?.addArc(center: center, radius: CGFloat(radius), startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: false)
                context?.drawPath(using: .fillStroke)
                
                // Clear circle
                context?.setFillColor(UIColor.clear.cgColor)
                context?.setBlendMode(.clear)
                context?.addArc(center: center, radius: CGFloat(radius - 0.54), startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: false)
                context?.drawPath(using: .fill)
                context?.setBlendMode(.normal)
            }
        }
        showcaseImageView = UIImageView(image: UIGraphicsGetImageFromCurrentImageContext())
        showcaseImageView.alpha = coverAlpha
        UIGraphicsEndImageContext()
    }
    
    fileprivate func calculateRegion() {
        let left = showcaseRect.origin.x,
        right = showcaseRect.origin.x + showcaseRect.size.width,
        top = showcaseRect.origin.y,
        bottom = showcaseRect.origin.y + showcaseRect.size.height
        
        let areas = [
            top * UIScreen.main.bounds.size.width, // Top region
            left * UIScreen.main.bounds.size.height, // Left region
            (UIScreen.main.bounds.size.height - bottom)
                * UIScreen.main.bounds.size.width, // Bottom region
            (UIScreen.main.bounds.size.width - right)
                - UIScreen.main.bounds.size.height // Right region
        ]
        
        var largestIndex = 0
        for i in 0..<areas.count {
            if areas[i] > areas[largestIndex] {
                largestIndex = i
            }
        }
        region = REGION.regionFromInt(largestIndex)
    }
    
    fileprivate func setupText() {
        titleLabel.frame = containerView.frame
        detailsLabel.frame = containerView.frame
        
        titleLabel.sizeToFit()
        detailsLabel.sizeToFit()
        
        let textPosition = getBestPositionOfTitle(
            withTitleSize: titleLabel.bounds.size,
            withDetailsSize: detailsLabel.bounds.size)
        
        if region == .bottom {
            detailsLabel.frame = textPosition.0
            titleLabel.frame = textPosition.1
        } else {
            titleLabel.frame = textPosition.0
            detailsLabel.frame = textPosition.1
        }
        
        titleLabel.frame = CGRect(
            x: containerView.bounds.size.width / 2.0 - titleLabel.frame.size.width / 2.0,
            y: titleLabel.frame.origin.y,
            width: titleLabel.frame.size.width - (region == .left || region == .right
                ? showcaseRect.size.width
                : 0),
            height: titleLabel.frame.size.height)
        titleLabel.sizeToFit()
        
        detailsLabel.frame = CGRect(
            x: containerView.bounds.size.width / 2.0 - detailsLabel.frame.size.width / 2.0,
            y: detailsLabel.frame.origin.y + titleLabel.frame.size.height / 2,
            width: detailsLabel.frame.size.width - (region == .left || region == .right
                ? showcaseRect.size.width
                : 0),
            height: detailsLabel.frame.size.height)
        detailsLabel.sizeToFit()
        
        var shouldAnimate = false
        if textBackgroundColor != nil {
            let topLeft = CGPoint(x: titleLabel.frame.origin.x < detailsLabel.frame.origin.x ? titleLabel.frame.origin.x : detailsLabel.frame.origin.x, y: titleLabel.frame.origin.y < detailsLabel.frame.origin.y ? titleLabel.frame.origin.y : detailsLabel.frame.origin.y)
            
            shouldAnimate = topLeft.y != lastPoint.y
            if shouldAnimate {
                UIView.animate(withDuration: 0.4, animations: {
                    self.textBackgroundView.alpha = 0.0
                    self.titleLabel.alpha = 0.0
                    self.detailsLabel.alpha = 0.0
                    self.counter.alpha = 0.0
                    self.closeButton.alpha = 0.0
                })
            }
            
            let width = titleLabel.frame.size.width > detailsLabel.frame.size.width ? titleLabel.frame.size.width : detailsLabel.frame.size.width
            
            let height = titleLabel.frame.size.height + detailsLabel.frame.origin.y > detailsLabel.frame.size.height + titleLabel.frame.origin.y ? titleLabel.frame.size.height + detailsLabel.frame.origin.y - topLeft.y : detailsLabel.frame.size.height + titleLabel.frame.origin.y - topLeft.y
            
            let textsFrame = CGRect(x: topLeft.x - 16, y: topLeft.y - 16, width: width + 32, height: height + 32)
            
            textBackgroundView.frame = textsFrame
            textBackgroundView.backgroundColor = textBackgroundColor
            textBackgroundView.layer.cornerRadius = 4.0
            
            counter.frame = CGRect(x: Int(topLeft.x - 16), y: Int(textsFrame.origin.y + height + 32 - 20), width: Int(textsFrame.size.width), height: 20)
            counter.currentPage = self.currentTip
            counter.numberOfPages = self.numberOfTips
            
            closeButton.frame = CGRect(x: topLeft.x + textsFrame.size.width - 40, y: textsFrame.origin.y, width: 25, height: 25)
            
            lastPoint = topLeft
        } else {
            closeButton.frame = CGRect(x: self.frame.size.width - 40, y: 10, width: 40, height: 40)
        }
        
        if shouldAnimate {
            self.textBackgroundView.alpha = 0.0
            self.titleLabel.alpha = 0.0
            self.detailsLabel.alpha = 0.0
            self.counter.alpha = 0.0
            self.closeButton.alpha = 0.0
            
            UIView.animate(withDuration: 0.3, delay: 0.3, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
                self.textBackgroundView.alpha = 1.0
                self.titleLabel.alpha = 1.0
                self.detailsLabel.alpha = 1.0
                self.counter.alpha = 1.0
                self.closeButton.alpha = 1.0
            }) { (completion) in }
        }
    }
    
    fileprivate func getBestPositionOfTitle(withTitleSize titleSize: CGSize,
                                            withDetailsSize detailsSize: CGSize) -> (CGRect, CGRect) {
        var rect0 = CGRect(), rect1 = CGRect()
        if let region = self.region {
            switch region {
            case .top:
                rect0 = CGRect(
                    x: containerView.bounds.size.width / 2.0 - titleSize.width / 2.0,
                    y: titleSize.height + 20,
                    width: titleSize.width,
                    height: titleSize.height)
                rect1 = CGRect(
                    x: containerView.bounds.size.width / 2.0 - detailsSize.width / 2.0,
                    y: rect0.origin.y + rect0.size.height + detailsSize.height / 2.0,
                    width: detailsSize.width,
                    height: detailsSize.height)
                break
            case .left:
                rect0 = CGRect(
                    x: 0,
                    y: containerView.bounds.size.height / 2.0,
                    width: titleSize.width,
                    height: titleSize.height)
                rect1 = CGRect(
                    x: 0,
                    y: rect0.origin.y + rect0.size.height + detailsSize.height / 2.0,
                    width: detailsSize.width,
                    height: detailsSize.height)
                break
            case .bottom:
                rect0 = CGRect(
                    x: containerView.bounds.size.width / 2.0 - detailsSize.width / 2.0,
                    y: containerView.bounds.size.height - detailsSize.height * 2.0 - 24,
                    width: detailsSize.width,
                    height: detailsSize.height)
                rect1 = CGRect(
                    x: containerView.bounds.size.width / 2.0 - titleSize.width / 2.0,
                    y: rect0.origin.y - rect0.size.height - titleSize.height / 2.0,
                    width: titleSize.width,
                    height: titleSize.height)
                break
            case .right:
                rect0 = CGRect(
                    x: containerView.bounds.size.width - titleSize.width,
                    y: containerView.bounds.size.height / 2.0,
                    width: titleSize.width,
                    height: titleSize.height)
                rect1 = CGRect(
                    x: containerView.bounds.size.width - detailsSize.width,
                    y: rect0.origin.y + rect0.size.height + detailsSize.height / 2.0,
                    width: detailsSize.width,
                    height: detailsSize.height)
                break
            }
        }
        
        return (rect0, rect1)
    }
    
    fileprivate func getGestureRecgonizer() -> UIGestureRecognizer {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(showcaseTapped))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        return singleTap
    }
    
    internal func showcaseTapped() {
        if !targetViews.isEmpty {
            targetViews.removeFirst()
            titles.removeFirst()
            subtitles.removeFirst()
        }
        
        if targetViews.isEmpty {
            UIView.animate(withDuration: 0.35, animations: { () -> Void in
                self.alpha = 0
            }, completion: { (_) -> Void in
                self.onAnimationComplete()
            })
        } else {
            UIView.transition(with: containerView, duration: 0.35, options: UIViewAnimationOptions.transitionCrossDissolve, animations: { () -> Void in
                let view = self.targetViews.first!
                self.setupShowcaseForLocation(view.convert(view.bounds, to: self.containerView))
                self.layoutSubviews()
                self.containerView.addSubview(self)
                
                self.currentTip = self.currentTip + 1
            }) { (_) -> Void in
                if let delegate = self.delegate {
                    if delegate.responds(to: #selector(iShowcaseDelegate.iShowcaseNextCaseShown(_:currentTipNumber:))) {
                        delegate.iShowcaseNextCaseShown!(self, currentTipNumber: self.currentTip)
                    }
                }
            }
        }
    }
    
    fileprivate func onAnimationComplete() {
        if singleShotId != -1 {
            UserDefaults.standard.set(true, forKey: String(
                format: "iShowcase-%ld", singleShotId))
            singleShotId = -1
        }
        for view in self.containerView.subviews {
            view.isUserInteractionEnabled = true
        }
        recycleViews()
        self.removeFromSuperview()
        if let delegate = delegate {
            if delegate.responds(to: #selector(iShowcaseDelegate.iShowcaseDismissed)) {
                delegate.iShowcaseDismissed!(self)
            }
        }
    }
    
    fileprivate func recycleViews() {
        if showcaseImageView != nil {
            showcaseImageView.removeFromSuperview()
        }
        
        if titleLabel != nil {
            titleLabel.removeFromSuperview()
        }
        
        if detailsLabel != nil {
            detailsLabel.removeFromSuperview()
        }
        
        if textBackgroundView != nil {
            textBackgroundView.removeFromSuperview()
        }
        
        if counter != nil {
            counter.removeFromSuperview()
        }
        
        if closeButton != nil {
            closeButton.removeFromSuperview()
        }
    }
    
}

// MARK: UIColor extension

public extension UIColor {
    
    /**
     Parse a hex string for its `ARGB` components and return a `UIColor` instance
     
     - parameter colorString: A string representing the color hex to be parsed
     - returns: A UIColor instance containing the parsed color
     */
    public static func colorFromHexString(_ colorString: String) -> UIColor {
        let hex = colorString.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return UIColor.clear
        }
        return UIColor(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255)
    }
}
