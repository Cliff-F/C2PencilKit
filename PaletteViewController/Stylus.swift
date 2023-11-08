//
//  Stylus.swift
//  ChildViewController
//
//  Created by Masatoshi Nishikata on 8/08/19.
//  Copyright © 2019 Catalystwo Limited. All rights reserved.
//

import Foundation
import UIKit
import simd
#if canImport(PencilKit)
import PencilKit
#endif

public class StylusPreset: NSObject {
  public static let maskingBrushNumber = 3
  
  // BASIC
  var mode: Stylus.Mode
  var color: SIMD4<Float>
  var penSize: Stylus.PenSize
  var inkSpeed: Float
  var thickness: Float
  var pressure: Float
  var pressureAlpha: Float
  var initialPressureCutoff: Float
  var ratio: Float = 0
  var name: String = WLoc("Untitled")
  var brushNumber: Int = 0
  var uuid: Data!
  
  // BRUSH PEN
//  var pressureBrush: Bool = false
  var azimuthBrush: Bool = false
  var altitudeBrush: Float = 0

  public override func isEqual(_ object: Any?) -> Bool {
    return uuid == (object as? StylusPreset)?.uuid
  }
  
  static func uuidData() -> Data {
    let tempUuid = UUID()
    var tempUuidBytes = [UInt8](repeating: 0, count: 16)
    (tempUuid as NSUUID).getBytes(&tempUuidBytes)
    let data = NSData(bytes: &tempUuidBytes, length: 16)
    
    return data as Data
  }
  
  public init(mode: Stylus.Mode, color: SIMD4<Float> = simd_float4(1,0,0,1), penSize: Stylus.PenSize = .r, thickness: Float = 0.5, pressure: Float = 0, pressureAlpha: Float = 0, inkSpeed: Float = 0.5, initialPressureCutoff: Float = 0, ratio: Float = 0, azimuthBrush: Bool = false, altitudeBrush: Float = 0, name: String, brushNumber: Int = 0) {
    self.mode = mode
    self.color = color
    self.penSize = penSize
    self.thickness = thickness
    self.pressure = pressure
    self.pressureAlpha = pressureAlpha
    self.inkSpeed = inkSpeed
    self.initialPressureCutoff = initialPressureCutoff
    self.ratio = ratio
    self.azimuthBrush = azimuthBrush
    self.altitudeBrush = altitudeBrush
    self.uuid = StylusPreset.uuidData()
    self.name = name
    self.brushNumber = brushNumber
  }
  
  public func saveData() -> Data? {
    var dict: [String: Any] = [:]
    
    dict["mode"] = mode.rawValue
    dict["color0"] = color[0]
    dict["color1"] = color[1]
    dict["color2"] = color[2]
    dict["color3"] = color[3]

    dict["penSize"] = penSize.rawValue
    dict["inkSpeed"] = inkSpeed
    dict["thickness"] = thickness
    dict["pressure"] = pressure
    dict["pressureAlpha"] = pressureAlpha
    dict["initialPressureCutoff"] = initialPressureCutoff
    dict["ratio"] = ratio
    
    dict["uuid"] = uuid
    dict["name"] = name
    dict["brushNumber"] = brushNumber

    dict["azimuthBrush"] = azimuthBrush
    dict["altitudeBrush"] = altitudeBrush

    let data = try? PropertyListSerialization.data(fromPropertyList: (dict as NSDictionary), format: .binary, options: 0)
    return data
  }
  
  public init?(from data: Data) {
    
    guard let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
     return nil
    }
    
    mode = Stylus.Mode(rawValue: dict["mode"] as? Int ?? 0) ?? .pen
    
    let color0 = dict["color0"] as? Float ?? 0
    let color1 = dict["color1"] as? Float ?? 0
    let color2 = dict["color2"] as? Float ?? 0
    let color3 = dict["color3"] as? Float ?? 0
    color = SIMD4<Float>(color0, color1, color2, color3)
    
    if let penSizeRaw = dict["penSize"] as? Int {
      penSize = Stylus.PenSize(rawValue: penSizeRaw) ?? .r
    }else {
      penSize = .r
    }
    

