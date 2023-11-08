//
//  PaletteViewController.swift
//  ChildViewController
//
//  Created by Masatoshi Nishikata on 8/08/19.
//  Copyright © 2019 Catalystwo Limited. All rights reserved.
//

import UIKit
import simd

func WLoc( _ title: String) -> String {
  return NSLocalizedString(title, tableName: nil, bundle: Bundle(identifier: "com.catalystwo.MetalProject.PaletteViewController")!, value: "", comment: "")
}

class PaletteBackgroundView: UIImageView {
  var location: PaletteViewModel.Location = .bottom {
    didSet {
      updateBackgroundImage()
      setup()
    }
  }
  var darkMode = false {
    didSet {
      updateBackgroundImage()
    }
  }
  
  func updateBackgroundImage() {
    var image: UIImage?
    if darkMode {
      image = UIImage(named: "docBG", in: Bundle(for: Stylus.self), compatibleWith: nil)?.colorizedImage(withTint: UIColor(white: 0.15, alpha: 1), alpha: 1)
      
    }else {
      image = UIImage(named: "docBG", in: Bundle(for: Stylus.self), compatibleWith: nil)?.colorizedImage(withTint: UIColor(white: 1, alpha: 1), alpha: 1)
    }
    
    if location == .bottom {
      image = image?.stretchableImage(withLeftCapWidth: 45, topCapHeight: 35)
    }else if location == .top {
      if darkMode {
        image = UIImage(named: "docBGtop", in: Bundle(for: Stylus.self), compatibleWith: nil)?.colorizedImage(withTint: UIColor(white: 0.15, alpha: 1), alpha: 1)
        
      }else {
        image = UIImage(named: "docBGtop", in: Bundle(for: Stylus.self), compatibleWith: nil)?.colorizedImage(withTint: UIColor(white: 1, alpha: 1), alpha: 1)
      }
      
      image = image?.stretchableImage(withLeftCapWidth: 45, topCapHeight: 35)

    }else if location == .left {
      image = image?.rotate(radians: .pi/2).stretchableImage(withLeftCapWidth: 35, topCapHeight: 45)
      
    }else if location == .right {
      image = image?.rotate(radians: -.pi/2).stretchableImage(withLeftCapWidth: 35, topCapHeight: 45)

    }
    
    self.image = image
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  func setup() {
    self.isOpaque = false
    layer.shadowRadius = 10.0
    layer.shadowOpacity = 0.1
    
    let path = CGMutablePath()
    var rect = self.bounds
    if location == .bottom  {
      rect.size.height += 50
    }else if location == .top {
      rect.size.height += 50
      rect.origin.y -= 50
    }else {
      rect.size.height += 15
    }
    path.addRoundedRect(in: rect, cornerWidth: 20, cornerHeight: 20)
    layer.shadowPath = path
  }
  
  override var frame: CGRect {
    didSet {
      guard self.bounds.size.width > 40 else { return }
      setup()
    }
  }
}

@available(iOS 13.4, *)
public protocol PaletteViewControllerDelegate: AnyObject {
  func paletteViewControllerDidSave(_ array: [Data])
  func paletteViewController(_ : PaletteViewController, utilityTapped: UIButton )
  func paletteViewController(_ : PaletteViewController, configureUtilityButton: UIButton )

}

@available(iOS 13.4,*)
public class PaletteViewController: UIViewController, PaletteCustomising, PaletteTabViewDelegate {
  
  public var viewModel: PaletteViewModel!
  //  var buttons: [PalettePenButton] = []
  public weak var delegate: PaletteViewControllerDelegate?
  
  var darkMode = false {
    didSet {
      updateApparance()
    }
  }
  public var convertDarkColor = false
  public var usesAdvancedButton = true
  
  public weak var customUndoManager: UndoManager?
  @IBOutlet weak var undoButton: UIButton!
  @IBOutlet weak var redoButton: UIButton!
  @IBOutlet weak var backgroundView: PaletteBackgroundView!
  @IBOutlet weak var clipView: UIView!
  
  @IBOutlet weak var utilityButton: UIButton!
  
  private var observedToken: NSKeyValueObservation? = nil
  private var countObservedToken: NSKeyValueObservation? = nil
  private var draggingObservedToken: NSKeyValueObservation? = nil

  @IBOutlet weak var paletteTabView: PaletteTabView!
  
  public var location: PaletteViewModel.Location { viewModel.location }
  
  public var includesPencil: Bool = false
  
  private var showsToolLabel: Bool = true
  
  //MARK:- INSTANTIATE
  
  
  public static func viewController(disabledStyles: [Stylus.Mode] = [], hasUtilityButton: Bool = false, location: PaletteViewModel.Location = .bottom, showsRuler: Bool = true, showsToolLabel: Bool = true, includesPencil: Bool = true) -> PaletteViewController {
    if location == .bottom || location == .top {
      let vc = UIStoryboard(name: "PaletteViewController", bundle: Bundle(for: PaletteViewController.self)).instantiateViewController(identifier: "PaletteViewController") as! PaletteViewController
      
      let viewModel = PaletteViewModel(disabledStyles: disabledStyles, hasUtilityButton: hasUtilityButton, location: location, showsRuler: showsRuler, includesPencil: includesPencil)
      vc.viewModel = viewModel
      vc.showsToolLabel = showsToolLabel
      vc.includesPencil = includesPencil

      return vc
    }else {
      let vc = UIStoryboard(name: "PaletteViewController", bundle: Bundle(for: PaletteViewController.self)).instantiateViewController(identifier: "PaletteViewControllerVertical") as! PaletteViewController
      
      let viewModel = PaletteViewModel(disabledStyles: disabledStyles, hasUtilityButton: hasUtilityButton, location: location, showsRuler: showsRuler, includesPencil: includesPencil)

      vc.viewModel = viewModel
      vc.showsToolLabel = showsToolLabel
      vc.includesPencil = includesPencil
      return vc
    }
  }
  
