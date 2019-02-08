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
import AVFoundation

enum Mode: Int {
  
  case photo = 1
  case video
}
class ViewController: UIViewController {
  
  private struct Constants {
     static let frameUploadDelayMs: TimeInterval = 1000

  }
  
  @IBOutlet weak var errorLabel: UILabel!
  @IBOutlet weak var errorView: UIView!
  @IBOutlet weak var sessionInterruptedLabel: UILabel!
  @IBOutlet weak var circularProgressView: CircularProgressView!
  @IBOutlet weak var videoButton: UIButton!
  @IBOutlet weak var photoButton: UIButton!
  @IBOutlet weak var modeControlSuperView: UIView!
  
  @IBOutlet weak var flashButton: UIButton!
  @IBOutlet weak var modeCOntrolSuperViewLeadingSpace: NSLayoutConstraint!
  @IBOutlet weak var recordButton: UIButton!
  @IBOutlet weak var previewView: CameraPreviewView!
  
  private lazy var cameraCaptureService: CameraCaptureService = CameraCaptureService(cameraPreviewView: previewView)
  
  private var previousFrameUploadTimeMs: TimeInterval = Date.distantPast.timeIntervalSince1970 * 1000
  
  private lazy var uploadEngine = UploadEngine()
  private var flashButtonImageNames = ["icn_flash_off","icn_flash_on","icn_flash_auto"]
  
  private let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("data")
  let dispatchQueue = DispatchQueue(label: "collectionQueue")
  
  
  
  @IBOutlet weak var uploadLabel: UILabel!
  private var mode = Mode.photo
  private var uploadCount = 0
  
  private var timer: Timer?
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    errorView.alpha = 0.0
    cameraCaptureService.delegate = self
    self.recordButton.setImage(UIImage(named: "icn_btn"), for: .normal)
    
    
  }
  
  @IBAction func onClickPhotoButton(_ sender: Any) {
    
    self.photoButton.isEnabled = false
    
    self.videoButton.isEnabled = true
    
    guard cameraCaptureService.mode == .video else {
      return
    }
    animateModeChange()
  }
  
  
  @IBAction func onClickFlashButton(_ sender: Any) {
    
    flashButton.isEnabled = false
    cameraCaptureService.toggleFlash { (complete) in
      DispatchQueue.main.async {
        self.flashButton.isEnabled = true
      }
    }
    flashButton.setImage(UIImage(named:flashButtonImageNames[cameraCaptureService.torchMode.rawValue]), for: .normal)
  }
 
  @IBAction func onClickVideoButton(_ sender: Any) {
    
    self.videoButton.isEnabled = false
    
    self.photoButton.isEnabled = true
    guard cameraCaptureService.mode == .photo else {
      return
    }
    animateModeChange()
  }
  
  func animateModeChange() {
    
    self.recordButton.isSelected = false
    switch cameraCaptureService.mode {
    case .photo:
      self.modeCOntrolSuperViewLeadingSpace.constant = -80.0
      self.recordButton.setImage(UIImage(named: "icn_record"), for: .normal)
      
    case .video:
      self.modeCOntrolSuperViewLeadingSpace.constant = 0.0
      self.recordButton.setImage(UIImage(named: "icn_btn"), for: .normal)
      
    }
    
    self.flashButton.setImage(UIImage(named:flashButtonImageNames[0]), for: .normal)
    
    cameraCaptureService.changeMode()
  }
  
  
  @objc func handleSwipe(swipeGEsture: UISwipeGestureRecognizer) {
    
  }
  
  
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    cameraCaptureService.attemptToStartRunningSession()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    cameraCaptureService.stopRunningSession()
  }
  
  
  func showAlert(withTitle title: String, message: String) {
    
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    present(alertController, animated: true, completion: nil)
    
    let action = UIAlertAction(title: "OK", style: .default) { (action) in
      
    }
    
    alertController.addAction(action)
    
  }
  
  func showCameraPermissionsDeniedAlert(withTitle title: String, message: String) {
    
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    present(alertController, animated: true, completion: nil)
    
    let action = UIAlertAction(title: "OK", style: .default) { (action) in
      
    }
    
    alertController.addAction(action)
    
    let settingsAction = UIAlertAction(title: "SETTINGS", style: .default) { (action) in
      
      if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url)  {
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }
    
    alertController.addAction(settingsAction)
  }
  
  
  @IBAction func onClickRecordButton(_ sender: Any) {
    
    switch cameraCaptureService.mode {
    case .photo:
      self.recordButton.isSelected = false
      cameraCaptureService.capturePhoto()
    case .video:
      
      toggleRecord()
      
      break
    }
    
  }
  
  func toggleRecord() {
    
    self.recordButton.isSelected = !self.recordButton.isSelected
    
    if self.recordButton.isSelected {
      
      self.recordButton.setImage(UIImage(named: "icn_stop_record"), for: .normal)
      timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { (timer) in
        self.onClickRecordButton(self.recordButton)
      }
      circularProgressView.drawCircularLayer(withProgress: 1.0)
      
    }
    else {
      
      self.recordButton.setImage(UIImage(named: "icn_record"), for: .normal)
      self.previousFrameUploadTimeMs = Date.distantPast.timeIntervalSince1970 * 1000
      circularProgressView.removeAnimation()
      timer?.invalidate()
      timer = nil
      
    }
    
  }
  
  
  
  @IBAction func onClickFlipButton(_ sender: Any) {
    
    self.recordButton.isEnabled = false
    cameraCaptureService.flipCamera { (complete) in
      self.recordButton.isEnabled = true
    }
  }
}

