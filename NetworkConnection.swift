//
//  NetworkConnection.swift
//  TeenPatti
//
//  Created by Vnnovate on 15/10/18.
//  Copyright © 2018 Vnnovate. All rights reserved.
//

import Foundation

class ApiCall: NSObject {
    
    static let sharedInstance : ApiCall = {
        let instance = ApiCall()
        return instance
    }()
    
    open func requestPostMethod(apiUrl : Api, params: Data , completion: @escaping (_ success: Bool, _ object: AnyObject?) -> ()) {
        
        var request = URLRequest(url: URL(string: apiUrl.url())!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = params
        
        if apiUrl != Api.login {
            request.addValue("Bearer " + Design.token(), forHTTPHeaderField: "Authorization")
        }
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task: URLSessionDataTask = session.dataTask(with : request as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            guard let data = data, error == nil else {
                // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            do {
                
                if let convertedJsonIntoDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject] {
                    DispatchQueue.main.async {
                        completion(true, convertedJsonIntoDict as AnyObject?)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        completion(false, nil)
                    }
                }
            } catch let error as NSError {
                let str = String(data: data, encoding: String.Encoding.utf8)
                print(str ?? "-----------")
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    completion(false, nil)
                }
            }
        })
        task.resume()
    }
    
    open func requestGetMethod(apiUrl : Api, completion: @escaping (_ success: Bool, _ object: AnyObject?) -> ()) {
        
        var request = URLRequest(url: URL(string: apiUrl.url())!)
        request.httpMethod = "GET"
        request.addValue("Bearer " + Design.token(), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task: URLSessionDataTask = session.dataTask(with : request as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            guard let data = data, error == nil else {
                print("error=\(String(describing: error))")
                return
            }
            do {
                if let convertedJsonIntoDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject] {
                    DispatchQueue.main.async {
                        completion(true, convertedJsonIntoDict as AnyObject?)
                    }
                }else {
                    DispatchQueue.main.async {
                        completion(false, nil)
                    }
                }
            } catch let error as NSError {
                let str = String(data: data, encoding: String.Encoding.utf8)
                print(str ?? "-----------")
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    completion(false, nil)
                }
            }
        })
        task.resume()
    }
    
}