  public func loadPreset(_ dataArray: [Data]) {
    
    viewModel.loadPreset(dataArray)
    if isViewLoaded {
      setup()
      paletteTabView.reload()
    }
  }
  
  //MARK:-

  override public func viewDidLoad() {
    super.viewDidLoad()
    clipView.clipsToBounds = true
    view.isHidden = true
    setup()

//    if let preset = viewModel.selectedPreset {
//      showPreset(preset, animated: false)
//    }
  }
  
  public func savePresets() {
    let dataArray = viewModel.savePresets()
    delegate?.paletteViewControllerDidSave(dataArray)
  }
  
  override public func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    align()
  }
  
  public func show(in viewController: UIViewController) {
    
    if self.view.superview != nil {
      self.view.removeFromSuperview()
      self.removeFromParent()
    }
    
    if viewModel.location == .bottom {
      viewController.addChild(self)
      view.isHidden = true
      self.didMove(toParent: viewController)
      let height = view.frame.size.height + 20

      let frame = view.frame
      var frame2 = frame
      frame2.origin.y += height
      view.frame = frame2
      viewController.view.addSubview(self.view)

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        
        self.view.frame = frame
        self.view.transform = CGAffineTransform.init(translationX: 0, y: height)
        
        UIView.animate(withDuration: 0.2, animations: {
          self.view.isHidden = false
          self.view.transform = .identity
        })
      }
    }
    
