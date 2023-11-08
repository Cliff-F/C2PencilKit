//
//  PalletteTabVerticalTextLabel.swift
//  PaletteViewController
//
//  Created by Masatoshi Nishikata on 14/08/23.
//  Copyright © 2023 Catalystwo Limited. All rights reserved.
//

import Foundation
import UIKit

class PalletteTabVerticalTextLabel: UIView {
  var selected: Bool = false
  var highlighted: Bool = false
  var attributedString: NSAttributedString? {
    didSet {
      if line != nil {
        line = nil
      }
      setNeedsDisplay()
    }
  }
  var MARGIN = 7.0
  var highlightedAttributedString: NSAttributedString?
  var contentWidth: CGFloat
  var onRight: Bool
  var inverted: Bool
  var alignCenter: Bool
  var alignCenterInsideFrame: Bool
  var hasShadow: Bool
  var shadowOffset: CGSize
  var shadowBlur: CGFloat
  var shadowColor: UIColor?
  
  private var line: CTLine?
  
  override init(frame: CGRect) {
    contentWidth = frame.size.width
    onRight = false
    inverted = false
    alignCenter = false
    alignCenterInsideFrame = false
    hasShadow = false
    shadowOffset = CGSize(width: 0, height: 1)
    shadowBlur = 3.0
    shadowColor = nil
    
    super.init(frame: frame)
    
    backgroundColor = .clear
    contentMode = .redraw
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var frame: CGRect {
    didSet {
      contentWidth = frame.size.width
      setNeedsDisplay()
    }
  }
  
  var lineRef: CTLine? {
    return line
  }
  
  func width() -> CGFloat {
    if line == nil, let attributedString = attributedString {
      line = CTLineCreateWithAttributedString(attributedString as CFAttributedString)
    }
    
    var width = CTLineGetTypographicBounds(line!, nil, nil, nil)
    if inverted {
      width += 20
    }
    
    return width
  }
  
  func textRect() -> CGRect {
    if line == nil, let attributedString = attributedString {
      line = CTLineCreateWithAttributedString(attributedString as CFAttributedString)
    }
    
    var rect = bounds
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    CTLineGetTypographicBounds(line!, &ascent, &descent, &leading)
    
    let ty = round((rect.size.height - descent - ascent) / 2 + ascent) + 2
    var width: CGFloat = 0
    var height = ascent
    height += 10
    
    CTLineGetTypographicBounds(line!, &ascent, &descent, &leading)
    width = CTLineGetTypographicBounds(line!, &ascent, &descent, &leading)
    var contentRect = CGRect(x: (rect.size.width - width) / 2, y: ty - height + 5, width: width, height: height)
    contentRect = contentRect.integral
    
    return contentRect
  }
  
  override func draw(_ rect: CGRect) {
    if line == nil, let attributedString = attributedString {
      let mattr = NSMutableAttributedString(attributedString: attributedString)
      line = CTLineCreateWithAttributedString(mattr as CFAttributedString)
      var width = CTLineGetTypographicBounds(line!, nil, nil, nil)
      
      if rect.size.height < width + MARGIN && mattr.length > 2 {
        var attributes = mattr.attributes(at: 0, effectiveRange: nil)
        if let font = attributes[NSAttributedString.Key.font] as? UIFont {
          let newFont = UIFont(name: font.fontName, size: font.pointSize - 2)
          attributes[NSAttributedString.Key.font] = newFont
          attributes[NSAttributedString.Key.kern] = -1
          mattr.addAttributes(attributes, range: NSRange(location: 0, length: mattr.length))
          line = nil
          line = CTLineCreateWithAttributedString(mattr as CFAttributedString)
          width = CTLineGetTypographicBounds(line!, nil, nil, nil)
        }
      }
      
      while rect.size.height < width + MARGIN && mattr.length > 5 {
        let attributes = mattr.attributes(at: mattr.length - 2, effectiveRange: nil)
        mattr.replaceCharacters(in: NSRange(location: mattr.length - 4, length: 2), with: "︙")
        mattr.addAttributes(attributes, range: NSRange(location: mattr.length - 2, length: 1))
        line = nil
        line = CTLineCreateWithAttributedString(mattr as CFAttributedString)
        width = CTLineGetTypographicBounds(line!, nil, nil, nil)
      }
    }
    
    guard let attributedString = attributedString, let line = line, attributedString.length > 0 else {
      super.draw(rect)
      return
    }
    
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    var width: Double = 0
    
    width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
    
    guard let ctx = UIGraphicsGetCurrentContext() else {
      return
    }
    
    ctx.saveGState()
    
    var transform = CGAffineTransform(scaleX: 1, y: -1)
    transform = transform.translatedBy(x: 0, y: 0)
    ctx.textMatrix = transform
    
    var t = CGAffineTransform()
    
    if alignCenter {
      t = CGAffineTransform(translationX: rect.size.width - 22, y: MARGIN)
    } else {
      t = CGAffineTransform(translationX: 12, y: MARGIN)
    }
    
    ctx.concatenate(t)
    
    let runs = CTLineGetGlyphRuns(line) as! [CTRun]
    for run in runs {
      CTRunDraw(run, ctx, CFRangeMake(0, 0))
    }
    
    ctx.restoreGState()
  }
}
