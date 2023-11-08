//
//  PaletteTabView.swift
//  LawInSwift
//
//  Created by Masatoshi Nishikata on 22/09/16.
//  Copyright © 2016 Catalystwo. All rights reserved.
//

import UIKit

@available(iOS 13.4,*)
protocol StylusPresetCellProtocol: AnyObject {
  var image: UIImage? { get set }
  var isPresetSelected: Bool { get set }
  func setPresetSelected(_ flag: Bool, animated: Bool)
  func wasJustCreated()
  var name: String { set get }
  var isNameLabelHidden: Bool { set get }
}


@available(iOS 13.4,*)
class StylusPresetCell: UICollectionViewCell, StylusPresetCellProtocol {
  
  weak var imageView: UIImageView!
  weak var nameLabel: PalletteTabVerticalTextLabel!
  weak var horizontalNameLabel: UILabel!

  weak var containerView: UIView?
  
  var location: PaletteViewModel.Location = .bottom {
    didSet {
      if location == .left {
        containerView?.transform = CGAffineTransform.init(rotationAngle: .pi/2)
        horizontalNameLabel.isHidden = false
        nameLabel.isHidden = true
        horizontalNameLabel.textAlignment = .right
        horizontalNameLabel.frame = CGRect(x: -40, y: -8, width: frame.size.width, height: 15)

      }else if location == .right {
        containerView?.transform = CGAffineTransform.init(rotationAngle: -.pi/2)
        horizontalNameLabel.isHidden = false
        nameLabel.isHidden = true
        horizontalNameLabel.textAlignment = .left
        horizontalNameLabel.frame = CGRect(x: 65, y: -8, width: frame.size.width, height: 15)

      }else {
        contentView.transform = .identity
        horizontalNameLabel.isHidden = true
        nameLabel.isHidden = false

        if location == .bottom {
          var frame = imageView.frame
          frame.size.height = contentView.frame.size.height + 50
          imageView.frame = frame
        }
      }
    }
  }
  var image: UIImage? {
    didSet {
      if location == .bottom {
        
        if let image = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 99, left: 40, bottom: 1, right: 0), resizingMode: .stretch) {
          imageView?.image = image
          imageView?.contentMode = .scaleToFill
        }else {
          imageView?.image = nil
        }
        
      }else {
        imageView?.image = image

      }
      
  
    }
  }
  
  var name: String = "" {
    didSet {
      nameLabel?.attributedString = NSAttributedString(string: name, attributes: textAttributes)
      horizontalNameLabel?.attributedText = NSAttributedString(string: name, attributes: horizontalTextAttributes)
    }
  }
  
  var isPresetSelected: Bool = false {
    didSet {
      self.tag = isPresetSelected ? 1 : 0
    }
  }
  
  override var frame: CGRect {
    willSet {
      containerView?.transform = .identity
    }
    didSet {
      if location == .left {
        containerView?.transform = CGAffineTransform.init(rotationAngle: .pi/2)
        
      }else if location == .right {
        containerView?.transform = CGAffineTransform.init(rotationAngle: -.pi/2)
        
      }
    }
  }
  
  func wasJustCreated() {
    if location == .bottom || location == .top {
      self.imageView.transform = CGAffineTransform(translationX: 0, y: self.bounds.size.height + 30)
      self.nameLabel.transform = CGAffineTransform(translationX: 0, y: self.bounds.size.height + 30)
    }
    else if location == .right {
      self.imageView.transform = CGAffineTransform(translationX: self.bounds.size.width + 30, y: 0)
      self.horizontalNameLabel.transform = CGAffineTransform(translationX: self.bounds.size.width + 30, y: 0)
    }else {
      self.imageView.transform = CGAffineTransform(translationX: -self.bounds.size.width - 30, y: 0)
      self.horizontalNameLabel.transform = CGAffineTransform(translationX: -self.bounds.size.width - 30, y: 0)
    }
  }
  
  func setPresetSelected(_ flag: Bool, animated: Bool) {
    let oldValue = isPresetSelected
    isPresetSelected = flag
    if animated {
      if isPresetSelected && oldValue == false && self.window != nil {
        isNameLabelHidden = false
        
        self.nameLabel.transform = CGAffineTransform(translationX: 0, y: +25)
        if location == .left {
          self.horizontalNameLabel.transform = CGAffineTransform(translationX: -50, y: 0)
        }else {
          self.horizontalNameLabel.transform = CGAffineTransform(translationX: +25, y: 0)
        }
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 4, options: [], animations: {
          self.transform = CGAffineTransform(translationX: 0, y: 0)
          self.imageView.transform = CGAffineTransform(translationX: 0, y: -25)
          self.nameLabel.transform = CGAffineTransform(translationX: 0, y: -25)
          if self.location == .left {
            self.horizontalNameLabel.transform = CGAffineTransform(translationX: 0, y: 0)
          }else {
            self.horizontalNameLabel.transform = CGAffineTransform(translationX: -25, y: 0)
          }
          self.nameLabel.alpha = 1
          self.horizontalNameLabel.alpha = 1
        }, completion: nil)
        
        
      }else if isPresetSelected == false && oldValue == true && self.window != nil {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 4, options: [], animations: {
          self.imageView.transform = .identity
          self.nameLabel.transform = CGAffineTransform(translationX: 0, y: +25)
          if self.location == .left {
            self.horizontalNameLabel.transform = CGAffineTransform(translationX: -50, y: 0)

          }else {
            self.horizontalNameLabel.transform = CGAffineTransform(translationX: +25, y: 0)
          }
          self.nameLabel.alpha = 0
          self.horizontalNameLabel.alpha = 0
        }, completion: { _ in
          self.isNameLabelHidden = true
          self.nameLabel.transform = .identity
          self.horizontalNameLabel.transform = .identity
          self.nameLabel.alpha = 1
          self.horizontalNameLabel.alpha = 1
        })
        
      }
    }else {
      if isPresetSelected  {
        self.imageView.transform = CGAffineTransform(translationX: 0, y: -25)
        self.nameLabel.transform = CGAffineTransform(translationX: 0, y: -25)
        if self.location == .left {
          self.horizontalNameLabel.transform = CGAffineTransform(translationX: 0, y: 0)
        }else {
          self.horizontalNameLabel.transform = CGAffineTransform(translationX: -25, y: 0)
        }
        isNameLabelHidden = false
      }else if isPresetSelected == false  {
        self.imageView.transform = .identity
        self.nameLabel.transform = .identity
        self.horizontalNameLabel.transform = .identity
        isNameLabelHidden = true
      }
    }
  }
  
  var textAttributes: [NSAttributedString.Key: Any] {
    let font = UIFont(name: "HiraKakuProN-W3", size: 9) ?? UIFont.systemFont(ofSize: 9)
    return [.foregroundColor: UIColor.secondaryLabel.cgColor, .font: font, .verticalGlyphForm: 1]
  }
  
  var horizontalTextAttributes: [NSAttributedString.Key: Any] {
    let font = UIFont(name: "HiraKakuProN-W3", size: 9) ?? UIFont.systemFont(ofSize: 9)
    return [.foregroundColor: UIColor.secondaryLabel, .font: font, .verticalGlyphForm: 0]
  }
  
  var isNameLabelHidden: Bool {
    set {
      if location == .bottom || location == .top {
        nameLabel.alpha = 1
        nameLabel.isHidden = newValue
      }else {
        horizontalNameLabel.alpha = 1
        horizontalNameLabel.isHidden = newValue
      }
    }
    get {
      if location == .bottom || location == .top {
        return nameLabel.isHidden
      }else {
        return horizontalNameLabel.isHidden
      }
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    contentView.backgroundColor = UIColor.clear
    
    let containerView = UIView(frame: contentView.bounds)
    containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    containerView.backgroundColor = .clear
    self.containerView = containerView
    contentView.addSubview(containerView)
    
    let frame = CGRect(x: 0, y: 10.0, width: frame.size.width, height: frame.size.height)
    let imageView = UIImageView(frame: frame)
    imageView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
    imageView.isUserInteractionEnabled = false
    imageView.contentMode = .top
    self.imageView = imageView
    containerView.addSubview(imageView)
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowRadius = 7.0
    layer.shadowOpacity = 0.1
    layer.shadowOffset = CGSize(width: 0, height: 3)
    
    var labelFrame = CGRect(x: frame.size.width-10.0, y: 25.0, width: 15, height: frame.size.height + 25)
    let label = PalletteTabVerticalTextLabel(frame: labelFrame)
    label.autoresizingMask = [.flexibleLeftMargin, .flexibleHeight]
    label.isUserInteractionEnabled = false
    label.isHidden = true
    label.backgroundColor = .clear
    label.attributedString = NSAttributedString(string: "", attributes: textAttributes)

    containerView.addSubview(label)
    nameLabel = label
    
    labelFrame = CGRect(x: -16, y: -8, width: frame.size.width - 10, height: 15)
    let hlabel = UILabel(frame: labelFrame)
    hlabel.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
    hlabel.isUserInteractionEnabled = false
    hlabel.isHidden = true
    hlabel.backgroundColor = .clear
    hlabel.attributedText = NSAttributedString(string: "", attributes: horizontalTextAttributes)
    
    contentView.addSubview(hlabel)
    horizontalNameLabel = hlabel
    

  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    imageView.transform = .identity
    nameLabel.transform = .identity
    horizontalNameLabel.transform = .identity
    nameLabel.attributedString = NSAttributedString(string: "")
    horizontalNameLabel.attributedText = nil
    tag = 0
    nameLabel.isHidden = false
    containerView?.transform = .identity
  }

}