    if viewModel.location == .top {
      viewController.addChild(self)
      view.isHidden = true
      self.didMove(toParent: viewController)
      let height = view.frame.size.height + 20
      
      let frame = view.frame
      var frame2 = frame
      frame2.origin.y -= height
      view.frame = frame2
      viewController.view.addSubview(self.view)
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        
        self.view.frame = frame
        self.view.transform = CGAffineTransform.init(translationX: 0, y: -height)
        
        UIView.animate(withDuration: 0.2, animations: {
          self.view.isHidden = false
          self.view.transform = .identity
        })
      }
    }
    
    if viewModel.location == .right {
      viewController.addChild(self)
      view.isHidden = true
      didMove(toParent: viewController)
      let width = view.frame.size.width + 20

      let frame = view.frame
      var frame2 = frame
      frame2.origin.x += width
      view.frame = frame2
      
      viewController.view.addSubview(view)
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        
        self.view.frame = frame
        self.view.transform = CGAffineTransform.init(translationX: width, y: 0)
        
        UIView.animate(withDuration: 0.2, animations: {
          self.view.isHidden = false
          self.view.transform = .identity
        })
      }
    }
    
    if viewModel.location == .left {
      viewController.addChild(self)
      view.isHidden = true
      didMove(toParent: viewController)
      
      let width = -view.frame.size.width - 20

      let frame = view.frame
      var frame2 = frame
      frame2.origin.x -= width
      view.frame = frame2
      
      viewController.view.addSubview(view)

      self.view.frame = frame
      view.transform = CGAffineTransform.init(translationX: width, y: 0)
      
      UIView.animate(withDuration: 0.2, animations: {
        self.view.isHidden = false
        self.view.transform = .identity
      })
    }
    
  }
  
  public func close() {
    if viewModel.location == .bottom {
      
      let height = view.frame.size.height + 20
      
      self.willMove(toParent: nil)
      
      UIView.animate(withDuration: 0.2, animations: {
        self.view.transform = CGAffineTransform.init(translationX: 0, y: height)
      }, completion: { (flag) in
        self.view.removeFromSuperview()
        self.view.transform = .identity
        self.removeFromParent()
        
      })
    }
    
    if viewModel.location == .top {
      
      let height = view.frame.size.height + 20
      
      self.willMove(toParent: nil)
      
      UIView.animate(withDuration: 0.2, animations: {
        self.view.transform = CGAffineTransform.init(translationX: 0, y: -height)
      }, completion: { (flag) in
        self.view.removeFromSuperview()
        self.view.transform = .identity
        self.removeFromParent()
        
      })
    }
    
    if viewModel.location == .right {
      
      let width = view.frame.size.width + 20
      
      self.willMove(toParent: nil)
      
      UIView.animate(withDuration: 0.2, animations: {
        self.view.transform = CGAffineTransform.init(translationX: width, y: 0)
      }, completion: { (flag) in
        self.view.removeFromSuperview()
        self.removeFromParent()
        self.view.transform = .identity

      })
    }
    
    if viewModel.location == .left {
      
      let width = -view.frame.size.width - 20
      
      self.willMove(toParent: nil)
      
      UIView.animate(withDuration: 0.2, animations: {
        self.view.transform = CGAffineTransform.init(translationX: width, y: 0)
      }, completion: { (flag) in
        self.view.removeFromSuperview()
        self.removeFromParent()
        self.view.transform = .identity

      })
    }
  }
  
  override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if previousTraitCollection == nil || traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection!) {
      self.darkMode = traitCollection.userInterfaceStyle == .dark
      updateApparance()
    }
  }
  
  
  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    coordinator.animate(alongsideTransition: { (ctx) in
      self.align(forSize: size)

    }, completion: nil)
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    

  }
  
  override public func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    if customUndoManager != nil {
      NotificationCenter.default.addObserver(self, selector: #selector(undoDidChange(_:)), name: .NSUndoManagerDidUndoChange, object: customUndoManager)
      NotificationCenter.default.addObserver(self, selector: #selector(undoDidChange(_:)), name: .NSUndoManagerDidRedoChange, object: customUndoManager)
      NotificationCenter.default.addObserver(self, selector: #selector(undoDidChange(_:)), name: .NSUndoManagerCheckpoint, object: customUndoManager)
    }
    
    updateUndoState()
  }
  
  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func undoDidChange(_ sender: Notification) {
    updateUndoState()
  }
  
  func updateUndoState() {
    undoButton.isEnabled = customUndoManager?.canUndo ?? false
    redoButton.isEnabled = customUndoManager?.canRedo ?? false
  }
  
  func updateApparance() {
    if darkMode {
      undoButton.setImage(UIImage(named: "UndoDark", in: Bundle(for: Stylus.self), compatibleWith: nil), for: .normal)
      undoButton.setImage(UIImage(named: "UndoDarkDiabled", in: Bundle(for: Stylus.self), compatibleWith: nil), for: .disabled)
      redoButton.setImage(UIImage(named: "RedoDark", in: Bundle(for: Stylus.self), compatibleWith: nil), for: .normal)
      redoButton.setImage(UIImage(named: "RedoDarkDiabled", in: Bundle(for: Stylus.self), compatibleWith: nil), for: .disabled)
      utilityButton.setImage(UIImage(named: "PaletteMoreDarkDiabled", in: Bundle(for: Stylus.self), compatibleWith: nil), for: .disabled)
      utilityButton.setImage(UIImage(named: "PaletteMoreDark", in: Bundle(for: Stylus.self), compatibleWith: nil), for: .normal)

      backgroundView.darkMode = darkMode
      paletteTabView.darkMode = darkMode
    }else {
      undoButton.setImage(UIImage(named: "Undo", in: Bundle(for: Stylus.self), compatibleWith: nil), for: .normal)
      undoButton.setImage(UIImage(named: "UndoDiabled", in: Bundle(for: Stylus.self), compatibleWith: nil), for: .disabled)
      redoButton.setImage(UIImage(named: "Redo", in: Bundle(for: Stylus.self), compatibleWith: nil), for: .normal)
      redoButton.setImage(UIImage(named: "RedoDarkDiabled", in: Bundle(for: Stylus.self), compatibleWith: nil), for: .disabled)
      utilityButton.setImage(UIImage(named: "PaletteMoreDiabled", in: Bundle(for: Stylus.self), compatibleWith: nil), for: .disabled)
      utilityButton.setImage(UIImage(named: "PaletteMore", in: Bundle(for: Stylus.self), compatibleWith: nil), for: .normal)

      backgroundView.darkMode = darkMode
      paletteTabView.darkMode = darkMode
    }
    
    paletteTabView.reload()
  }
  
  func setup() {
    self.darkMode = traitCollection.userInterfaceStyle == .dark
    
    
    if viewModel.location == .left {
      var frame = clipView.bounds
      frame.size.width += 16
      paletteTabView.frame = frame
    }
    
    if viewModel.location == .right {
      var frame = clipView.bounds
      frame.origin.x -= 16
      frame.size.width += 16
      paletteTabView.frame = frame
    }
    
    if viewModel.location == .top {
      var frame = backgroundView.frame
      frame.size.height += 17
      backgroundView.frame = frame
      
    }
    
    
    if viewModel.location == .top {
      var frame = redoButton.frame
      frame.origin.y += 20
      redoButton.frame = frame
      
      frame = undoButton.frame
      frame.origin.y += 20
      undoButton.frame = frame
      
      frame = utilityButton.frame
      frame.origin.y += 20
      utilityButton.frame = frame
    }
    
    
    paletteTabView.convertDarkColor = convertDarkColor
    paletteTabView.showsToolLabel = showsToolLabel
    paletteTabView.dataSource = viewModel
    paletteTabView.delegate = self
    paletteTabView.reload()
    
    backgroundView.location = viewModel.location
    
    utilityButton.isPointerInteractionEnabled = true
    utilityButton.pointerStyleProvider = { button, proposedEffect, proposedShape -> UIPointerStyle? in
      let targetedPreview = UITargetedPreview(view: proposedEffect.preview.view)
      let rect = button.convert(button.bounds, to: targetedPreview.target.container)
      return  UIPointerStyle(effect: UIPointerEffect.lift(targetedPreview), shape: .roundedRect(rect, radius: rect.size.width/2))
    }
    
    undoButton.pointerStyleProvider = utilityButton.pointerStyleProvider
    redoButton.pointerStyleProvider = utilityButton.pointerStyleProvider


    observedToken?.invalidate()
    observedToken = viewModel.observe(\.displayPopover, options: [.new, .old]) { [weak self] object, change in

      if change.newValue == true {
        self?.showPopover()
      }else {
        self?.presentedViewController?.dismiss(animated: false, completion: nil)
      }
    }
    
    countObservedToken?.invalidate()
    countObservedToken = viewModel.observe(\.presets, options: [.new, .old]) { [weak self] object, change in
      if self?.viewModel.isDragging == true { return }
      
      if change.newValue?.count != change.oldValue?.count {
        self?.align()
        self?.savePresets()
        
        if change.newValue != nil && change.oldValue != nil && change.newValue!.count > change.oldValue!.count {
          guard let count = self?.viewModel.presets.count else { return }
          self?.paletteTabView.didCreateCell(at: count - 1)
          self?.paletteTabView.reload()
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self?.paletteTabView.revealCreatedCell(at: count - 1)
            self?.viewModel.displayPopover = true
          }
        }
      }
      
    }
    
    draggingObservedToken?.invalidate()
    draggingObservedToken = viewModel.observe(\.isDragging, options: [.new, .old]) { [weak self] object, change in
//      self?.clipView.clipsToBounds = self?.viewModel.isDragging == false
      
      if self?.viewModel.isDragging == false {
        self?.savePresets()
      }
    }
    
    delegate?.paletteViewController(self, configureUtilityButton: utilityButton)
  }
  
  @objc func savePresets(_ n: Notification) {
    savePresets()
  }
  
  @IBAction func undoAction(_ sender: Any) {
    if customUndoManager?.canUndo == true {
      customUndoManager?.undo()
    }
  }
  
  @IBAction func utilityAction(_ sender: Any) {
    delegate?.paletteViewController(self, utilityTapped: utilityButton )
  }
  
  @IBAction func redoAction(_ sender: Any) {
    if customUndoManager?.canRedo == true {
      customUndoManager?.redo()
    }
  }
  
  func align(forSize size: CGSize? = nil) {
    guard let _ = parent?.view.bounds else { return }
    
    let frame = viewModel.viewFrameForParent(parent)
    view.frame = frame
    
    let clipViewFrame = viewModel.clipViewFrameFor(bounds: view.bounds, parent: parent!)
    clipView.frame = clipViewFrame
    print(clipViewFrame)
    utilityButton.isHidden = viewModel.utilityButtonIsHidden
    paletteTabView.location = viewModel.location
    
  }
  
  public func switchEraser() {
    guard let eraser = viewModel.presets.filter( { $0.mode == .objEraser || $0.mode == .pixEraser } ).first else { return }
    Stylus.shared.setPreset(eraser)

    let currentSelectedCell = paletteTabView.selectedCell()
    (currentSelectedCell as? StylusPresetCell)?.setPresetSelected(false, animated: true)

    viewModel.selectedPreset = eraser

    showPreset(eraser)
  }
  
  public func switchObjectEraser(_ flag: Bool) {
    guard let eraser = viewModel.presets.filter( { $0.mode == .objEraser || $0.mode == .pixEraser } ).first else { return }
    
    
    let currentMode = Stylus.shared.mode
    Stylus.shared.setPreset(eraser)
    
    let currentSelectedCell = paletteTabView.selectedCell()
    (currentSelectedCell as? StylusPresetCell)?.setPresetSelected(false, animated: true)
    
    viewModel.selectedPreset = eraser
    
    showPreset(eraser)
    
    if currentMode == .objEraser || currentMode == .pixEraser {
      setPixEraser(!flag)
    }
  }
  

  
  public func switchLasso() {
    guard let lasso = viewModel.presets.filter( { $0.mode == .lasso  } ).first else { return }
        
    Stylus.shared.setPreset(lasso)
    
    let currentSelectedCell = paletteTabView.selectedCell()
    (currentSelectedCell as? StylusPresetCell)?.setPresetSelected(false, animated: true)
    
    viewModel.selectedPreset = lasso
    
    showPreset(lasso)
  }
  
  public func switchPrevious() {
    guard let previous = viewModel.popPresetIndexHistory() else { return }
    
    Stylus.shared.setPreset(previous)

    let currentSelectedCell = paletteTabView.selectedCell()
    (currentSelectedCell as? StylusPresetCell)?.setPresetSelected(false, animated: true)
    
    viewModel.selectedPreset = previous
    showPreset(previous)
  }
  
  public func switchNone() {

    viewModel.selectedPreset = nil
    let indexPaths = paletteTabView.collectionView.indexPathsForVisibleItems
    for indexPath in indexPaths {
        let cell = paletteTabView.collectionView.cellForItem(at: indexPath)
        (cell as? StylusPresetCell)?.setPresetSelected(false, animated: true)
    }
  }
  
  func showPreset(_ preset: StylusPreset, animated: Bool = true) {
    
    let indexPaths = paletteTabView.collectionView.indexPathsForVisibleItems
    
    for indexPath in indexPaths {
      if viewModel.presets[indexPath.row].uuid == preset.uuid {
        let cell = paletteTabView.collectionView.cellForItem(at: indexPath)
        (cell as? StylusPresetCell)?.setPresetSelected(true, animated: animated)

        return
      }
    }
    
    if let row = viewModel.presets.firstIndex(of: preset) {
      paletteTabView.collectionView.scrollToItem(at: IndexPath(row: row, section: 0), at: .centeredHorizontally, animated: animated)
    }
  }
  
  func showPopover() {
    
    guard let cell = paletteTabView.selectedCell() else { return }
    guard let preset = viewModel.selectedPreset else { return }
    
    if preset.mode == .pixEraser || preset.mode == .objEraser {
      guard let contentViewController = self.storyboard?.instantiateViewController(withIdentifier: "PalettEraserViewController") as? PalettEraserViewController else { return }
      contentViewController.modalPresentationStyle = .popover
      contentViewController.viewModel = viewModel
      contentViewController.delegate = self
      contentViewController.eraserType = preset.mode
      contentViewController.darkMode = darkMode
      if let popover = contentViewController.popoverPresentationController {
        popover.sourceRect = cell.frame.insetBy(dx: 0, dy: -30)
        popover.sourceView = cell.superview
        popover.backgroundColor = darkMode ? UIColor(white: 0.15, alpha: 1) : .white
        popover.delegate = self
      }
      present(contentViewController, animated: true, completion: nil)
    }
    
    if preset.mode == .pen || preset.mode == .alphaPen || preset.mode == .brushPen || preset.mode == .pencil {
      
      guard let contentViewController = self.storyboard?.instantiateViewController(withIdentifier: "PalettColorPickeNavigationController") as? UINavigationController else { return }
      let root = contentViewController.viewControllers.first as! PalettColorPickerViewController
      contentViewController.modalPresentationStyle = .popover
      root.usesAdvancedButton = usesAdvancedButton
      root.viewModel = viewModel
      root.preset = preset
      root.darkMode = darkMode
      root.convertDarkColor = convertDarkColor
      root.delegate = self
      if let popover = contentViewController.popoverPresentationController {
        popover.sourceRect = cell.frame.insetBy(dx: 0, dy: -30)
        popover.sourceView = cell.superview
        popover.backgroundColor = darkMode ? UIColor(white: 0.15, alpha: 1) : .white
        popover.delegate = self
      }
      present(contentViewController, animated: true, completion: nil)
    }
  }
  
  func tabView(_: PaletteTabView, createNewFrom cell: UICollectionViewCell) {

    //PaletteAddNewPenViewController
    guard let contentViewController = self.storyboard?.instantiateViewController(withIdentifier: "PaletteAddNewPenViewController") as? PaletteAddNewPenViewController else { return }
    contentViewController.modalPresentationStyle = .popover
    contentViewController.viewModel = viewModel
    contentViewController.darkMode = darkMode
    contentViewController.includesPencil = includesPencil
    if let popover = contentViewController.popoverPresentationController {
      popover.sourceRect = cell.frame.insetBy(dx: 0, dy: -10)
      popover.sourceView = cell.superview
      if location == .bottom {
        popover.permittedArrowDirections = [.down]
      }else if location == .left {
        popover.permittedArrowDirections = [.left]
      }else if location == .right {
        popover.permittedArrowDirections = [.right]
      }else {
        popover.permittedArrowDirections = [.up]
      }
      popover.backgroundColor = darkMode ? UIColor(white: 0.15, alpha: 1) : .white
      popover.delegate = self
    }
    present(contentViewController, animated: true, completion: nil)

  }
  

  //MARK:- PaletteCustomising
  
  
  func setPixEraser(_ isPix: Bool) {
    guard let preset = viewModel.selectedPreset else { return }

    preset.mode = isPix ? .pixEraser : .objEraser
    Stylus.shared.mode = preset.mode
    
    preset.name = isPix ? WLoc("P_Pix Eraser") : WLoc("P_Obj Eraser")
    
    paletteTabView.reload()
  }
  
  func setColor(_ color: SIMD4<Float>) {
    guard let preset = viewModel.selectedPreset else { return }

    preset.color = color
    Stylus.shared.color = color
    paletteTabView.reload()
  }
  
  func setPenSize(_ penSize: Stylus.PenSize) {
    guard let preset = viewModel.selectedPreset else { return }

    preset.penSize = penSize
    Stylus.shared.penSize = penSize
    paletteTabView.reload()
  }
  
  func setThickness(_ thickness: Float) {
    guard let preset = viewModel.selectedPreset else { return }
    preset.thickness = thickness
    Stylus.shared.thickness = thickness
  }
  
  func setPressure(_ pressure: Float) {
    guard let preset = viewModel.selectedPreset else { return }

    preset.pressure = pressure
    Stylus.shared.pressure = pressure
  }
  
  func setPressureAlpha(_ pressureAlpha: Float) {
    guard let preset = viewModel.selectedPreset else { return }
    
    preset.pressureAlpha = pressureAlpha
    Stylus.shared.pressureAlpha = pressureAlpha
  }
  
  func setInkSpeed(_ speed: Float) {
    guard let preset = viewModel.selectedPreset else { return }

    preset.inkSpeed = speed
    Stylus.shared.inkSpeed = speed
  }
  
  func setInitialPressureCutoff(_ pressure: Float) {
    guard let preset = viewModel.selectedPreset else { return }

    preset.initialPressureCutoff = pressure
    Stylus.shared.initialPressureCutoff = pressure
  }
  
  func setRatio(_ ratio: Float) {
    guard let preset = viewModel.selectedPreset else { return }
    
    preset.ratio = ratio
    Stylus.shared.ratio = ratio
  }

  func setAzimuthBrush(_ flag: Bool) {
    guard let preset = viewModel.selectedPreset else { return }
    
    preset.azimuthBrush = flag
    Stylus.shared.azimuthBrush = flag
  }
  
  func setAltitudeBrush(_ value: Float) {
    guard let preset = viewModel.selectedPreset else { return }
    
    preset.altitudeBrush = value
    Stylus.shared.altitudeBrush = value
  }
  
  func setName(_ value: String) {
    guard let preset = viewModel.selectedPreset else { return }
    preset.name = value
    paletteTabView.reload()
  }
  
  func setBrushNumber(_ value: Int) {
    guard let preset = viewModel.selectedPreset else { return }
    
    preset.brushNumber = value
    Stylus.shared.brushNumber = value
    paletteTabView.reload()
  }
}


