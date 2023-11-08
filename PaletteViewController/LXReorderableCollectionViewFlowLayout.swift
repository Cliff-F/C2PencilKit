//
//  LXReorderableCollectionViewFlowLayout.swift
//  PaletteViewController
//
//  Created by Masatoshi Nishikata on 14/08/23.
//  Copyright © 2023 Catalystwo Limited. All rights reserved.
//

import Foundation
import UIKit


protocol LXReorderableCollectionViewDataSource: UICollectionViewDataSource {
  // Optional methods
  func collectionView(_ collectionView: UICollectionView, itemAt fromIndexPath: IndexPath, willMoveTo toIndexPath: IndexPath)
  func collectionView(_ collectionView: UICollectionView, itemAt fromIndexPath: IndexPath, didMoveTo toIndexPath: IndexPath)
  func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool
  func collectionView(_ collectionView: UICollectionView, itemAt fromIndexPath: IndexPath, canMoveTo toIndexPath: IndexPath) -> Bool
}

protocol LXReorderableCollectionViewDelegateFlowLayout: UICollectionViewDelegateFlowLayout {
  // Optional methods
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, willBeginDraggingItemAt indexPath: IndexPath)
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, didBeginDraggingItemAt indexPath: IndexPath)
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, willEndDraggingItemAt indexPath: IndexPath) -> Bool
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, didEndDraggingItemAt indexPath: IndexPath)
}



let LX_FRAMES_PER_SECOND: CGFloat = 60.0
let DRAGGING_VIEW_SCALE: CGFloat = 1.5

func LXS_CGPointAdd(_ point1: CGPoint, _ point2: CGPoint) -> CGPoint {
  return CGPoint(x: point1.x + point2.x, y: point1.y + point2.y)
}


enum LXScrollingDirection: Int {
  case unknown = 0
  case up
  case down
  case left
  case right
}

let kLXScrollingDirectionKey = "LXScrollingDirection"
let kLXCollectionViewKeyPath = "collectionView"

class CADisplayLinkWithUserInfo: CADisplayLink {
  var LX_userInfo: [String: Any]?
}

extension UICollectionViewCell {
  func LX_rasterizedImage(withTopPadding topPadding: CGFloat, bottomPadding: CGFloat) -> UIImage? {
    let size = CGSize(width: bounds.size.width, height: bounds.size.height + topPadding + bottomPadding)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    defer { UIGraphicsEndImageContext() }
    
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    
    context.translateBy(x: 0, y: topPadding)
    context.clear(bounds)
    layer.render(in: context)
    
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}

class LXReorderableCollectionViewFlowLayout: UICollectionViewFlowLayout, UIGestureRecognizerDelegate {
  var selectedItemIndexPath: IndexPath?
  var currentView: UIView?
  var currentViewCenter: CGPoint = .zero
  var panTranslationInCollectionView: CGPoint = .zero
  var displayLink: CADisplayLink?
  
  
  var scrollingSpeed: CGFloat = 300.0
  var scrollingTriggerEdgeInsets = UIEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0)
  
  private(set) var longPressGestureRecognizer: UILongPressGestureRecognizer!
  private(set) var panGestureRecognizer: UIPanGestureRecognizer!
  
  
  func setDefaults() {
    scrollingSpeed = 300.0
    scrollingTriggerEdgeInsets = UIEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0)
    