@available(iOS 13.4,*)
protocol PaletteTabViewSource: NSObjectProtocol {
  
  func presetsForTabView(_ : PaletteTabView) -> [StylusPreset]
  func tabView(_ : PaletteTabView, didSelectItemAt: Int?) -> Bool
  func tabView(_ : PaletteTabView, willSelectItemAt: Int?)

  func tabViewCanAddNewItem(_ : PaletteTabView) -> Bool

  func tabViewIndexOfSelection(_ : PaletteTabView) -> Int?
  func tabView(_ : PaletteTabView, moveItemAt: Int, to: Int)
  func tabView(_ : PaletteTabView, removeItemAt: Int) -> Bool

  func tabView(_ : PaletteTabView, canDragAt: IndexPath) -> Bool
  func tabViewDraggingWillStart(_ : PaletteTabView)
  func tabViewDraggingWillEnd(_ : PaletteTabView)
  func tabViewDraggingDidEnd(_ : PaletteTabView)

  func tabView(_ : PaletteTabView, canRemoveItemAt: IndexPath) -> Bool
  
}

@available(iOS 13.4,*)
protocol PaletteTabViewDelegate: NSObjectProtocol {
  func tabView(_: PaletteTabView, createNewFrom: UICollectionViewCell)

}

@available(iOS 13.4,*)
public class PaletteTabView: UIView {
  
