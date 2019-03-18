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

class UploadOperation: Operation {
 
  
  private let stateQueue = DispatchQueue(label: "asynchronous.operation.state", attributes: .concurrent)
  
  private var _executing: Bool = false
  override var isExecuting: Bool {
    get {
      return _executing
    }
    set {
      if _executing != newValue {
        willChangeValue(forKey: "isExecuting")
        _executing = newValue
        didChangeValue(forKey: "isExecuting")
      }
    }
  }
  
  private var _finished: Bool = false;
  override var isFinished: Bool {
    get {
      return _finished
    }
    set {
      if _finished != newValue {
        willChangeValue(forKey: "isFinished")
        _finished = newValue
        didChangeValue(forKey: "isFinished")
      }
    }
  }
  var failed = false
  var error: Error?
  private var fileUrl: URL
  
  
  init(withData url: URL) {
    
    self.fileUrl = url
    super.init()
    
   
  }
  public final override var isReady: Bool {
    
    return true
  }
  
  override func start() {
    
    self.isExecuting = true
    
    AzureEngine.shared.upload(fromFile: fileUrl) { (error) in
      self.error = error
      self.failed = self.error != nil
      
      self.stateQueue.sync {
        self.isExecuting = false
        self.isFinished = true
      }
    }
    
  }
  
}
