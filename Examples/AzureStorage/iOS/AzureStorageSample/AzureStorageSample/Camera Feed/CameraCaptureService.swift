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


protocol CameraCaptureManagerDelegate: class {
 
  func didOutput(pixelBuffer: CVPixelBuffer)

  func cameraPermissionsDenied()
 
  func videoConfigurationFailed()

  func didEncounterSessionRuntimeError()
  
  func sessionInterrupted(canResumeManually resumeManually: Bool)
  
  func sessionInterruptionHasEnded()
  
  func didCapturePhoto(data: Data)
  
}

enum CameraConfiguration {
  
  case success
  case failed
  case permissionDenied
}

class CameraCaptureService: NSObject {
  
  private let captureSession: AVCaptureSession = AVCaptureSession()
  private let captureQueue = DispatchQueue(label: "CaptureQueue")
  private let cameraPreviewView: CameraPreviewView
  lazy var videoOutput = AVCaptureVideoDataOutput()
  private let photoOutput = AVCapturePhotoOutput()
  private var videoDeviceInput: AVCaptureDeviceInput!
  private var isSessionCurrentlyRunning = false
  var photo: AVCapturePhoto?
  var mode: Mode = .photo
  var torchMode = AVCaptureDevice.TorchMode.off
  var flashMode = AVCaptureDevice.FlashMode.off
  
  private var cameraConfiguration: CameraConfiguration = .failed

  weak var delegate: CameraCaptureManagerDelegate?
  
  init(cameraPreviewView: CameraPreviewView) {
    self.cameraPreviewView = cameraPreviewView
    super.init()
    
    captureSession.sessionPreset = .medium
    cameraPreviewView.session = captureSession
    cameraPreviewView.videoPreviewLayer.connection?.videoOrientation = .portrait
    cameraPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill
    checkCameraPermissionsAndConfigureSession()
  }
  
  func attemptToStartRunningSession() {
    captureQueue.async {
      switch self.cameraConfiguration {
      case .success:
        self.addSessionPropertyObservers()
        self.startRunningSession()
      case .failed:
        DispatchQueue.main.async {
          self.delegate?.videoConfigurationFailed()
        }
      case .permissionDenied:
        DispatchQueue.main.async {
          self.delegate?.cameraPermissionsDenied()
        }
      }
    }
  }
  
  func setTorch(withMode torchMode: AVCaptureDevice.TorchMode, completion: @escaping (Bool) -> ()) {
    
    self.torchMode = torchMode
    self.flashMode = AVCaptureDevice.FlashMode(torchMode: self.torchMode)
    
    
    var currentTorchMode = self.torchMode
    
    if self.mode == .photo {
      
      currentTorchMode = .off
    }
    
    captureQueue.async {
      do {
        try self.videoDeviceInput.device.lockForConfiguration()
        self.videoDeviceInput.device.torchMode = currentTorchMode
      }
      catch {
        print(error)
        completion(false)
      }
      self.videoDeviceInput.device.unlockForConfiguration()
      completion(true)
      
    }
  }
  
  func toggleFlash(withCompletion completion:@escaping (Bool) -> ()) {
    
    guard let newTorchMode = AVCaptureDevice.TorchMode(rawValue: (torchMode.rawValue + 1) % 3) else {
      
      return
    }
    
    setTorch(withMode: newTorchMode) { (complete) in
      completion(complete)
    }
    
  }
  
  
  func changeMode() {
    
    if self.mode == .video {
      self.mode = .photo
    }
    else {
      self.mode = .video
    }
    
    setTorch(withMode: .off) { (complete) in
      
    }
    switch mode {
    case .photo:
      captureQueue.async {
        self.captureSession.removeOutput(self.videoOutput)
        if self.captureSession.canAddOutput(self.photoOutput) {
          self.captureSession.addOutput(self.photoOutput)
        }
      }
      
    case .video:
      captureQueue.async {
        
        self.captureSession.removeOutput(self.photoOutput)
        if self.captureSession.canAddOutput(self.videoOutput) {
          self.captureSession.addOutput(self.videoOutput)
          self.videoOutput.connection(with: .video)?.videoOrientation = .portrait
        }
      }
      
    
    }
  }
  