  static let dragType = "com.catalystwo.PaletteTabView.dragging"

  weak var dataSource: PaletteTabViewSource? = nil
  weak var delegate: PaletteTabViewDelegate? = nil

  var flowLayout: UICollectionViewFlowLayout!
  weak var collectionView: UICollectionView!
  var showsToolLabel: Bool = true

  var darkMode = false {
    didSet {
      reload()
    }
  }
  
  var convertDarkColor = false

  var tabs: [StylusPreset] {
    get {
      return dataSource?.presetsForTabView(self) ?? []
    }
  }
  var location: PaletteViewModel.Location = .bottom {
    didSet {
      flowLayout.scrollDirection = (location == .bottom || location == .top) ? .horizontal : .vertical
      reload()
    }
  }
  private var dropTargetIndexPath: IndexPath? = nil
  private var dragSourceIndexPath: IndexPath? = nil

  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  func setup() {
    self.isOpaque = false
    self.clipsToBounds = false
    flowLayout = LXReorderableCollectionViewFlowLayout()
    flowLayout.scrollDirection = .horizontal
    flowLayout.minimumLineSpacing = 0.0;
    flowLayout.minimumInteritemSpacing = 5.0;
    flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 5.0, bottom: 0, right: 5.0)
    
    // COLLECTION VIEW
    var bounds = self.bounds
    bounds.size.height = 64
    