//MARK:- UIPopoverPresentationControllerDelegate
@available(iOS 13.4,*)
extension PaletteViewController: UIPopoverPresentationControllerDelegate {
  public func adaptivePresentationStyle(for controller: UIPresentationController)
    -> UIModalPresentationStyle {
      return .none
  }
  
  public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection)
    -> UIModalPresentationStyle {
      return .none
  }
  
  public func popoverPresentationController( _ popoverPresentationController: UIPopoverPresentationController,
                                             willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>,
                                             in view: AutoreleasingUnsafeMutablePointer<UIView>) {
  }
  
  public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
    savePresets()
  }
}

@available(iOS 13.4,*)
protocol PaletteCustomising: AnyObject {
//  func customiseColor(for: PalettePenButton)
  
  func setPixEraser(_ isPix: Bool)
  func setColor(_ color: SIMD4<Float>)
  func setPenSize(_ penSize: Stylus.PenSize)
  func setThickness(_ thickness: Float)
  func setPressure(_ pressure: Float)
  func setPressureAlpha(_ pressure: Float)
  func setInkSpeed(_ speed: Float)
  func setInitialPressureCutoff(_ pressure: Float)
  func setRatio(_ ratio: Float)
  func setAzimuthBrush(_ flag: Bool)
  func setAltitudeBrush(_ value: Float)
  func setName(_ value: String)
  func setBrushNumber(_ value: Int)

}