  func capturePhoto() {
    
    let videoPreviewLayerOrientation = cameraPreviewView.videoPreviewLayer.connection?.videoOrientation
    
    captureQueue.async {
      if let photoOutputConnection = self.photoOutput.connection(with: .video) {
        photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
      }
      let photoSettings = AVCapturePhotoSettings()
  
      if self.videoDeviceInput.device.isFlashAvailable {
        photoSettings.flashMode = self.flashMode
      }
      
      if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
        photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
      }
     
      self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
  }
  
  func flipCamera(completion: @escaping (Bool) -> ()) {
    
    captureQueue.async {
      let currentVideoDevice = self.videoDeviceInput.device
      let currentPosition = currentVideoDevice.position
      
      let preferredPosition: AVCaptureDevice.Position
      
      switch currentPosition {
      case .unspecified, .front:
        preferredPosition = .back
        
      case .back:
        preferredPosition = .front
      }
      
      guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: preferredPosition) else {
        
        DispatchQueue.main.async {
          completion(true)
          
        }
        return
      }
      
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
          
          self.captureSession.beginConfiguration()
          
          self.captureSession.removeInput(self.videoDeviceInput)
          
          if self.captureSession.canAddInput(videoDeviceInput) {
        
            self.captureSession.addInput(videoDeviceInput)
            
            do {
              try videoDeviceInput.device.lockForConfiguration()
            }
            catch {
              
            }
            videoDeviceInput.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
            videoDeviceInput.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
            videoDeviceInput.device.unlockForConfiguration()
          
            self.videoDeviceInput = videoDeviceInput
          } else {
            self.captureSession.addInput(self.videoDeviceInput)
        
          }
          self.videoOutput.connection(with: .video)?.videoOrientation = .portrait
          
          self.captureSession.commitConfiguration()
          DispatchQueue.main.async {
            completion(true)

          }
        } catch {
          print("Error occurred while creating video device input: \(error)")
        }
  
    }
  }
  
  func stopRunningSession() {
    self.removeSessionPropertyObservers()
    captureQueue.async {
      if self.captureSession.isRunning {
        self.captureSession.stopRunning()
        self.isSessionCurrentlyRunning = self.captureSession.isRunning
      }
    }
    
  }
  
 
  func resumeSession(withCompletion completion: @escaping (Bool) -> ()) {
    
    captureQueue.async {
      self.startRunningSession()
      
      DispatchQueue.main.async {
        completion(self.isSessionCurrentlyRunning)
      }
    }
  }
  
  private func startRunningSession() {
    captureSession.startRunning()
    isSessionCurrentlyRunning = captureSession.isRunning
  }
  
  
  private func checkCameraPermissionsAndConfigureSession() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      self.cameraConfiguration = .success
    case .notDetermined:
      self.captureQueue.suspend()
      self.requestCameraAccess(completion: { (granted) in
        self.captureQueue.resume()
      })
    case .denied:
      self.cameraConfiguration = .permissionDenied
    default:
      break
    }
    
    self.captureQueue.async {
      self.configureCaptureSession()
    }
  }
  
 
  private func requestCameraAccess(completion: @escaping (Bool) -> ()) {
    AVCaptureDevice.requestAccess(for: .video) { (granted) in
      if !granted {
        self.cameraConfiguration = .permissionDenied
      }
      else {
        self.cameraConfiguration = .success
      }
      completion(granted)
    }
  }
  
 
  private func configureCaptureSession() {
    
    guard cameraConfiguration == .success else {
      return
    }
    captureSession.beginConfiguration()
    
    guard configureVideoDeviceInput() == true else {
      self.captureSession.commitConfiguration()
      self.cameraConfiguration = .failed
      return
    }
    
    guard configureVideoDataOutput() else {
      self.captureSession.commitConfiguration()
      self.cameraConfiguration = .failed
      return
    }
    
    captureSession.commitConfiguration()
    self.cameraConfiguration = .success
  }
 
  private func configureVideoDeviceInput() -> Bool {
    
    guard let camera  = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
      fatalError("Cannot find camera")
    }
    
    do {
      let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
      if captureSession.canAddInput(videoDeviceInput) {
        captureSession.addInput(videoDeviceInput)
        self.videoDeviceInput = videoDeviceInput
        return true
      }
      else {
        return false
      }
    }
    catch {
      fatalError("Cannot create video device input")
    }
  }
  

  private func configureVideoDataOutput() -> Bool {
    
    videoOutput.alwaysDiscardsLateVideoFrames = true
    
    let sampleBufferQueue = DispatchQueue(label: "cameraOutputQueue")
    videoOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)

    guard captureSession.canAddOutput(photoOutput) else {
      return false
    }
    
    captureSession.addOutput(photoOutput)
    return true
  }
  
  private func addSessionPropertyObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(CameraCaptureService.sessionInterrupted(notification:)), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: captureSession)
    NotificationCenter.default.addObserver(self, selector: #selector(CameraCaptureService.sessionInterruptionHasEnded(notification:)), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: captureSession)
    NotificationCenter.default.addObserver(self, selector: #selector(CameraCaptureService.didEncounterSessionRuntimeError(notification:)), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: captureSession)

  }
  
  private func removeSessionPropertyObservers() {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionRuntimeError, object: captureSession)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: captureSession)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: captureSession)
  }
  
  @objc func sessionInterrupted(notification: Notification) {
    
    if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
      let reasonIntegerValue = userInfoValue.integerValue,
      let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
      print("Capture session was interrupted with reason \(reason)")
      
      var canResumeManually = false
      if reason == .videoDeviceInUseByAnotherClient {
        canResumeManually = true
      } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
        canResumeManually = false
      }
      
      self.delegate?.sessionInterrupted(canResumeManually: canResumeManually)
      
    }
  }
  
  @objc func sessionInterruptionHasEnded(notification: Notification) {
    
    self.delegate?.sessionInterruptionHasEnded()
  }
  
  @objc func didEncounterSessionRuntimeError(notification: Notification) {
    guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else {
      return
    }
    
    print("Capture session runtime error: \(error)")
    
    if error.code == .mediaServicesWereReset {
      captureQueue.async {
        if self.isSessionCurrentlyRunning {
          self.startRunningSession()
        } else {
          DispatchQueue.main.async {
            self.delegate?.didEncounterSessionRuntimeError()
          }
        }
      }
    } else {
      self.delegate?.didEncounterSessionRuntimeError()
      
    }
  }
}


extension CameraCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
  
 
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
    
    
    guard let imagePixelBuffer = pixelBuffer else {
      return
    }
    
    delegate?.didOutput(pixelBuffer: imagePixelBuffer)
  }
  
}

extension CameraCaptureService: AVCapturePhotoCaptureDelegate {
  
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    
    self.photo = photo
  
  }
  
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?){
    
    print("capture done")
    
    guard let data = photo?.fileDataRepresentation() else {
      return
    }
    delegate?.didCapturePhoto(data: data)
  }
}

extension AVCaptureDevice.FlashMode {
  
  init(torchMode: AVCaptureDevice.TorchMode) {
    
    switch torchMode {
    case .off:
      self = AVCaptureDevice.FlashMode.off
    case .on:
      self = AVCaptureDevice.FlashMode.on
    case .auto:
      self = AVCaptureDevice.FlashMode.auto
    default:
      self = AVCaptureDevice.FlashMode.off
    }
  }
  
}