    let collectionView = UICollectionView(frame: bounds, collectionViewLayout: flowLayout)
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.bounces = true
    collectionView.allowsSelection = true
    collectionView.allowsMultipleSelection = false
    collectionView.showsVerticalScrollIndicator = false
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.delaysContentTouches = false
    collectionView.isOpaque = false
    collectionView.backgroundColor = .clear
    collectionView.clipsToBounds = false
    
//    collectionView.dragInteractionEnabled = true
//    collectionView.dragDelegate = self
//    collectionView.dropDelegate = self

    collectionView.register(StylusPresetCell.self, forCellWithReuseIdentifier: "Cell")
    
    
    self.addSubview(collectionView)
    self.collectionView = collectionView
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    collectionView.frame = bounds
    if location == .left || location == .right {
      let viewHeight = self.bounds.width
      flowLayout.itemSize = CGSize(width: viewHeight, height: 60)
      
    }else {
      let viewHeight = self.bounds.height
      flowLayout.itemSize = CGSize(width: 60, height: viewHeight)
    }
    flowLayout.invalidateLayout()
  }
  
  func poof() -> UIImageView {
    let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    view.animationImages = [UIImage(named: "poof1", in: Bundle(for: Stylus.self), compatibleWith: nil)!, UIImage(named: "poof2", in: Bundle(for: Stylus.self), compatibleWith: nil)!,UIImage(named: "poof3", in: Bundle(for: Stylus.self), compatibleWith: nil)!,UIImage(named: "poof4", in: Bundle(for: Stylus.self), compatibleWith: nil)!,UIImage(named: "poof5", in: Bundle(for: Stylus.self), compatibleWith: nil)!,UIImage(named: "poof6", in: Bundle(for: Stylus.self), compatibleWith: nil)!]
    view.animationDuration = 0.5
    view.animationRepeatCount = 1;
    view.startAnimating()
    return view
  }
  
  func reload() {
    collectionView.reloadData()
  }
  
  func selectedCell() -> UICollectionViewCell? {
    guard let selectedIndex = dataSource?.tabViewIndexOfSelection(self) else { return nil }

    return collectionView.cellForItem(at: IndexPath(row: selectedIndex, section: 0))
  }

  var didCreateCellIndex: Int? = nil
  func didCreateCell(at index: Int) {
    didCreateCellIndex = index
  }
  
  func revealCreatedCell(at index: Int) {
    let indexPath = IndexPath(row: index, section: 0)
    let cell = collectionView.cellForItem(at: indexPath) as? StylusPresetCellProtocol & UICollectionViewCell
    let currentSelectedCell = selectedCell() as? StylusPresetCellProtocol & UICollectionViewCell
    
    didCreateCellIndex =  nil
    if cell !== currentSelectedCell {
      cell?.wasJustCreated()
      cell?.setPresetSelected(true, animated: true)
      currentSelectedCell?.setPresetSelected(false, animated: true)
    }
    
    cell?.isHidden = false
  }
  
  
}

@available(iOS 13.4,*)
extension PaletteTabView: UIPointerInteractionDelegate {

  func customPointerInteraction(on view: UICollectionViewCell, pointerInteractionDelegate: UIPointerInteractionDelegate){
    
    let existing = view.interactions.filter { $0 is UIPointerInteraction }
    if existing.count == 0 {
      let pointerInteraction = UIPointerInteraction(delegate: pointerInteractionDelegate)
      view.addInteraction(pointerInteraction)
    }
  }
  