//MARK:-

@available(iOS 13.4,*)
class PalettEraserViewController: UIViewController {
  @IBOutlet weak var segmentControl: UISegmentedControl!
  weak var delegate: PaletteCustomising?
  weak var viewModel: PaletteViewModel?
  var eraserType: Stylus.Mode?
  var darkMode = false {
    didSet {
      overrideUserInterfaceStyle = darkMode ? .dark : .light
    }
  }
  
  override var preferredContentSize: CGSize {
    get {
      return CGSize(width: 280, height: 65)
    }
    set {
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    segmentControl.setTitle(WLoc("Pixel Eraser"), forSegmentAt: 0)
    segmentControl.setTitle(WLoc("Object Eraser"), forSegmentAt: 1)

    if eraserType == .pixEraser {
      segmentControl.selectedSegmentIndex = 0
    }
    
    if eraserType == .objEraser {
      segmentControl.selectedSegmentIndex = 1
    }
    
    view.clipsToBounds = true
  }
  
  
  @IBAction func changeEraserType(_ sender: Any) {
    if segmentControl.selectedSegmentIndex == 0 { eraserType = .pixEraser }
    else { eraserType = .objEraser }
    delegate?.setPixEraser(segmentControl.selectedSegmentIndex == 0)
  }
}

@available(iOS 13.4,*)
class PaletteAddNewPenViewController: UIViewController {
  
