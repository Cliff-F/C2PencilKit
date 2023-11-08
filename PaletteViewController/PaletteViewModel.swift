//
//  PaletteViewModel.swift
//  ChildViewController
//
//  Created by Masatoshi Nishikata on 10/08/19.
//  Copyright © 2019 Catalystwo Limited. All rights reserved.
//

import Foundation
import UIKit
import simd

open class PaletteViewModel: NSObject {

  public enum Location: Int {
    case bottom = 0, left, right, top
  }
  
  private struct Key {
    static var selectedPresetUuid = "PaletteViewModel.selectedPresetUuid"
  }
  
  public var fullPresets: [StylusPreset] = []
  public var disabledStyles: [Stylus.Mode] = []
  public var hasUtilityButton = false
  public var showsRuler = false
  public var location: Location = .bottom
  public var includesPencil = false
  @objc dynamic public var presets: [StylusPreset] = []
  @objc dynamic public var selectedPreset: StylusPreset? = nil
  @objc dynamic var displayPopover: Bool = false
  @objc dynamic var isDragging: Bool = false
    
  public init(disabledStyles: [Stylus.Mode] = [], hasUtilityButton: Bool = false, location: Location = .bottom, showsRuler: Bool = false, includesPencil: Bool) {
    self.showsRuler = showsRuler
    self.hasUtilityButton = hasUtilityButton
    self.includesPencil = includesPencil
    let dataArray = UserDefaults.standard.object(forKey: "PaletteViewControllerSavedData") as? [Data]
    var pens: [StylusPreset]? = dataArray?.compactMap {
      guard let preset = StylusPreset(from: $0) else { return nil }
      return preset
    }
    
    
    if pens == nil || pens?.count == 0 {
      
      if includesPencil {
        pens = [
          StylusPreset(mode: .brushPen, color: simd_float4(1,1,0,1), penSize: .xl, name: WLoc("P_UntitledBrush"), brushNumber: 0),
          StylusPreset(mode: .alphaPen, color: simd_float4(0,0,0,1), penSize: .r, name: WLoc("P_Untitled")),
          StylusPreset(mode: .pencil, color: simd_float4(1,0,0,1), penSize: .r, name: WLoc("P_UntitledPencil")),
          
          StylusPreset(mode: .pixEraser, name: WLoc("P_Pix Eraser")),
          StylusPreset(mode: .lasso, name: WLoc("P_Lasso")),
          StylusPreset(mode: .paste, name: WLoc("P_Insert")),
          StylusPreset(mode: .move, name: WLoc("P_Move"))
          
        ]
      }else {
        pens = [
          StylusPreset(mode: .brushPen, color: simd_float4(1,1,0,1), penSize: .xl, name: WLoc("P_UntitledBrush"), brushNumber: 0),
          StylusPreset(mode: .alphaPen, color: simd_float4(0,0,0,1), penSize: .r, name: WLoc("P_Untitled")),
          //        StylusPreset(mode: .pencil, color: simd_float4(0,0,0.8,1), penSize: .r, name: WLoc("P_UntitledPencil")),
          
          StylusPreset(mode: .pixEraser, name: WLoc("P_Pix Eraser")),
          StylusPreset(mode: .lasso, name: WLoc("P_Lasso")),
          StylusPreset(mode: .paste, name: WLoc("P_Insert")),
          StylusPreset(mode: .move, name: WLoc("P_Move"))
          
        ]
      }
      if showsRuler {
        pens?.append( StylusPreset(mode: .ruler, name: WLoc("P_Ruler")) )
      }
    }
    
    if showsRuler &&  pens!.filter( { $0.mode == .ruler } ).count == 0 {
      pens?.append(StylusPreset(mode: .ruler, name: WLoc("P_Ruler")))
    }
    
    self.fullPresets = pens!
    self.location = location
    self.disabledStyles = disabledStyles
    self.presets = pens!.filter {
      return !disabledStyles.contains($0.mode)
    }

    var preset: StylusPreset?
    let stack = UserDefaults.standard.object(forKey: PaletteViewModel.Key.selectedPresetUuid) as? [Data] ?? []
    
    if let presetUuid = stack.first {
      preset = pens!.filter({ $0.uuid == presetUuid }).first
    }
    
    if preset == nil {
      preset = pens!.first
    }
    
    if preset != nil {
      selectedPreset = preset
      Stylus.shared.setPreset(preset!)
    }
    
  }
  