  public func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
    var pointerStyle: UIPointerStyle?
    //    print("pointerInteraction view", interaction.view!)
    if let interactionView = interaction.view as? StylusPresetCell {
      let targetedPreview = UITargetedPreview(view: interactionView)
      pointerStyle = UIPointerStyle(effect: UIPointerEffect.hover(targetedPreview, preferredTintMode: .none, prefersShadow: false, prefersScaledContent: false))
      
    }
    return pointerStyle
  }
  
  public func pointerInteraction(_ interaction: UIPointerInteraction, willEnter region: UIPointerRegion, animator: UIPointerInteractionAnimating) {
    if let interactionView = interaction.view as? StylusPresetCell {
      
      if interactionView.isPresetSelected {
      }else {
        
#if targetEnvironment(macCatalyst)
        UIView.animate(withDuration: 0.1) {
          switch self.location {
          case .left: interactionView.transform = CGAffineTransform(translationX: 5, y: 0)
          case .right: interactionView.transform = CGAffineTransform(translationX: -5, y: 0)
          case .top: interactionView.transform = CGAffineTransform(translationX: 0, y: -5)
          case .bottom: interactionView.transform = CGAffineTransform(translationX: 0, y: -5)
          }
        }
        
#else
        animator.addAnimations {
          switch self.location {
          case .left: interactionView.transform = CGAffineTransform(translationX: 5, y: 0)
          case .right: interactionView.transform = CGAffineTransform(translationX: -5, y: 0)
          case .top: interactionView.transform = CGAffineTransform(translationX: 0, y: -5)
          case .bottom: interactionView.transform = CGAffineTransform(translationX: 0, y: -5)
          }
        }
        
#endif
      }
    }
  }
  
  public func pointerInteraction(_ interaction: UIPointerInteraction, willExit region: UIPointerRegion, animator: UIPointerInteractionAnimating) {
    if let interactionView = interaction.view as? StylusPresetCell {
      
#if targetEnvironment(macCatalyst)
      UIView.animate(withDuration: 0.1) {
        interactionView.transform = .identity
      }
#else
      animator.addAnimations {
        interactionView.transform = .identity
      }
#endif
    }
  }
}

@available(iOS 13.4,*)
extension PaletteTabView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    if dataSource?.tabViewCanAddNewItem(self) == false { return 1 }
    return 2
  }
  
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if section == 1 { return 1 }
    return tabs.count
  }
  
  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let item = indexPath.item
    let cell: UICollectionViewCell & StylusPresetCellProtocol
    
    cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! UICollectionViewCell & StylusPresetCellProtocol
    
    (cell as? StylusPresetCell)?.location = location
    
    if indexPath.section == 1 {
      
      cell.image = UIImage(named:darkMode ? "PenNewDark" : "PenNew", in: Bundle(for: Stylus.self), compatibleWith: nil)
      cell.setPresetSelected(false, animated: false)
      customPointerInteraction(on: cell.self, pointerInteractionDelegate: self)
      
      return cell
    }
    let tabs = self.tabs
    if item >= tabs.count { return cell }
    cell.image = tabs[item].image(dark: darkMode, convertDarkColor: convertDarkColor)
    if showsToolLabel {
      cell.name = tabs[item].name
      
    }else {
      cell.name = ""
      
    }
    let selected = (dataSource?.tabViewIndexOfSelection(self) == item)
    cell.setPresetSelected(selected, animated: false)
    
    cell.isNameLabelHidden = !selected
    
    if didCreateCellIndex == indexPath.row {
      cell.isHidden = true
    }
    
    customPointerInteraction(on: cell.self, pointerInteractionDelegate: self)
    
    return cell
  }
  
  
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    if location == .left || location == .right {
      return UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
    }
    return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
  }
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    if location == .left || location == .right {
      let itemWidth = collectionView.bounds.size.width - 0
      
      let image = tabs[indexPath.item].image(convertDarkColor: convertDarkColor)
      let size = image.size
      
      return CGSize(width: itemWidth, height: size.width);

    }else {
      let itemHeight: CGFloat = collectionView.bounds.size.height
      
//      if location == .bottom {
//        itemHeight = collectionView.bounds.size.height - 0 + (safeAreaInsets.bottom)
//      }else {
//        itemHeight = collectionView.bounds.size.height - 0 + (safeAreaInsets.top)
//      }
      
      let image = tabs[indexPath.item].image(convertDarkColor: convertDarkColor)
      let size = image.size
      
      return CGSize(width: size.width, height: itemHeight);
    }
  }
  
  public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    
    return true
  }
  
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let cell = collectionView.cellForItem(at: indexPath) as? StylusPresetCellProtocol & UICollectionViewCell
    let currentSelectedCell = selectedCell() as? StylusPresetCellProtocol & UICollectionViewCell
    
    if indexPath.section == 1 {
      if cell != nil {
        let selectedIndex = dataSource?.tabViewIndexOfSelection(self)
        delegate?.tabView(self, createNewFrom: cell!)
//        if selectedIndex != nil {
//        let currentSelectedCell = collectionView.cellForItem(at: IndexPath(row: selectedIndex!, section: 0)) as? StylusPresetCellProtocol & UICollectionViewCell
//
//        currentSelectedCell?.setPresetSelected(false, animated: true)
//        }
      }
      
    }else {
      guard let success = dataSource?.tabView(self, didSelectItemAt: indexPath.item) else { return }
      
      if success && cell !== currentSelectedCell {
        cell?.setPresetSelected(true, animated: true)
        currentSelectedCell?.setPresetSelected(false, animated: true)
      }
      
      if success == false {
        cell?.setPresetSelected(true, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          cell?.setPresetSelected(false, animated: true)
        }

      }
    }
    

  }

  public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
    if indexPath.section == 1 {
  
    }else {
      dataSource?.tabView(self, willSelectItemAt: indexPath.item)
      
    }
    return true
    
  }
 