    itemSize = CGSize(width: 80, height: 80)
  }

  func setupCollectionView() {
    guard let collectionView = collectionView else { return }
    longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
    longPressGestureRecognizer.delegate = self
    
    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
    // by enforcing failure dependency so that they don't clash.
    for gestureRecognizer in collectionView.gestureRecognizers ?? [] {
      if let longPress = gestureRecognizer as? UILongPressGestureRecognizer {
        longPress.require(toFail: longPressGestureRecognizer)
      }
    }
    
    collectionView.addGestureRecognizer(longPressGestureRecognizer)
    
    panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    panGestureRecognizer.delegate = self
    collectionView.addGestureRecognizer(panGestureRecognizer)
    
    // Useful in multiple scenarios: one common scenario being when the Notification Center drawer is pulled down
    NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
  }

  override init() {
    super.init()
    setDefaults()
    addObserver(self, forKeyPath: kLXCollectionViewKeyPath, options: .new, context: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setDefaults()
    addObserver(self, forKeyPath: kLXCollectionViewKeyPath, options: .new, context: nil)
  }
  
  deinit {
    invalidatesScrollTimer()
    removeObserver(self, forKeyPath: kLXCollectionViewKeyPath)
    NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
  }
  
  func applyLayoutAttributes(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    if layoutAttributes.indexPath == selectedItemIndexPath {
      layoutAttributes.isHidden = true
    }
  }
  
  var dataSource: LXReorderableCollectionViewDataSource? {
    return collectionView?.dataSource as? LXReorderableCollectionViewDataSource
  }
  
  var delegate: LXReorderableCollectionViewDelegateFlowLayout? {
    return collectionView?.delegate as? LXReorderableCollectionViewDelegateFlowLayout
  }

  func invalidateLayoutIfNecessary() {
    guard let currentView = currentView else { return }
    guard let collectionView = collectionView else { return }

    let center = collectionView.convert(currentView.center, from: nil)
    
    if let newIndexPath = collectionView.indexPathForItem(at: center),
       let previousIndexPath = selectedItemIndexPath,
       newIndexPath != previousIndexPath {
      
      if let dataSource = dataSource,
         true == dataSource.collectionView(collectionView, itemAt: previousIndexPath, canMoveTo: newIndexPath) {
        
        selectedItemIndexPath = newIndexPath
        
        dataSource.collectionView(collectionView, itemAt: previousIndexPath, willMoveTo: newIndexPath)
        
        collectionView.performBatchUpdates({
          collectionView.deleteItems(at: [previousIndexPath])
          collectionView.insertItems(at: [newIndexPath])
        }, completion: { [weak self] finished in
          guard let self = self, let dataSource = self.dataSource else { return }
          dataSource.collectionView(collectionView, itemAt: previousIndexPath, didMoveTo: newIndexPath)
          // Completion block executed after the batch updates
          
        })
        
      }
    }
  }
  
  func invalidatesScrollTimer() {
    if displayLink?.isPaused == false {
      displayLink?.invalidate()
    }
    displayLink = nil
  }

  func setupScrollTimer(in direction: LXScrollingDirection) {
    if displayLink?.isPaused == false, let oldDirection = displayLink?.LX_userInfo[kLXScrollingDirectionKey] as? LXScrollingDirection, direction == oldDirection {
      return
    }
    
    invalidatesScrollTimer()
    
    displayLink = CADisplayLink(target: self, selector: #selector(handleScroll(_:)))
    displayLink?.preferredFramesPerSecond = 0
    displayLink?.LX_userInfo = [kLXScrollingDirectionKey: direction.rawValue]
    
    displayLink?.add(to: .main, forMode: .common)
  }

  @objc func handleScroll(_ displayLink: CADisplayLink) {
    guard let collectionView = collectionView else { return }

    guard let directionRawValue = displayLink?.LX_userInfo[kLXScrollingDirectionKey] as? Int,
          let direction = LXScrollingDirection(rawValue: directionRawValue) else {
      return
    }
    
    let frameSize = collectionView.bounds.size
    let contentSize = collectionView.contentSize
    var contentOffset = collectionView.contentOffset
    let contentInset = collectionView.contentInset
    
    var distance = rint(scrollingSpeed / LX_FRAMES_PER_SECOND)
    var translation = CGPoint.zero
    
    switch direction {
    case .up:
      distance = -distance
      let minY = 0.0 - contentInset.top
      
      if (contentOffset.y + distance) <= minY {
        distance = -contentOffset.y - contentInset.top
      }
      
      translation = CGPoint(x: 0.0, y: distance)
    case .down:
      let maxY = max(contentSize.height, frameSize.height) - frameSize.height + contentInset.bottom
      
      if (contentOffset.y + distance) >= maxY {
        distance = maxY - contentOffset.y
      }
      
      translation = CGPoint(x: 0.0, y: distance)
    case .left:
      distance = -distance
      let minX = 0.0 - contentInset.left
      
      if (contentOffset.x + distance) <= minX {
        distance = -contentOffset.x - contentInset.left
      }
      
      translation = CGPoint(x: distance, y: 0.0)
    case .right:
      let maxX = max(contentSize.width, frameSize.width) - frameSize.width + contentInset.right
      
      if (contentOffset.x + distance) >= maxX {
        distance = maxX - contentOffset.x
      }
      
      translation = CGPoint(x: distance, y: 0.0)
    default:
      // Do nothing...
      break
    }
    
    currentViewCenter = LXS_CGPointAdd(currentViewCenter, translation)
    currentView.center = LXS_CGPointAdd(currentViewCenter, panTranslationInCollectionView)
    contentOffset = LXS_CGPointAdd(contentOffset, translation)
    collectionView.contentOffset = contentOffset
  }

  
  @objc func handleLongPressGesture(_ gestureRecognizer: UILongPressGestureRecognizer) {
    guard let collectionView = collectionView else { return }

    switch gestureRecognizer.state {
    case .began:
      guard let currentIndexPath = collectionView.indexPathForItem(at: gestureRecognizer.location(in: collectionView)) else {
        return
      }
      
      if dataSource?.collectionView?(collectionView, canMoveItemAtIndexPath: currentIndexPath) == false {
        return
      }
      
      AudioServicesPlaySystemSound(1519)
      
      selectedItemIndexPath = currentIndexPath
      
      if delegate?.collectionView?(collectionView, layout: self, willBeginDraggingItemAtIndexPath: selectedItemIndexPath) != nil {
        delegate?.collectionView?(collectionView, layout: self, willBeginDraggingItemAtIndexPath: selectedItemIndexPath)
      }
      
      if let collectionViewCell = collectionView.cellForItem(at: selectedItemIndexPath) as? UICollectionViewCell {
        var topPadding: CGFloat = 0
        
        if collectionViewCell.tag == 1 {
          topPadding = 25
        }
        
        currentView = UIView(frame: collectionViewCell.frame)
        currentView.opaque = false
        currentView.clipsToBounds = false
        currentView.backgroundColor = .clear
        collectionViewCell.isHighlighted = true
        let thumbnail = collectionViewCell.LX_rasterizedImageWithExtraPadding(onTop: topPadding, bottom: 40)
        
        let highlightedImageView = UIImageView(image: thumbnail)
        highlightedImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        highlightedImageView.alpha = 1.0
        highlightedImageView.isOpaque = false
        highlightedImageView.backgroundColor = .clear
        highlightedImageView.frame = CGRect(x: 0, y: -topPadding, width: thumbnail.size.width, height: thumbnail.size.height)
        
        collectionViewCell.isHighlighted = false
        let imageView = UIImageView(image: thumbnail)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.alpha = 0.0
        imageView.isOpaque = false
        imageView.backgroundColor = .clear
        imageView.frame = CGRect(x: 0, y: -topPadding, width: thumbnail.size.width, height: thumbnail.size.height)
        currentView.addSubview(imageView)
        currentView.addSubview(highlightedImageView)
        collectionView.window?.addSubview(currentView)
        
        var center = collectionView.convert(currentView.center, to: nil)
        currentView.center = center
        currentViewCenter = center
        imageView.transform = CGAffineTransform(translationX: 0, y: 0)
        highlightedImageView.transform = CGAffineTransform(translationX: 0, y: 0)
        currentView.transform = CGAffineTransform(translationX: 0, y: 0)
        
        weak var weakSelf = self
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .beginFromCurrentState, animations: {
          if let strongSelf = weakSelf {
            strongSelf.currentView.transform = strongSelf.currentView.transform.scaledBy(x: DRAGGING_VIEW_SCALE, y: DRAGGING_VIEW_SCALE)
            highlightedImageView.alpha = 0.0
            imageView.alpha = 0.8
          }
        }, completion: { finished in
          if let strongSelf = weakSelf {
            highlightedImageView.removeFromSuperview()
            if let delegate = strongSelf.delegate, delegate.collectionView?(strongSelf.collectionView, layout: strongSelf, didBeginDraggingItemAtIndexPath: strongSelf.selectedItemIndexPath) != nil {
              delegate.collectionView?(strongSelf.collectionView, layout: strongSelf, didBeginDraggingItemAtIndexPath: strongSelf.selectedItemIndexPath)
            }
          }
        })
        
        invalidateLayout()
      }
    case .cancelled, .ended:
      guard let currentIndexPath = selectedItemIndexPath else {
        return
      }
      
      if delegate?.collectionView?(collectionView, layout: self, willEndDraggingItemAtIndexPath: currentIndexPath) != nil {
        if delegate?.collectionView?(collectionView, layout: self, willEndDraggingItemAtIndexPath: currentIndexPath) == true {
          currentView.removeFromSuperview()
          currentView = nil
          selectedItemIndexPath = nil
          invalidateLayout()
          
          if let delegate = delegate, delegate.collectionView?(collectionView, layout: self, didEndDraggingItemAtIndexPath: currentIndexPath) != nil {
            delegate.collectionView?(collectionView, layout: self, didEndDraggingItemAtIndexPath: currentIndexPath)
          }
          return
        }
      }
      
      selectedItemIndexPath = nil
      currentViewCenter = .zero
      
      if let layoutAttributes = layoutAttributesForItem(at: currentIndexPath) {
        weak var weakSelf = self
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .beginFromCurrentState, animations: {
          if let strongSelf = weakSelf {
            strongSelf.currentView.transform = .identity
            strongSelf.currentView.center = strongSelf.collectionView.convert(layoutAttributes.center, to: nil)
          }
        }, completion: { finished in
          if let strongSelf = weakSelf {
            strongSelf.invalidateLayout()
            strongSelf.currentView.alpha = 0
            strongSelf.currentView.removeFromSuperview()
            strongSelf.currentView = nil
            if let delegate = strongSelf.delegate, delegate.collectionView?(strongSelf.collectionView, layout: strongSelf, didEndDraggingItemAtIndexPath: currentIndexPath) != nil {
              delegate.collectionView?(strongSelf.collectionView, layout: strongSelf, didEndDraggingItemAtIndexPath: currentIndexPath)
            }
          }
        })
      }
    default:
      break
    }
  }

  @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
    guard let collectionView = collectionView else { return }

    switch gestureRecognizer.state {
    case .began, .changed:
      panTranslationInCollectionView = gestureRecognizer.translation(in: collectionView)
      var viewCenter = currentViewCenter + panTranslationInCollectionView
      currentView.center = viewCenter
      
      viewCenter = collectionView.convert(viewCenter, from: nil)
      
      invalidateLayoutIfNecessary()
      
      switch scrollDirection {
      case .vertical:
        if viewCenter.y < (collectionView.bounds.minY + scrollingTriggerEdgeInsets.top) {
          setupScrollTimerInDirection(.up)
        } else {
          if viewCenter.y > (collectionView.bounds.maxY - scrollingTriggerEdgeInsets.bottom) {
            setupScrollTimerInDirection(.down)
          } else {
            invalidatesScrollTimer()
          }
        }
      case .horizontal:
        if viewCenter.x < (collectionView.bounds.minX + scrollingTriggerEdgeInsets.left) {
          setupScrollTimerInDirection(.left)
        } else {
          if viewCenter.x > (collectionView.bounds.maxX - scrollingTriggerEdgeInsets.right) {
            setupScrollTimerInDirection(.right)
          } else {
            invalidatesScrollTimer()
          }
        }
      }
    case .cancelled, .ended:
      invalidatesScrollTimer()
    default:
      break
    }
  }

  // MARK: - UICollectionViewLayout overridden methods
  
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var layoutAttributesForElementsInRect = super.layoutAttributesForElements(in: rect)
    
    for layoutAttributes in layoutAttributesForElementsInRect ?? [] {
      switch layoutAttributes.representedElementCategory {
      case .cell:
        applyLayoutAttributes(layoutAttributes)
      default:
        break
      }
    }
    
    return layoutAttributesForElementsInRect
  }
  
  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    var layoutAttributes = super.layoutAttributesForItem(at: indexPath)
    
    switch layoutAttributes?.representedElementCategory {
    case .cell?:
      applyLayoutAttributes(layoutAttributes!)
    default:
      break
    }
    
    return layoutAttributes
  }
  
  // MARK: - UIGestureRecognizerDelegate methods
  
  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer.isEqual(panGestureRecognizer) {
      return selectedItemIndexPath != nil
    }
    return true
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer.isEqual(longPressGestureRecognizer) {
      return otherGestureRecognizer.isEqual(panGestureRecognizer)
    }
    
    if gestureRecognizer.isEqual(panGestureRecognizer) {
      return otherGestureRecognizer.isEqual(longPressGestureRecognizer)
    }
    
    return false
  }
  
  // MARK: - Key-Value Observing methods
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == kLXCollectionViewKeyPath {
      if collectionView != nil {
        setupCollectionView()
      } else {
        invalidatesScrollTimer()
      }
    }
  }
  
  // MARK: - Notifications
  
  @objc func handleApplicationWillResignActive(_ notification: Notification) {
    panGestureRecognizer.isEnabled = false
    panGestureRecognizer.isEnabled = true
  }
  
  // MARK: - Deprecated methods
  
  // Starting from 0.1.0
  @available(*, deprecated, message: "This method is deprecated starting from 0.1.0")
  func setUpGestureRecognizersOnCollectionView() {
    // Do nothing...
  }

}