    inkSpeed = dict["inkSpeed"] as? Float ?? 0
    pressure = dict["pressure"] as? Float ?? 0
    thickness = dict["thickness"] as? Float ?? 0.5
    pressureAlpha = dict["pressureAlpha"] as? Float ?? 0
    initialPressureCutoff = dict["initialPressureCutoff"] as? Float ?? 0
    ratio = dict["ratio"] as? Float ?? 0

    
    uuid = dict["uuid"] as? Data
    name = dict["name"] as? String ?? WLoc("Untitled")
    brushNumber = dict["brushNumber"] as? Int ?? 0

    if mode == .pixEraser {
      name = WLoc("P_Pix Eraser")
    }else if mode == .objEraser {
      name = WLoc("P_Obj Eraser")
    }else if mode == .lasso {
      name = WLoc("P_Lasso")
    }else if mode == .paste {
      name = WLoc("P_Insert")
    }
    
    azimuthBrush = dict["azimuthBrush"] as? Bool ?? false
    altitudeBrush = dict["altitudeBrush"] as? Float ?? 0

    
  }
  
//  func button() -> PalettePenButton {
//    let button1 = PalettePenButton(color: color, mode: mode)
//    return button1
//  }
//
  func image(dark: Bool = false, convertDarkColor: Bool) -> UIImage {
    return penImage(for: color, dark: dark, for: mode, penSize: penSize, convertDarkColor: convertDarkColor)
  }

  func penImage(for fcolor: SIMD4<Float>, dark: Bool = false, for mode: Stylus.Mode, penSize: Stylus.PenSize, convertDarkColor: Bool) -> UIImage {
    var image: UIImage!
    var maskImage: UIImage?
    
    

    var color = UIColor(red: CGFloat(fcolor[0]), green: CGFloat(fcolor[1]), blue: CGFloat(fcolor[2]), alpha: 1)
    
    if #available(iOS 13.4, *) {
      if dark && convertDarkColor {
        color = PKInkingTool.convertColor(color, from: .light, to: .dark)
      }
    }
    
    switch mode {
    case .alphaPen:
      image = UIImage(named:dark ? "pen0dark" : "pen0", in: Bundle(for: Stylus.self), compatibleWith: nil)!
      maskImage = UIImage(named:"pen0mask", in: Bundle(for: Stylus.self), compatibleWith: nil)!.colorizedImage(withTint: color, alpha: 1)
      
    case .brushPen:
      image = UIImage(named:dark ? "pen1dark" : "pen1", in: Bundle(for: Stylus.self), compatibleWith: nil)!
      maskImage = UIImage(named:"pen1mask", in: Bundle(for: Stylus.self), compatibleWith: nil)!.colorizedImage(withTint: color, alpha: 1)
      
    case .pen:
      image = UIImage(named:dark ? "pen1dark" : "pen1", in: Bundle(for: Stylus.self), compatibleWith: nil)!
      maskImage = UIImage(named:"pen1mask", in: Bundle(for: Stylus.self), compatibleWith: nil)!.colorizedImage(withTint: color, alpha: 1)
      
    case .pencil:
      image = UIImage(named:dark ? "pen2dark" : "pen2", in: Bundle(for: Stylus.self), compatibleWith: nil)!
      maskImage = UIImage(named:"pen2mask", in: Bundle(for: Stylus.self), compatibleWith: nil)!.colorizedImage(withTint: color, alpha: 1)
      
    case .pixEraser:
      image = UIImage(named:dark ? "PenPixEraserDark" : "PenPixEraser", in: Bundle(for: Stylus.self), compatibleWith: nil)!
      
    case .objEraser:
      image = UIImage(named:dark ? "PenObjEraserDark" : "PenObjEraser", in: Bundle(for: Stylus.self), compatibleWith: nil)!
      
    case .lasso:
      image = UIImage(named:dark ? "PenLassoDark" : "PenLasso", in: Bundle(for: Stylus.self), compatibleWith: nil)!
      
    case .paste:
      image = UIImage(named:dark ? "PenClipDark" : "PenClip", in: Bundle(for: Stylus.self), compatibleWith: nil)!
      
    case .move:
      image = UIImage(named:dark ? "MoveStickDark" : "MoveStick", in: Bundle(for: Stylus.self), compatibleWith: nil)!

    case .ruler:
      image = UIImage(named:dark ? "RulerDark" : "Ruler", in: Bundle(for: Stylus.self), compatibleWith: nil)!

    }
    
    
    
    
    if mode == .brushPen && brushNumber == StylusPreset.maskingBrushNumber {
      color = UIColor.masking
      image = UIImage(named:dark ? "penMaskDark" : "penMask", in: Bundle(for: Stylus.self), compatibleWith: nil)!
      maskImage = UIImage(named:"pen1mask", in: Bundle(for: Stylus.self), compatibleWith: nil)!.colorizedImage(withTint: color, alpha: 1)

    }

    
    #if os(iOS)
    
    let toolSize = CGSize(width: 40, height: 100)
    UIGraphicsBeginImageContextWithOptions(toolSize, false, 0)
    
    image.draw(in: CGRect(origin: .zero, size: toolSize))
    maskImage?.draw(in: CGRect(origin: .zero, size: toolSize))
    
    if mode == .brushPen || mode == .alphaPen || mode == .pencil {
      
      let maskFront: String
      let maskBackground: String
      
      if mode == .brushPen || mode == .alphaPen {
        maskFront = "PenMaskFront"
        maskBackground = "PenMaskBackground"
      }else {
        maskFront = "PencilMaskFront"
        maskBackground = "PencilMaskBackground"
      }
      
      let barMaskFront = UIImage(named: maskFront, in: Bundle(for: Stylus.self), compatibleWith: nil)!.colorizedImage(withTint: color, alpha: 1)
      let barMaskBG = UIImage(named: maskBackground, in: Bundle(for: Stylus.self), compatibleWith: nil)!
      
      var penHeight: CGFloat = 10
      
      switch penSize {
      case .xs:   penHeight = 2
      case .s:    penHeight = 4
      case .r:  penHeight = 6
      case .l:    penHeight = 9
      case .xl:   penHeight = 12
      }

      barMaskBG.draw(in: CGRect(x: 6.5, y: 56, width: 27, height: penHeight), blendMode: .normal, alpha: 0.8)
      barMaskFront.draw(in: CGRect(x: 6.5, y: 56, width: 27, height: penHeight), blendMode: .normal, alpha: 1)
    }
    if #available(iOS 13.4, *) {
      if fcolor[3] < 1.0 {
        let number = String(Int(fcolor[3] * 100))
        let attr = NSAttributedString(string: number, attributes: [.foregroundColor : UIColor.secondaryLabel, .font: UIFont.systemFont(ofSize: 7)])
        let size = attr.size()
        attr.draw(in: CGRect(x: 7 + 13 - size.width/2, y: 46, width: 26, height: size.height))
      }
    }
    
    let compositedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    #endif
    
    #if os(OSX)
    let compositedImage: NSImage? = NSImage(size: image.size)
    compositedImage?.lockFocus()
    let bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.width)
    image.draw(in: bounds)
    maskImage?.draw(in: bounds)
    
    compositedImage?.unlockFocus()
    
    #endif
    
    return compositedImage!
  }
}

