//
//The MIT License (MIT)
//Copyright © 2019 YML. All Rights Reserved.
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files
//(the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge,
//publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
//subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit
import CoreImage

class CircularProgressView: UIView {

 
  var circularProgress: Double = 0.0
  private var circularLayer: CAShapeLayer = CAShapeLayer()
  
  required init?(coder aDecoder: NSCoder) {
    
    super.init(coder: aDecoder)
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    drawPath()

  }
  
  func drawPath() {
    
    let topAngle = -CGFloat.pi / 2
    let circularPath = UIBezierPath(arcCenter: CGPoint(x: self.bounds.midX, y: self.bounds.midY), radius: (85.0 - 10.0) / 2.0, startAngle: topAngle, endAngle: topAngle + 2 * CGFloat.pi, clockwise: true)
    
    circularLayer.path = circularPath.cgPath
    circularLayer.strokeColor = UIColor(displayP3Red: 237.0/255.0, green: 68.0/255.0, blue: 66.0/255.0, alpha: 1.0).cgColor
    
    circularLayer.lineWidth = 10.0
    circularLayer.lineCap = CAShapeLayerLineCap.round
    circularLayer.strokeEnd = 0
    self.layer.addSublayer(circularLayer)
    
  }
  
  func drawCircularLayer(withProgress progress: Double) {
    
    circularProgress = progress
    
    let animation = CABasicAnimation(keyPath: "strokeEnd")
    animation.fromValue = 0
    animation.toValue = progress
    animation.duration = 20
    
    circularLayer.add(animation, forKey: "progress")
    
  }
  
  func removeAnimation() {
    circularLayer.removeAllAnimations()
  }

}