  var includesPencil = false
  
  @IBOutlet weak var penButton: UIButton!
  @IBOutlet weak var brushButton: UIButton!
  @IBOutlet weak var alphaPenImageView: UIImageView!
  @IBOutlet weak var brushPenImageView: UIImageView!
  @IBOutlet weak var pencilImageView: UIImageView!

  weak var viewModel: PaletteViewModel?
  var darkMode = false {
    didSet {
      overrideUserInterfaceStyle = darkMode ? .dark : .light
    }
  }
    
  override var preferredContentSize: CGSize {
    get {
      if includesPencil {
        return CGSize(width: 210, height: 100)

      }else {
        return CGSize(width: 150, height: 100)
      }
    }
    set {
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let tintColor = view.tintColor
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
    tintColor?.getRed(&red, green: &green, blue: &blue, alpha: nil)

    
    let brushPen = StylusPreset(mode: .brushPen, color: SIMD4<Float>(Float(red), Float(green), Float(blue),1), penSize: .r, name: WLoc("P_UntitledBrush"), brushNumber: 0)
    let alphaPen = StylusPreset(mode: .alphaPen, color: SIMD4<Float>(Float(red), Float(green), Float(blue),1), penSize: .r, name: WLoc("P_Untitled"))
    let pencilPen = StylusPreset(mode: .pencil, color: SIMD4<Float>(Float(red), Float(green), Float(blue),1), penSize: .r, name: WLoc("P_UntitledPencil"))

    let brushImage = brushPen.image(dark: darkMode, convertDarkColor: false)
    let alphaImage = alphaPen.image(dark: darkMode, convertDarkColor: false)
    let pencilImage = pencilPen.image(dark: darkMode, convertDarkColor: false)

    alphaPenImageView.image = alphaImage
    brushPenImageView.image = brushImage
    pencilImageView.image = pencilImage
    
    for view in [alphaPenImageView, brushPenImageView, pencilImageView] {
      view?.layer.shadowColor = UIColor.black.cgColor
      view?.layer.shadowRadius = 7.0
      view?.layer.shadowOpacity = 0.1
      view?.layer.shadowOffset = CGSize(width: 0, height: 3)
    }
  }
  
  @IBAction func addBrush(_ sender: Any) {
    dismiss(animated: false) { [weak self] in
      self?.viewModel?.addNewPen(.brushPen, select: true)
    }
  }
  
  @IBAction func addPen(_ sender: Any) {
    dismiss(animated: false) { [weak self] in
      self?.viewModel?.addNewPen(.alphaPen, select: true)
    }
  }
  
  @IBAction func addPencil(_ sender: Any) {
    dismiss(animated: false) { [weak self] in
      self?.viewModel?.addNewPen(.pencil, select: true)
    }
  }
  
}

//MARK:-

//@available(iOS 13.4,*)
//extension PalettColorPickerViewController: ColorPickerDelegate {
//  func setColor(_ colorPicker: ColorPickerViewController, color: SIMD4<Float>?) {
//    delegate?.setColor(color!)
//  }
//}


@available(iOS 14.0,*)
extension PalettColorPickerViewController: UIColorPickerViewControllerDelegate {
  func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    delegate?.setColor(SIMD4<Float>(Float(red), Float(green), Float(blue), Float(alpha)))

  }
}

@available(iOS 13.4,*)
class PalettColorPickerViewController: UIViewController {
//  @IBOutlet weak var imageView: UIImageView!
//  @IBOutlet weak var snipetView: UIView!
//  @IBOutlet weak var alphaSlider: AlphaSlider!
  
  @IBOutlet weak var penSize1: PenSizeButton!
  @IBOutlet weak var penSize2: PenSizeButton!
  @IBOutlet weak var penSize3: PenSizeButton!
  @IBOutlet weak var penSize4: PenSizeButton!
  @IBOutlet weak var penSize5: PenSizeButton!
  
  @IBOutlet weak var messageLabel: UILabel!
  
  @IBOutlet weak var advancedButton: UIButton!
  
  var colorPicker: UIColorPickerViewController!
  
  weak var delegate: PaletteCustomising?
  weak var viewModel: PaletteViewModel?
  
  var usesAdvancedButton = true
  
  var darkMode: Bool = false {
    didSet {
      penSize1?.darkMode = darkMode
      penSize2?.darkMode = darkMode
      penSize3?.darkMode = darkMode
      penSize4?.darkMode = darkMode
      penSize5?.darkMode = darkMode
      
      overrideUserInterfaceStyle = darkMode ? .dark : .light
      navigationController?.overrideUserInterfaceStyle = darkMode ? .dark : .light
    }
  }
  
  var convertDarkColor = false
  
  // MODEL
  var preset: StylusPreset! {
    didSet {

    }
  }
//  var color: SIMD4<Float> = SIMD4<Float>(1,1,1,1) {
//    didSet {
//      alphaSlider?.color = color
//    }
//  }
//  var penSize: Stylus.PenSize = .r
//  var inkSpeed: Float = 0
//  var pressure: Float = 0
//  var initialPressureCutoff: Float = 0
//  var ratio: Float = 0
//  var penMode: Stylus.Mode!
//  var pressureBrush: Bool = false
//  var azimuthBrush: Bool = false
//  var altitudeBrush: Float = 0
//
  