  open func loadPreset(_ dataArray: [Data]) {
    var presets = dataArray.compactMap { StylusPreset(from: $0) }
    
    // ADD IF MISSING ANY
    if presets.filter( { $0.mode == .lasso } ).count == 0 {
      presets.append(StylusPreset(mode: .lasso, name: WLoc("P_Lasso")))
    }
    
    if presets.filter( { $0.mode == .pixEraser ||  $0.mode == .objEraser } ).count == 0 {
      presets.append(StylusPreset(mode: .pixEraser, name: WLoc("P_Pix Eraser")))
    }
    
    if presets.filter( { $0.mode == .paste } ).count == 0 {
      presets.append(StylusPreset(mode: .paste, name: WLoc("P_Insert")))
    }
    
    if presets.filter( { $0.mode == .move } ).count == 0 {
      presets.append(StylusPreset(mode: .move, name: WLoc("P_Move")))
    }
    
    if showsRuler &&  presets.filter( { $0.mode == .ruler } ).count == 0 {
      presets.append(StylusPreset(mode: .ruler, name: WLoc("P_Ruler")))
    }
    
    
    fullPresets = presets
    self.presets = presets.filter {
      return !disabledStyles.contains($0.mode)
    }

    
    var preset: StylusPreset?
    let stack = UserDefaults.standard.object(forKey: PaletteViewModel.Key.selectedPresetUuid) as? [Data] ?? []
    
    if let presetUuid = stack.first {
      preset = presets.filter({ $0.uuid == presetUuid }).first
    }
    
    if preset == nil {
      preset = presets.first
    }
    
    if preset != nil {
      selectedPreset = preset
      Stylus.shared.setPreset(preset!)
    }
    
  }
  
  open func savePresets() -> [Data] {
    let dataArray = presets.compactMap{ $0.saveData() }
    UserDefaults.standard.set(dataArray, forKey: "PaletteViewControllerSavedData")
    return dataArray
  }
  
  func viewFrameForParent(_ parent: UIViewController?) -> CGRect {
    guard let parent = parent else { return .zero }
    let size = parent.view.frame.size
    var standardHeight: CGFloat = 80
    
    if location == .bottom {
      standardHeight += parent.view.safeAreaInsets.bottom
      if hasUtilityButton {
        let width: CGFloat = min(max(300, 20 + 112 + CGFloat(presets.count * 40) + 70), size.width - 20)
        
        let frame = CGRect(x: (size.width - width)/2, y: size.height - standardHeight, width: width, height: standardHeight)
        return frame
        
      }else {
        let width: CGFloat = min(max(300, 112 + CGFloat(presets.count * 40) + 40), size.width - 20)
        
        let frame = CGRect(x: (size.width - width)/2, y: size.height - standardHeight, width: width, height: standardHeight)
        return frame
      }
    }else if location == .top {
      #if targetEnvironment(macCatalyst)
      #else
      standardHeight += parent.view.safeAreaInsets.top
      #endif
      if hasUtilityButton {
        let width: CGFloat = min(max(300, 20 + 112 + CGFloat(presets.count * 40) + 70), size.width - 20)
        
        let frame = CGRect(x: (size.width - width)/2, y: 0, width: width, height: standardHeight)
        return frame
        
      }else {
        let width: CGFloat = min(max(300, 112 + CGFloat(presets.count * 40) + 70), size.width - 20)
        
        let frame = CGRect(x: (size.width - width)/2, y: 0, width: width, height: standardHeight)
        return frame
      }
      
    }else if location == .right {
      if hasUtilityButton {
        let width: CGFloat = min(max(300, 60 + 50 + CGFloat(presets.count * 40) + 70), size.height - 20)
        
        let frame = CGRect(x: size.width - standardHeight, y: (size.height - width)/2, width: standardHeight, height: width)
        return frame
        
      }else {
        let width: CGFloat = min(max(300, 50 + CGFloat(presets.count * 40) + 70), size.height - 20)
        
        let frame = CGRect(x: size.width - standardHeight, y: (size.height - width)/2, width: standardHeight, height: width)
        return frame
      }
    }else {
      if hasUtilityButton {
        let width: CGFloat = min(max(300, 60 + 50 + CGFloat(presets.count * 40) + 70), size.height - 20)
        
        let frame = CGRect(x: 0, y: (size.height - width)/2, width: standardHeight, height: width)
        return frame
        
      }else {
        let width: CGFloat = min(max(300, 50 + CGFloat(presets.count * 40) + 70), size.height - 20)
        
        let frame = CGRect(x: 0, y: (size.height - width)/2, width: standardHeight, height: width)
        return frame
      }
    }
  }
  