//  public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//    let item = tabs[indexPath.item]
//    guard item.mode == .alphaPen || item.mode == .brushPen || item.mode == .pencil || item.mode == .pen else { return nil }
//
//
//
//    let configuration = UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { [weak self] action in
//
//      var menus: [UIMenuElement] = []
//
//      if item.mode == .alphaPen || item.mode == .brushPen || item.mode == .pencil || item.mode == .pen {
//
//        let jump = UIAction(title: "削除", image: UIImage(systemName: "trash"), identifier: nil, attributes: .destructive, handler: { [weak self] action in
//
//          if self?.dataSource?.tabView(self!, removeItemAt: indexPath.row) == true {
//            self?.reload()
//          }
//        })
//        menus.append(jump)
//      }
//      return UIMenu(title: "長押し＆左右にドラッグして順番を入れ替えできます。", image: nil, identifier: nil, children: menus)
//    }
//
//    return configuration
//  }
}

@available(iOS 13.4,*)
extension PaletteTabView: LXReorderableCollectionViewDataSource, LXReorderableCollectionViewDelegateFlowLayout {
  public func collectionView(_ collectionView: UICollectionView!, itemAt fromIndexPath: IndexPath!, willMoveTo toIndexPath: IndexPath!) {

  }

  public func collectionView(_ collectionView: UICollectionView!, itemAt fromIndexPath: IndexPath!, didMoveTo toIndexPath: IndexPath!) {
    dataSource?.tabView(self, moveItemAt: fromIndexPath.item, to: toIndexPath.item)
  }

  public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
    // DRAGGING START
    if tabs.count <= 1 { return false }
    if indexPath.isEmpty { return false } // AVOID CRASH
    let canDrag = indexPath.section == 0 //Thread 1: EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, su

    if canDrag {
      if dataSource?.tabView(self, canDragAt: indexPath) == false { return false }

      let cell = collectionView.cellForItem(at: indexPath) as? StylusPresetCellProtocol & UICollectionViewCell
      cell?.isNameLabelHidden = true
      dataSource?.tabViewDraggingWillStart(self)
    }

    return canDrag
  }

  public func collectionView(_ collectionView: UICollectionView!, itemAt fromIndexPath: IndexPath!, canMoveTo toIndexPath: IndexPath!) -> Bool {
    return toIndexPath.section == 0
  }


  public func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, willEndDraggingItemAt indexPath: IndexPath!) -> Bool {
    // DRAGGING WILL END
    dataSource?.tabViewDraggingWillEnd(self)

    let canRemove = dataSource?.tabView(self, canRemoveItemAt: indexPath)
    var point = (flowLayout.value(forKeyPath: "currentView.center") as! NSValue).cgPointValue
    point = collectionView.convert(point, from: nil)
    if canRemove == true {

      if ((location == .bottom||location == .top) && (point.y < 0 || point.y > self.bounds.size.height)) ||
          ((location == .left||location == .right) && (point.x < 0 || point.x > self.bounds.size.width)) {
        let p = collectionView.convert(point, to: self.window!)
        let poofImage = poof()
        poofImage.center = p
        self.window?.addSubview(poofImage)

        if self.dataSource?.tabView(self, removeItemAt: indexPath.row) == true {
          self.reload()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
          poofImage.removeFromSuperview()

        }


        return true
      }
    }
    return false
  }

  public func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, didEndDraggingItemAt indexPath: IndexPath!)  {

    dataSource?.tabViewDraggingDidEnd(self)
    reload()
  }

}

