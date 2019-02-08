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


class AzureEngine: NSObject {
  
  
  private struct Constants {
    
    static let accountKey: String? = "BtdY76B0z+Br9y8mQ1jPK48T1WDwffrU3GNsH3ctRb1TTEvZb2h+IlRx9lst54+OwVG/i+MnT1NSp2E/z8+vwA=="
    static let accountName: String? = "ilabsazure"
    static let blobContainerName = "ios"
  }
  
  static let shared = AzureEngine()

  let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("data")

  
  var container: AZSCloudBlobContainer!
  
  private let connectionString: String? = {
    
    guard let name = Constants.accountName, let key = Constants.accountKey else {
      return nil
    }
    return "DefaultEndpointsProtocol=https;AccountName=\(name);AccountKey=\(key)=="
  }()
  

 private override init() {
    super.init()
    
     performAzureAuth()
  }
  
  private func performAzureAuth() {
    
    guard let tempConnectionString = connectionString else {
      return
    }
    let storageAccount : AZSCloudStorageAccount;
    try! storageAccount = AZSCloudStorageAccount(fromConnectionString: tempConnectionString)
    let blobClient = storageAccount.getBlobClient()
    self.container = blobClient.containerReference(fromName:Constants.blobContainerName)
    
    self.container.createContainerIfNotExists { (error : Error?, created) -> Void in
      
    }
    
  }
  
  func upload(data: Data, withCompletion completion:@escaping (Error?)->()) {
    
    let reference = container.blockBlobReference(fromName: "\(UUID().uuidString).jpg")
    
    reference.upload(from: data) { (error) in
      
      completion(error)
      
    }
    
  }
  
  func upload(fromFile url: URL, withCompletion completion:@escaping (Error?)->()) {
    
    let reference = container.blockBlobReference(fromName: "\(UUID().uuidString).jpg")
    
    reference.uploadFromFile(with: url) { (error) in
      completion(error)

    }
    
  }
}
