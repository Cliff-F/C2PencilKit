//
//  PalettDetailViewController.swift
//  TextureDraw2-iOS
//
//  Created by Masatoshi Nishikata on 22/08/19.
//  Copyright © 2019 Catalystwo Limited. All rights reserved.
//

import Foundation
import UIKit
import ColorPicker

class PaletteDetailViewController: UIViewController {
  weak var delegate: PaletteCustomising?
  var inkSpeed: Float = 0
  var pressure: Float = 0
  var initialPressureCutoff: Float = 0
  var ratio: Float = 0
  
  @IBOutlet weak var pressureSlider: SimpleSlider!
  @IBOutlet weak var inkSpeedSlider: SimpleSlider!
  @IBOutlet weak var initialPressureCutoffSlider: SimpleSlider!
  @IBOutlet weak var ratioSlider: SimpleSlider!
  
  override var preferredContentSize: CGSize {
    get {
      return CGSize(width: 280, height: 450)
    }
    set {
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
    view.tintColor.getRed(&red, green: &green, blue: &blue, alpha: nil)

    pressureSlider.color = SIMD4<Float>(Float(red), Float(green), Float(blue),1)
    inkSpeedSlider.color = SIMD4<Float>(Float(red), Float(green), Float(blue),1)
    initialPressureCutoffSlider.color = SIMD4<Float>(Float(red), Float(green), Float(blue),1)
    ratioSlider.setColor(SIMD4<Float>(Float(red), Float(green), Float(blue),1), and: SIMD4<Float>(Float(red), Float(green), Float(blue),1))

    //SIMD4<Float>(Float(red), Float(green), Float(blue),1)

    pressureSlider.value = pressure
    inkSpeedSlider.value = inkSpeed
    initialPressureCutoffSlider.value = initialPressureCutoff
    ratioSlider.value = (ratio + 5)/10 // -5 ... 5
  }
  
  @IBAction func goBack(_ sender: Any) {
    navigationController?.popViewController(animated: true)
  }
  
  @IBAction func pressureSliderAciton(_ sender: Any) {
    delegate?.setPressure(pressureSlider.value)
  }
  
  @IBAction func inkSpeedSliderAciton(_ sender: Any) {
    delegate?.setInkSpeed(inkSpeedSlider.value)
  }
  
  @IBAction func initialPressureCutoff(_ sender: Any) {
    delegate?.setInitialPressureCutoff(initialPressureCutoffSlider.value)
  }
  
  @IBAction func ratioAction(_ sender: Any) {
    if (0.5 - 0.05) < ratioSlider.value && ratioSlider.value < (0.5 + 0.05) {
      ratioSlider.value = 0.5
    }
    delegate?.setRatio( (ratioSlider.value - 0.5) * 10)
  }
}

extension PaletteDetailViewController: UITextFieldDelegate {
  func textFieldDidEndEditing(_ textField: UITextField) {
    
  }
}