  var utilityButtonIsHidden: Bool {
    return !hasUtilityButton
  }
  func clipViewFrameFor(bounds: CGRect, parent: UIViewController) -> CGRect {
    if location == .bottom {
      if hasUtilityButton {
        let frame = CGRect(x: 92, y: -16, width: bounds.size.width - 112 - 30, height: bounds.size.height + 16)
        return frame
      }else {
        let frame = CGRect(x: 92, y: -16, width: bounds.size.width - 95, height: bounds.size.height + 16)
        return frame
      }
      
    }else if location == .top {
      #if targetEnvironment(macCatalyst)
      let topSafeAreaInset: CGFloat = 0
      #else
      let topSafeAreaInset: CGFloat = parent.view.safeAreaInsets.top
      #endif
      if hasUtilityButton {
        let frame = CGRect(x: 92, y: topSafeAreaInset, width: bounds.size.width - 112 - 30, height: bounds.size.height + 16 - topSafeAreaInset)
        return frame
      }else {
        let frame = CGRect(x: 92, y: topSafeAreaInset, width: bounds.size.width - 95, height: bounds.size.height + 16 - topSafeAreaInset)
        return frame
      }
      
    }else if location == .left {
      if hasUtilityButton {
        let frame = CGRect(x: 0, y: 60, width: bounds.size.width + 20, height:  bounds.size.height - 60 - 50 )
        return frame
      }else {
        let frame = CGRect(x: 0, y: 60, width: bounds.size.width + 20, height: bounds.size.height - 50)
        return frame
      }
      
    }else {
      if hasUtilityButton {
        let frame = CGRect(x: -20, y: 60, width: bounds.size.width + 20, height:  bounds.size.height - 60 - 50 )
        return frame
      }else {
        let frame = CGRect(x: -20, y: 60, width: bounds.size.width + 20, height: bounds.size.height - 50)
        return frame
      }
      
    }
    
  }
}


//MARK:- PaletteTabViewSource

@available(iOS 13.4,*)
extension PaletteViewModel: PaletteTabViewSource {
  func presetsForTabView(_: PaletteTabView) -> [StylusPreset] {
    return presets
  }
  
  @objc open func tabViewCanAddNewItem(_ : PaletteTabView) -> Bool {
    return true
  }
  
  func addNewPen(_ mode: Stylus.Mode, select: Bool) {
    let title: String
    if mode == .brushPen {
      title = WLoc("P_UntitledBrush")
    }else if mode == .pencil {
      title = WLoc("P_UntitledPencil")
    }else {
      title = WLoc("P_Untitled")
    }
    
    let preset = StylusPreset(mode: mode, color: SIMD4<Float>(0,0,0,1), penSize: .r, name: title)
    presets.append(preset)
    if select {
      selectedPreset = preset
      Stylus.shared.setPreset(selectedPreset!)
    }
  }
  