public class Stylus: NSObject {
  public static let xyRatioMax: CGFloat = 6
  public static func thicknessScaleFunction(_ scale: Float) -> Float {
    return round((scale * scale * 3.2 + 0.2) * 10) / 10
  }
  public static var shared = Stylus()
  
  @objc public enum Mode: Int {
    case alphaPen, brushPen, pen, lasso, pixEraser, objEraser, paste, move, pencil, ruler
  }
  
  @objc public enum PenSize: Int {
    case xs, s, r, l, xl
  }
  
  var color_: SIMD4<Float> = SIMD4<Float>(0,0,0,1)
  public var color: SIMD4<Float> {
    get {
      if mode == .brushPen && brushNumber == StylusPreset.maskingBrushNumber {
        return UIColor.maskingFloat
      }
      
      return color_
    }

    set {
      willChangeValue(forKey: "mode")
      color_ = newValue
      didChangeValue(forKey: "mode")
    }
  }
  public var penSize: PenSize = .r {
    willSet {
      willChangeValue(forKey: "mode")
    }
    didSet {
      didChangeValue(forKey: "mode")
    }
  }
  public var inkSpeed: Float = 0
  public var thickness: Float = 0.5
  public var pressure: Float = 0
  public var pressureAlpha: Float = 0
  public var initialPressureCutoff: Float = 0
  public var ratio: Float = 0
  public var azimuthBrush: Bool = false
  public var altitudeBrush: Float = 0
  public var brushNumber: Int = 0
  