//// MARK: - UICollectionViewDragDelegate
//@available(iOS 13.4, *)
//extension PaletteTabView: UICollectionViewDragDelegate {
//  public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
//
//    if tabs.count <= 1 { return [] }
//    if indexPath.isEmpty { return [] } // AVOID CRASH
//    if collectionView.hasActiveDrag { return [] }
//
//    let canDrag = indexPath.section == 0 //Thread 1: EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, su
//
//    if canDrag {
//      if dataSource?.tabView(self, canDragAt: indexPath) == false { return [] }
//
//      guard let cell = collectionView.cellForItem(at: indexPath) as? StylusPresetCellProtocol & UICollectionViewCell else { return [] }
//      cell.isNameLabelHidden = true
//      dataSource?.tabViewDraggingWillStart(self)
//
//      let obj = cell.name
//
//      let itemProvider = NSItemProvider()
//
//      itemProvider.registerDataRepresentation(forTypeIdentifier: PaletteTabView.dragType, visibility: .ownProcess) { completion in
//        completion(nil, nil)
//        return nil
//      }
//
//      dragSourceIndexPath = indexPath
//      return [UIDragItem(itemProvider: itemProvider)]
//
//    }
//
//    return []
//  }
//
//  public func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
//    if collectionView.isTracking { return false }
//    return session.hasItemsConforming(toTypeIdentifiers: [PaletteTabView.dragType])
//  }
//
//  public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
//    if destinationIndexPath?.section == 1  {
//      return UICollectionViewDropProposal(operation: .cancel)
//    }
//
//    if collectionView.hasActiveDrag {
//      return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
//    }else {
//      if dropTargetIndexPath != destinationIndexPath {
//        dropTargetIndexPath = destinationIndexPath
//      }
//
//      return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
//    }
//  }
//
//  public func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
//    dataSource?.tabViewDraggingWillStart(self)
//  }
//
//  public func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
//    dataSource?.tabViewDraggingWillEnd(self)
//
//
//    if session.localContext as? String == "dropped" && dragSourceIndexPath != nil {
//      if self.dataSource?.tabView(self, removeItemAt: dragSourceIndexPath!.row) == true {
//        //        self.reload()
//      }
//
//    }
//
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//      self.reload()
//    }
//
//    dataSource?.tabViewDraggingDidEnd(self)
//  }
//}
//
//// MARK: - UICollectionViewDropDelegate
//@available(iOS 13.4, *)
//extension PaletteTabView: UICollectionViewDropDelegate {
//
//
//  public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
//    //    dropTargetIndexPath = nil
//    guard let item = coordinator.items.first else { return }
//
//    if collectionView.hasActiveDrag == true {
//
//      if let dragSourceIndexPath = dragSourceIndexPath {
//        coordinator.session.localDragSession?.localContext = "self"
//
//        var destinationIndexPath = coordinator.destinationIndexPath
//        if destinationIndexPath == nil || destinationIndexPath?.section == 1 {
//          destinationIndexPath = IndexPath(item: tabs.count-1, section: 0)
//          //          delegate?.lawTabView(self, moveItemAt: dragSourceIndexPath.item, to: destinationIndexPath!.item)
//          //          reload()
//          //          return
//        }
//
//        dataSource?.tabView(self, moveItemAt: dragSourceIndexPath.item, to: destinationIndexPath!.item)
//
//        collectionView.performBatchUpdates({
//          collectionView.deleteItems(at: [dragSourceIndexPath])
//          collectionView.insertItems(at: [destinationIndexPath!])
//        }) { (_) in
//          coordinator.drop(item.dragItem, toItemAt: destinationIndexPath!)
//        }
//      }
//    }else if let destinationIndexPath = coordinator.destinationIndexPath {
//
//      coordinator.session.localDragSession?.localContext = "dropped"
//
//    }
//    else {
//
//    }
//  }
//
//  public func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: UIDropSession) {
//
//  }
//
//  public func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: UIDropSession) {
//    dropTargetIndexPath = nil
//  }
//
//  public func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
//    //dropTargetIndexPath = nil
//  }
//
//}