  func pushPresetIndexHistory(_ preset: StylusPreset) {
    var stack = UserDefaults.standard.object(forKey: PaletteViewModel.Key.selectedPresetUuid) as? [Data] ?? []
    stack.insert(preset.uuid, at: 0)
    if stack.count > 2 { stack = stack.dropLast() }
    UserDefaults.standard.set(stack, forKey: PaletteViewModel.Key.selectedPresetUuid)
  }
  
  @objc open func popPresetIndexHistory() -> StylusPreset? {
    var stack = UserDefaults.standard.object(forKey: PaletteViewModel.Key.selectedPresetUuid) as? [Data] ?? []
    guard stack.count > 1 else { return nil }
    
    
    guard let presetUuid = stack.last else { return nil }
    stack = stack.dropLast()
    stack.insert(presetUuid, at: 0)
    UserDefaults.standard.set(stack, forKey: PaletteViewModel.Key.selectedPresetUuid)

    return presets.filter({ $0.uuid == presetUuid }).first
  }
  
  @objc open func canDisplayPopover() -> Bool {
    return true
  }
  
  func tabView(_: PaletteTabView, didSelectItemAt index: Int?) -> Bool {
    guard let newIndex = index, presets.count > newIndex else {
      selectedPreset = nil
      return false
    }
    
    if presets[newIndex].mode == .ruler {
      NotificationCenter.default.post(name: Notification.Name(rawValue:  "PaletteViewModelRulerTapped"), object: nil)
     return false
    }
    
    if presets[newIndex] == selectedPreset {
      if canDisplayPopover() {
        displayPopover = true
      }
    }else {
      displayPopover = false
      selectedPreset = presets[newIndex]
      pushPresetIndexHistory(selectedPreset!)
    }
    
    if selectedPreset != nil {
      Stylus.shared.setPreset(selectedPreset!)
    }
    
    return true
  }
  
  func tabView(_: PaletteTabView, willSelectItemAt index: Int?) {
    
  }
  
  func tabViewIndexOfSelection(_: PaletteTabView) -> Int? {
    guard let selectedPreset = selectedPreset else { return nil }
    return presets.firstIndex(of: selectedPreset)
  }
  
  func tabView(_: PaletteTabView, moveItemAt fromIndex: Int, to toIndex: Int) {
    if presets.count <= fromIndex || presets.count <= toIndex {
      return
    }
    
    if fromIndex < toIndex {
      let obj = presets[fromIndex]
      presets.insert(obj, at: toIndex+1)
      presets.remove(at: fromIndex)
      
    }else {
      let obj = presets[fromIndex]
      presets.remove(at: fromIndex)
      presets.insert(obj, at: toIndex)
    }
    
  }
  
  func tabView(_: PaletteTabView, removeItemAt index: Int) -> Bool {
    guard presets.count > index && index >= 0 else { return false }
    let preset = presets[index]

    if preset == selectedPreset { selectedPreset = presets.first }

    presets.remove(at: index)
    return true
  }
  
  @objc open func tabView(_ : PaletteTabView, canDragAt: IndexPath) -> Bool {
   return true
  }
  
  func tabViewDraggingWillStart(_: PaletteTabView) {
    displayPopover = false
    isDragging = true
  }
  
  func tabViewDraggingWillEnd(_: PaletteTabView) {
  }
  
  func tabViewDraggingDidEnd(_: PaletteTabView) {
    isDragging = false
  }
  
  @objc open func tabView(_ : PaletteTabView, canRemoveItemAt indexPath: IndexPath) -> Bool {
    let preset = presets[indexPath.row]
    if preset.mode == .objEraser || preset.mode == .pixEraser || preset.mode == .lasso || preset.mode == .ruler {
      return false
    }
    
    return true
  }
  
}