  override var preferredContentSize: CGSize {
    get {
#if targetEnvironment(macCatalyst)
      return CGSize(width: 280, height: 260) // 320 for iphone
      
#else
      return CGSize(width: 370, height: 670) // 320 for iphone
#endif
    }
    set {
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let controller = UIColorPickerViewController()//ColorPickerViewController.viewController(color: preset.color)
    colorPicker = controller
    let color = UIColor(red: CGFloat(preset.color[0]), green: CGFloat(preset.color[1]), blue: CGFloat(preset.color[2]), alpha: CGFloat(preset.color[3]))
    colorPicker.selectedColor = color
    colorPicker.supportsAlpha = true
    colorPicker.delegate = self
//    colorPicker.convertDarkColor = convertDarkColor
//    controller.darkMode = darkMode
    controller.view.frame = CGRect(x: 0, y: 50, width: view.bounds.size.width, height: view.bounds.size.height - 50)
    view.addSubview(controller.view)
    addChild(controller)
    controller.didMove(toParent: self)

    advancedButton.isHidden = !usesAdvancedButton
    
    penSize1?.darkMode = darkMode
    penSize2?.darkMode = darkMode
    penSize3?.darkMode = darkMode
    penSize4?.darkMode = darkMode
    penSize5?.darkMode = darkMode
        
    
    if advancedButton.isHidden {
      var frame = penSize1.frame
      frame.origin.x += 20
      penSize1.frame = frame
      
      frame = penSize2.frame
      frame.origin.x += 20
      penSize2.frame = frame
      
      frame = penSize3.frame
      frame.origin.x += 20
      penSize3.frame = frame
      
      frame = penSize4.frame
      frame.origin.x += 20
      penSize4.frame = frame
      
      frame = penSize5.frame
      frame.origin.x += 20
      penSize5.frame = frame
    }
    
    switch preset.penSize {
    case .xs: penSize1.isSelected = true
    case .s:  penSize2.isSelected = true
    case .r:  penSize3.isSelected = true
    case .l:  penSize4.isSelected = true
    case .xl:  penSize5.isSelected = true

    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if preset.brushNumber == StylusPreset.maskingBrushNumber {
      colorPicker.view.isHidden = true
      messageLabel.isHidden = false
      messageLabel.text = WLoc("Masking Pen\nTouch to unhide in browsing mode")
    }else {
      colorPicker.view.isHidden = false
      messageLabel.isHidden = true
    }
  }
  
  @IBAction func detailButtonClicked(_ sender: Any) {

  }
  
  
  @IBAction func penSizeAction(_ sender: UIButton) {
    penSize1.isSelected = false
    penSize2.isSelected = false
    penSize3.isSelected = false
    penSize4.isSelected = false
    penSize5.isSelected = false

    if sender == penSize1 { preset.penSize = .xs; penSize1.isSelected = true }
    else if sender == penSize2 { preset.penSize = .s; penSize2.isSelected = true }
    else if sender == penSize3 { preset.penSize = .r; penSize3.isSelected = true }
    else if sender == penSize4 { preset.penSize = .l; penSize4.isSelected = true }
    else if sender == penSize5 { preset.penSize = .xl; penSize5.isSelected = true }

    delegate?.setPenSize(preset.penSize)
  }

}

//MARK:-

@available(iOS 13.4,*)
class PenSizeButton: UIButton {
  var darkMode: Bool = false
  
  override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
    return .zero
  }
  
  override func draw(_ rect: CGRect) {
    guard let ctx = UIGraphicsGetCurrentContext() else { return }
    guard let image = self.image(for: .normal) else { return }
    
    if isSelected {
      
      
      if darkMode {
        ctx.setFillColor(UIColor.white.cgColor)

      }else {
        ctx.setFillColor(UIColor.black.cgColor)
      }
      
      squirclePath.fill()

      
      if darkMode {
        image.draw(in: rect)

      }else {
        image.colorizedImage(withTint: .white, alpha: 1).draw(in: rect)
      }
      
    }else {
      if darkMode {
        image.colorizedImage(withTint: .white, alpha: 1).draw(in: rect)

      }else {
        image.draw(in: rect)
      }
    }
  }
  
  
  //https://github.com/neobeppe/Squircle/blob/master/Squircle/Internal/Squircle%2BInternal.swift
  internal var squirclePath: UIBezierPath {
    
    let width = bounds.width
    let height = bounds.height
    let squircleSide = min(width, height)
    CGPoint.xDelta = abs(squircleSide - width)
    CGPoint.yDelta = abs(squircleSide - height)
    
    let checkpoints = Checkpoints(width: bounds.width, height: bounds.height)
    
    let path = UIBezierPath()
    path.move(to: CGPoint(x: checkpoints.cornerDelta, y: 0))
    
    path.addLine(to: CGPoint(x: width-checkpoints.cornerDelta, y: 0))
    path.addCurve(to: CGPoint.xDeltaPoint(x: checkpoints.checkpoint0, y: squircleSide-checkpoints.checkpoint3),
                  controlPoint1: CGPoint.xDeltaPoint(x: checkpoints.checkpoint1, y: 0),
                  controlPoint2: CGPoint.xDeltaPoint(x: checkpoints.checkpoint2, y: 0))
    path.addCurve(to: CGPoint.xDeltaPoint(x: checkpoints.checkpoint3, y: squircleSide-checkpoints.checkpoint0),
                  controlPoint1: CGPoint.xDeltaPoint(x: checkpoints.checkpoint4, y: squircleSide-checkpoints.checkpoint5),
                  controlPoint2: CGPoint.xDeltaPoint(x: checkpoints.checkpoint5, y: squircleSide-checkpoints.checkpoint4))
    path.addCurve(to: CGPoint.xDeltaPoint(x: squircleSide, y: checkpoints.cornerDelta),
                  controlPoint1: CGPoint.xDeltaPoint(x: squircleSide, y: squircleSide-checkpoints.checkpoint2),
                  controlPoint2: CGPoint.xDeltaPoint(x: squircleSide, y: squircleSide-checkpoints.checkpoint1))
    
    path.addLine(to: CGPoint(x: width, y: height-checkpoints.cornerDelta))
    path.addCurve(to: CGPoint.deltaPoint(x: checkpoints.checkpoint3, y: checkpoints.checkpoint0),
                  controlPoint1: CGPoint.deltaPoint(x: squircleSide, y: checkpoints.checkpoint1),
                  controlPoint2: CGPoint.deltaPoint(x: squircleSide, y: checkpoints.checkpoint2))
    path.addCurve(to: CGPoint.deltaPoint(x: checkpoints.checkpoint0, y: checkpoints.checkpoint3),
                  controlPoint1: CGPoint.deltaPoint(x: checkpoints.checkpoint5, y: checkpoints.checkpoint4),
                  controlPoint2: CGPoint.deltaPoint(x: checkpoints.checkpoint4, y: checkpoints.checkpoint5))
    path.addCurve(to: CGPoint.deltaPoint(x: squircleSide-checkpoints.cornerDelta, y: squircleSide),
                  controlPoint1: CGPoint.deltaPoint(x: checkpoints.checkpoint2, y: squircleSide),
                  controlPoint2: CGPoint.deltaPoint(x: checkpoints.checkpoint1, y: squircleSide))
    
    path.addLine(to: CGPoint(x: checkpoints.cornerDelta, y: height))
    path.addCurve(to: CGPoint.yDeltaPoint(x: squircleSide-checkpoints.checkpoint0, y: checkpoints.checkpoint3),
                  controlPoint1: CGPoint.yDeltaPoint(x: squircleSide-checkpoints.checkpoint1, y: squircleSide),
                  controlPoint2: CGPoint.yDeltaPoint(x: squircleSide-checkpoints.checkpoint2, y: squircleSide))
    path.addCurve(to: CGPoint.yDeltaPoint(x: squircleSide-checkpoints.checkpoint3, y: checkpoints.checkpoint0),
                  controlPoint1: CGPoint.yDeltaPoint(x: squircleSide-checkpoints.checkpoint4, y: checkpoints.checkpoint5),
                  controlPoint2: CGPoint.yDeltaPoint(x: squircleSide-checkpoints.checkpoint5, y: checkpoints.checkpoint4))
    path.addCurve(to: CGPoint.yDeltaPoint(x: 0, y: squircleSide-checkpoints.cornerDelta),
                  controlPoint1: CGPoint.yDeltaPoint(x: 0, y: checkpoints.checkpoint2),
                  controlPoint2: CGPoint.yDeltaPoint(x: 0, y: checkpoints.checkpoint1))
    
    path.addLine(to: CGPoint(x: 0, y: checkpoints.cornerDelta))
    path.addCurve(to: CGPoint(x: squircleSide-checkpoints.checkpoint3, y: squircleSide-checkpoints.checkpoint0),
                  controlPoint1: CGPoint(x: 0, y: squircleSide-checkpoints.checkpoint1),
                  controlPoint2: CGPoint(x: 0, y: squircleSide-checkpoints.checkpoint2))
    path.addCurve(to: CGPoint(x: squircleSide-checkpoints.checkpoint0, y: squircleSide-checkpoints.checkpoint3),
                  controlPoint1: CGPoint(x: squircleSide-checkpoints.checkpoint5, y: squircleSide-checkpoints.checkpoint4),
                  controlPoint2: CGPoint(x: squircleSide-checkpoints.checkpoint4, y: squircleSide-checkpoints.checkpoint5))
    path.addCurve(to: CGPoint(x: checkpoints.cornerDelta, y: 0),
                  controlPoint1: CGPoint(x: squircleSide-checkpoints.checkpoint2, y: 0),
                  controlPoint2: CGPoint(x: squircleSide-checkpoints.checkpoint1, y: 0))
    
    path.close()
    
    return path
  }

}

extension CGPoint {
  
