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

protocol UploadEngineDelegate {
  
  func uploadComplete()
}

class UploadEngine: NSObject {
  
  let dispatchQueue = DispatchQueue(label: "ConvertQueue")
   
  var uploadQueue: OperationQueue = {
    
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.name = "UploadQueue"
    return queue
  }()
  
  override init() {
    super.init()
    createDirectory()
  }
  
  func createDirectory() {
    
    var isDir : ObjCBool = true
    
    if !FileManager.default.fileExists(atPath: AzureEngine.shared.url.path, isDirectory: &isDir) == true {
      do {
        
        try FileManager.default.createDirectory(at: AzureEngine.shared.url, withIntermediateDirectories: false, attributes: nil)
      }
      catch {
        
        print(error)
      }
    }
  }
  
  func addToUploadQueue(data: Data, completion: @escaping (Error?)->()) {
    
    
    
    let imageUrl = AzureEngine.shared.url.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
    
    do{
      try data.write(to: imageUrl)
    }
    catch {
      print(error)
    }
    
    
   let uploadOperation = UploadOperation(withData: imageUrl)
    uploadOperation.completionBlock = {

      if uploadOperation.error == nil {
        
        self.dispatchQueue.async {
          
          do {
            try FileManager.default.removeItem(at: imageUrl)
          }
          catch {
            print(error)
          }
        }
       
      }
      completion(uploadOperation.error)
     
    }
      

    self.uploadQueue.addOperation(uploadOperation)

  }

  
  func addToUploadQueue(pixelBuffer: CVPixelBuffer, completion: @escaping (Error?)->()) {
    
    
    dispatchQueue.async {
      
    let ciiImage = CIImage(cvPixelBuffer: pixelBuffer)
    let ciContext = CIContext(options: nil)
    
    
    guard let cgImage = ciContext.createCGImage(ciiImage, from: ciiImage.extent), let data =  UIImage(cgImage: cgImage).jpegData(compressionQuality: 1.0) else {
      return
    }
    
    self.addToUploadQueue(data: data) { (error) in
      completion(error)
    }
    }
    
  }
  
}
