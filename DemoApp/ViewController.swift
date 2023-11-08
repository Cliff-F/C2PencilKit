//
//  ViewController.swift
//  ChildViewController
//
//  Created by Masatoshi Nishikata on 8/08/19.
//  Copyright © 2019 Catalystwo Limited. All rights reserved.
//

import UIKit
import simd
import PaletteViewController
#if canImport(PencilKit)
import PencilKit
#endif

class ViewController: UIViewController {
  
  @IBOutlet weak var openButton: UIButton!
  private var paletteViewController: PaletteViewController? = nil
  private var paletteObserver: NSKeyValueObservation?
  private var observerEVent = false
  private weak var canvasView: PKCanvasView?
  private var toolPicker : PKToolPicker?
  
  private var location: PaletteViewModel.Location = .bottom
  private var usesOurPalette = true
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    
    NotificationCenter.default.addObserver(self, selector: #selector(toggleRuler(_:)), name: Notification.Name(rawValue:  "PaletteViewModelRulerTapped"), object: nil)

  }
  
  @IBAction func openCanvas(_ sender: Any) {
    if let paletteViewController = paletteViewController, paletteViewController.view.window != nil {
      paletteViewController.close()
      return
    }
    
    openButton.isHidden = true
    let canvasView = PKCanvasView(frame: view.bounds)
    canvasView.backgroundColor = .clear
    canvasView.isOpaque = false
    canvasView.maximumZoomScale = 2.0
    canvasView.minimumZoomScale = 1
    canvasView.isScrollEnabled = true
    canvasView.bounces = true
    canvasView.bouncesZoom = false
    self.canvasView = canvasView
    view.addSubview(canvasView)
    
    toolPicker = PKToolPicker()
    toolPicker!.setVisible(!usesOurPalette, forFirstResponder: canvasView)
    toolPicker!.addObserver(canvasView)
    if #available(macCatalyst 16.0, *) {
      toolPicker!.addObserver(self)
    }
    canvasView.drawingPolicy = .anyInput
    
    canvasView.becomeFirstResponder()
    
    paletteViewController = getPaletteViewController()
    paletteViewController?.show(in: self)
    Stylus.shared.willChangeValue(forKey: "mode")
    Stylus.shared.didChangeValue(forKey: "mode")
    canvasView.undoManager?.removeAllActions()
  }
  
  func getPaletteViewController() -> PaletteViewController  {
    
    let paletteViewController: PaletteViewController
    paletteViewController = PaletteViewController.viewController(disabledStyles: [.move, .paste], hasUtilityButton: true, location: location, showsToolLabel: false)
    
    self.paletteViewController = paletteViewController
    paletteViewController.delegate = self
    paletteViewController.customUndoManager = canvasView?.undoManager
    paletteViewController.usesAdvancedButton = false
    paletteViewController.convertDarkColor = true
    
    paletteObserver?.invalidate()
    paletteObserver = Stylus.shared.observe(\.mode) { [weak self] object, change in
      
      if self?.observerEVent == true { return }
      if Stylus.shared.mode == .lasso {
        self?.canvasView?.tool = PKLassoTool()
      }else if Stylus.shared.mode == .objEraser {
        self?.canvasView?.tool = PKEraserTool(PKEraserTool.EraserType.vector)
      }else if Stylus.shared.mode == .pixEraser {
        self?.canvasView?.tool = PKEraserTool(PKEraserTool.EraserType.bitmap)
      }else if Stylus.shared.mode == .ruler {
        self?.canvasView?.isRulerActive = !self!.canvasView!.isRulerActive
      }else if Stylus.shared.mode == .alphaPen || Stylus.shared.mode == .brushPen || Stylus.shared.mode == .pencil {
        let penSize = Stylus.shared.penSize
        var width: CGFloat = 10
        
        if Stylus.shared.mode == .brushPen {
          switch penSize {
          case .xs: width = 7.5
          case .s: width = 20.625
          case .r: width = 33.75
          case .l: width = 46.875
          case .xl: width = 60
          default: width = 40
          }
        }
        
        if Stylus.shared.mode == .alphaPen {
          switch penSize {
          case .xs: width = 0.87816
          case .s: width = 2.67994
          case .r: width = 5.26140
          case .l: width = 11.01299
          case .xl: width = 25.65926
          default: width = 40
          }
        }
        
        if Stylus.shared.mode == .pencil {
          switch penSize {
          case .xs: width = 2.4
          case .s: width = 5.8
          case .r: width = 9.2
          case .l: width = 12.6
          case .xl: width = 16
          default: width = 40
          }
        }
        
        
        let color = Stylus.shared.color
        let uiColor = UIColor(red: CGFloat(color[0]), green: CGFloat(color[1]), blue: CGFloat(color[2]), alpha: CGFloat(color[3]))
        
        let style: PKInkingTool.InkType
        if Stylus.shared.mode == .alphaPen {
          style = .pen
        }else if Stylus.shared.mode == .brushPen {
          style = .marker
        }else {
          style = .pencil
        }
        self?.canvasView?.tool = PKInkingTool(style, color: uiColor, width: width)
        
      }
      if let tool = self?.canvasView?.tool {
        self?.observerEVent = true
        self?.toolPicker?.selectedTool = tool
        self?.observerEVent = false
        
      }
    }
    
    return paletteViewController
  }
  
  
  func close() {
    openButton.isHidden = false

    paletteObserver?.invalidate()
    paletteObserver = nil
    paletteViewController?.close()
    
    canvasView?.removeFromSuperview()
    canvasView = nil
    
  }
  
  @objc func toggleRuler(_ : Any) {
    canvasView?.isRulerActive = !canvasView!.isRulerActive
  }
}