extension ViewController: CameraCaptureManagerDelegate {
  
  
  func didOutput(pixelBuffer: CVPixelBuffer) {
    
    DispatchQueue.main.async {
      if self.recordButton.isSelected == true {
        
        let currentTimeMs = Date().timeIntervalSince1970 * 1000
        
        guard  (currentTimeMs - self.previousFrameUploadTimeMs) >= Constants.frameUploadDelayMs else {
          return
        }
        
        self.uploadEngine.addToUploadQueue(pixelBuffer: pixelBuffer) { (error) in
          
          DispatchQueue.main.async {
            
            self.didUploadFile(error: error)
          }
        }
        
        self.previousFrameUploadTimeMs = currentTimeMs
      }
    }
  }
  
  
  func cameraPermissionsDenied() {
  showCameraPermissionsDeniedAlert(withTitle: "Camera Permissions Denied", message: "You have previously denied permissions for camera. You can change this in settings.")
    
  }
  
  func videoConfigurationFailed() {
    showAlert(withTitle: "Video Configuration Error", message: "There is an error in configuring the video device.")

  }
  
  func didEncounterSessionRuntimeError() {
    sessionInterruptedLabel.isHidden = false

  }
  
  
  func sessionInterrupted(canResumeManually resumeManually: Bool) {
    sessionInterruptedLabel.isHidden = false

  }
  
  func sessionInterruptionHasEnded(){
    sessionInterruptedLabel.isHidden = true

  }
  
  func didCapturePhoto(data: Data) {
    
    uploadEngine.addToUploadQueue(data: data) { (error) in
      DispatchQueue.main.async {
        
        self.didUploadFile(error: error)
      }
    }
  }
  
  func didUploadFile(error: Error?) {
    
    guard let uploadError = error else {
      
      self.uploadCount = self.uploadCount + 1
      
      var extensionString = "files"
      
      if self.uploadCount == 1 {
        extensionString = "file"
      }
      self.uploadLabel.text = "Uploaded \(self.uploadCount) \(extensionString)."
      print("Uploaded")
      
      return
    }
    
    showErrorView(withMessage: "File could not be uploaded. \(uploadError.localizedDescription)")
  }
  
  func showErrorView(withMessage message: String) {
    
    self.errorLabel.text = message
    self.errorView.alpha = 0.0
    UIView.animate(withDuration: 0.4) {
      self.errorView.alpha = 1.0
    }
 
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1600)) {
      self.hideErrorView()
    }
    
  }
  
  func hideErrorView() {
    
    self.errorView.alpha = 1.0
    UIView.animate(withDuration: 0.4) {
      self.errorView.alpha = 0.0
    }
  }
}