  static var xDelta: CGFloat = 0
  static var yDelta: CGFloat = 0
  
  static func xDeltaPoint(x: CGFloat, y: CGFloat) -> CGPoint {
    return CGPoint(x: xDelta + x, y: y)
  }
  
  static func yDeltaPoint(x: CGFloat, y: CGFloat) -> CGPoint {
    return CGPoint(x: x, y: yDelta + y)
  }
  
  static func deltaPoint(x: CGFloat, y: CGFloat) -> CGPoint {
    return CGPoint(x: xDelta + x, y: yDelta + y)
  }
}

struct Checkpoints {
  
  let width: CGFloat
  let height: CGFloat
  
  let startRatio: CGFloat = 256/87.15
  
  let checkpoint0Ratio: CGFloat = 256/219.33
  let checkpoint1Ratio: CGFloat = 256/198.35
  let checkpoint2Ratio: CGFloat = 256/206.63
  let checkpoint3Ratio: CGFloat = 256/251.73
  let checkpoint4Ratio: CGFloat = 256/234.35
  let checkpoint5Ratio: CGFloat = 256/246.24
  
  var squircleSide: CGFloat { return min(width, height) }
  
  var cornerDelta: CGFloat { return squircleSide/startRatio }
  var checkpoint0: CGFloat { return squircleSide/checkpoint0Ratio }
  var checkpoint1: CGFloat { return squircleSide/checkpoint1Ratio }
  var checkpoint2: CGFloat { return squircleSide/checkpoint2Ratio }
  var checkpoint3: CGFloat { return squircleSide/checkpoint3Ratio }
  var checkpoint4: CGFloat { return squircleSide/checkpoint4Ratio }
  var checkpoint5: CGFloat { return squircleSide/checkpoint5Ratio }
}

extension UIImage {
  func rotate(radians: CGFloat) -> UIImage {
    let rotatedSize = CGRect(origin: .zero, size: size)
      .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
      .integral.size
    UIGraphicsBeginImageContext(rotatedSize)
    if let context = UIGraphicsGetCurrentContext() {
      let origin = CGPoint(x: rotatedSize.width / 2.0,
                           y: rotatedSize.height / 2.0)
      context.translateBy(x: origin.x, y: origin.y)
      context.rotate(by: radians)
      draw(in: CGRect(x: -origin.y, y: -origin.x,
                      width: size.width, height: size.height))
      let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      
      return rotatedImage ?? self
    }
    
    return self
  }
}