  @objc public dynamic var mode: Mode = .pen
  
  public var lineWidth: Float {
    if mode == .brushPen {
      switch penSize {
      
      case .xs:
        return 10 * Stylus.thicknessScaleFunction(thickness)
      case .s:
        return 20 * Stylus.thicknessScaleFunction(thickness)
      case .r:
        return 30 * Stylus.thicknessScaleFunction(thickness)
      case .l:
        return 40 * Stylus.thicknessScaleFunction(thickness)
      case .xl:
        return 50 * Stylus.thicknessScaleFunction(thickness)
      }
    }else {
      switch penSize {
      
      case .xs:
        return 1 * Stylus.thicknessScaleFunction(thickness)
      case .s:
        return 2 * Stylus.thicknessScaleFunction(thickness)
      case .r:
        return 3 * Stylus.thicknessScaleFunction(thickness)
      case .l:
        return 4 * Stylus.thicknessScaleFunction(thickness)
      case .xl:
        return 5 * Stylus.thicknessScaleFunction(thickness)
      }
    }
  }
  
  public func setPreset(_ preset: StylusPreset) {
    
    if preset.mode == .ruler {

      
      return
    }
    
    
    color = preset.color
    penSize = preset.penSize
    inkSpeed = preset.inkSpeed
    pressure = preset.pressure
    pressureAlpha = preset.pressureAlpha
    initialPressureCutoff = preset.initialPressureCutoff
    ratio = preset.ratio
//    pressureBrush = preset.pressureBrush
    azimuthBrush = preset.azimuthBrush
    altitudeBrush = preset.altitudeBrush
    brushNumber = preset.brushNumber
    mode = preset.mode
  }

}


public extension UIImage {
  func colorizedImage(withTint tintColor: UIColor, alpha: CGFloat, glow outerGlow: Bool = false) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
    let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
    let ctx = UIGraphicsGetCurrentContext()
    var t = CGAffineTransform.identity
    t = t.scaledBy(x: 1, y: -1)
    t = t.translatedBy(x: 0, y: -rect.size.height)
    ctx?.concatenate(t)
    ctx?.setAlpha(alpha)
    ctx?.setFillColor(tintColor.cgColor)
    UIRectFill(rect)
    
    ctx?.setAlpha(1.0)
    ctx?.setBlendMode(.destinationIn)
    ctx?.draw(self.cgImage!, in: rect)
    var theImage = UIGraphicsGetImageFromCurrentImageContext()
    
    if outerGlow {
      ctx?.setShadow(offset: CGSize(width: 0, height: 0), blur: 3.0, color: tintColor.cgColor)
      ctx?.setBlendMode(.normal)
      ctx?.setAlpha(0.5)
      ctx?.draw( (theImage?.cgImage!)!, in: rect)
      theImage = UIGraphicsGetImageFromCurrentImageContext()
    }
    UIGraphicsEndImageContext()
    return theImage!
  }
}

public func RGBA(_ r: CGFloat,_ g: CGFloat,_ b: CGFloat,_ a: CGFloat) -> UIColor  {
  return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
}


extension UIColor {
  
  static var masking: UIColor {
    return RGBA( 179, 179, 179, 1 )
  }
  
  static var maskingFloat: SIMD4<Float> {
    return SIMD4<Float>( 179/255, 179/255, 179/255, 1 )
  }
}