@available(iOS 16.0, *)
extension ViewController: PaletteViewControllerDelegate {
  func paletteViewControllerDidSave(_ array: [Data]) {
    
  }
  
  func paletteViewController(_: PaletteViewController, utilityTapped: UIButton) {
    
  }
  
  func paletteViewController(_: PaletteViewController, configureUtilityButton button: UIButton) {
    button.showsMenuAsPrimaryAction = true
    
    let leftItem = UIAction(title: "Left", image: UIImage(systemName: "rectangle.leftthird.inset.fill"), identifier: nil, discoverabilityTitle: nil, state: location == .left ? .on : .off, handler: { [weak self] action in
      self?.setPaletteLocation(.left)
      return
    })
    
    
    let rightItem = UIAction(title: "Right", image: UIImage(systemName: "rectangle.rightthird.inset.fill"), identifier: nil, discoverabilityTitle: nil, state: location == .right ? .on : .off, handler: { [weak self] action in
      self?.setPaletteLocation(.right)
      return
    })
    
    let topItem = UIAction(title: "Top", image: UIImage(systemName: "rectangle.topthird.inset.filled"), identifier: nil, discoverabilityTitle: nil, state: location == .top ? .on : .off, handler: { [weak self] action in
      self?.setPaletteLocation(.top)
      return
    })
    
    let bottomItem = UIAction(title: "Bottom", image: UIImage(systemName: "rectangle.bottomthird.inset.fill"), identifier: nil, discoverabilityTitle: nil, state: location == .bottom ? .on : .off, handler: { [weak self] action in
      self?.setPaletteLocation(.bottom)
      return
    })
    
    let submenu = UIMenu(title: "Location", image: nil, identifier: nil, options: [], children: [topItem, bottomItem,  leftItem, rightItem])

    
    let doneItem = UIAction(title: "Done", image: UIImage(systemName: "checkmark.circle"), identifier: nil, discoverabilityTitle: nil, state: .off, handler: { [weak self] action in
      
      self?.close()
    })
    
    let submenu2 = UIDeferredMenuElement.uncached { [weak self] completion in
      guard let strongSelf = self else { return }
      var actions = [UIMenuElement]()
      
      let item = UIAction(title: "Switch to PKToolPicker", image: UIImage(systemName: "pencil.tip.crop.circle"), identifier: nil, discoverabilityTitle: nil, state: strongSelf.usesOurPalette ? .off : .on , handler: { action in
        
        if strongSelf.usesOurPalette == true {
          strongSelf.toolPicker?.setVisible(true, forFirstResponder: strongSelf.canvasView!)
          strongSelf.usesOurPalette = false
          strongSelf.paletteViewController?.close()
          
        }else {
          strongSelf.toolPicker?.setVisible(false, forFirstResponder: strongSelf.canvasView!)
          strongSelf.usesOurPalette = true
          strongSelf.paletteViewController = strongSelf.getPaletteViewController()
          strongSelf.paletteViewController?.show(in: strongSelf)
          
          strongSelf.toolPickerSelectedToolDidChange(strongSelf.toolPicker!)
        }
        
      })
      
      
      let items = UIMenu(title: "", image: nil, identifier: nil, options: [.displayInline], children: [item])
      
      actions.append(items)
      
      completion(actions)
    }
    
#if targetEnvironment(macCatalyst)
    let children = [doneItem, submenu]
    button.menu = UIMenu(title: "", options: [.displayInline], children: children)
    
#else
    let children = [doneItem, submenu, submenu2]
    button.menu = UIMenu(title: "", options: [.displayInline], children: children)
#endif
  }
  
  func setPaletteLocation(_ location: PaletteViewModel.Location) {
    self.location = location
    paletteViewController?.close()
    paletteViewController = getPaletteViewController()
    paletteViewController?.show(in: self)
    self.setNeedsStatusBarAppearanceUpdate()
  }
  
  
}

@available(iOS 16.0, *)
extension ViewController: PKToolPickerObserver {
  func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
    
  }
  
  /// Delegate method: Note that the tool picker has become visible or hidden.
  func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
    
  }
  
  func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
    guard observerEVent == false else { return }
    guard true == paletteViewController?.isViewLoaded else { return }
    observerEVent = true
    if let tool = toolPicker.selectedTool as? PKEraserTool {
      paletteViewController?.switchObjectEraser(tool.eraserType == .vector)
    }
    
    else if toolPicker.selectedTool is PKLassoTool {
      paletteViewController?.switchLasso()
    }
    
    else {
      paletteViewController?.switchNone()
    }
    
    //    if let tool = toolPicker.selectedTool as? PKEraserTool {
    //      print("tool \(tool.width)")
    //    }
    
    observerEVent = false
  }
}
