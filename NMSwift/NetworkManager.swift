//
//  NetworkManager.swift
//  MZNetworkManagerSwift
//
//  Created by Venu Gopal kotha on 05/01/17.
//

import Foundation
import Reachability
@objc open class NetworkManager:NSObject{
    var baseUrlStr:String
    var connectionTimeoutStr:String
    var headerAcceptStr:String
    var headercontentTypeStr:String
    var trailCountInt:Int
    
    public override init(){
        baseUrlStr = ""
        connectionTimeoutStr = ""
        headerAcceptStr = ""
        headercontentTypeStr = ""
        trailCountInt = 1
        super.init()
        getValuesFromConfigurationPlist()
    }
    
    //method to check internet is available or not
    func isNetworkReachable() -> Bool{
        let reachability = Reachability.forInternetConnection()
        let netStatus = reachability!.currentReachabilityStatus()
        if netStatus.rawValue == 0{
            return false
        }
        else {
            return true
        }
    }
    
    //method to check the network connection type is WAN,Wifi and etc
    func isNetworkType() -> Int{
        let reachability = Reachability()
        let netStatus = reachability.currentReachabilityStatus()
        return netStatus.rawValue
    }
    
    func getValuesFromConfigurationPlist(){
        let appCategory = UserDefaults.standard.string(forKey: "appCategory")
        var fileName:String;
        //apppCategory is YES for customer projects and NO for base(ChannelConnect) project
        if appCategory == "YES" {
            fileName = Bundle.main.infoDictionary?["CFBundleName"] as! String
            fileName = fileName + "_NetworkConfigurations"
        }
        else
        {
            fileName = "NetworkConfigurations";
        }
        
        let path:String = Bundle.main.path(forResource: fileName, ofType: "plist")!
        let dictionary = NSDictionary(contentsOfFile: path)
        baseUrlStr = dictionary!["baseURL"] as! String
        connectionTimeoutStr = dictionary!["connectionTimeoutStr"] as! String
        //trailCountInt = dictionary!["trailCountInt"] as! Int
        headercontentTypeStr = dictionary!["headercontentTypeStr"] as! String
    }
    func attachTheCookie()->Dictionary<String,String>{
        let savedCookieData:Dictionary<String,String>? = UserDefaults.standard.object(forKey: "ccCookie") as? Dictionary<String, String>
        var cookie: HTTPCookie?
        if savedCookieData != nil{
            cookie = HTTPCookie(properties: [HTTPCookiePropertyKey(rawValue: HTTPCookiePropertyKey.domain.rawValue):(savedCookieData?["domain"])!,HTTPCookiePropertyKey(rawValue: HTTPCookiePropertyKey.path.rawValue):(savedCookieData?["path"])!,HTTPCookiePropertyKey(rawValue: HTTPCookiePropertyKey.name.rawValue):(savedCookieData?["name"])!,HTTPCookiePropertyKey(rawValue:HTTPCookiePropertyKey.value.rawValue):(savedCookieData?["value"])!])
        }
        else {
            cookie = HTTPCookie(properties: [HTTPCookiePropertyKey(rawValue: HTTPCookiePropertyKey.domain.rawValue):"a",HTTPCookiePropertyKey(rawValue: HTTPCookiePropertyKey.path.rawValue):"a",HTTPCookiePropertyKey(rawValue: HTTPCookiePropertyKey.name.rawValue):"a",HTTPCookiePropertyKey(rawValue:HTTPCookiePropertyKey.value.rawValue):"a"])
            
        }
        let headers:Dictionary<String,String> = HTTPCookie.requestHeaderFields(with: [cookie!])
        return headers
    }
    
   open func createURLRequest(_ networkRequestParam:NetworkRequest) -> URLRequest{
        if networkRequestParam.baseURLStr.characters.count > 0{
            self.baseUrlStr = networkRequestParam.baseURLStr
        }
        let saveURL:String = self.baseUrlStr + "/" + networkRequestParam.serviceURLStr
        let encodedURL = saveURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)
        print("encodedURL is \(encodedURL)")
        let urlString:URL? = URL(string: encodedURL!)
        var urlRequestObj:URLRequest = URLRequest(url:urlString!)
        print(urlRequestObj)
        urlRequestObj.allHTTPHeaderFields = attachTheCookie()
        urlRequestObj.addValue(networkRequestParam.acceptStr, forHTTPHeaderField: "Accept")
        urlRequestObj.addValue(networkRequestParam.contentTypeStr, forHTTPHeaderField: "Content-Type")
        if networkRequestParam.requestTypeStr == "GET"{
            urlRequestObj.httpMethod = "GET"
        }
        else if networkRequestParam.requestTypeStr == "DELETE"{
            urlRequestObj.httpMethod = "DELETE"
        }
        else if networkRequestParam.requestTypeStr == "POST"{
            urlRequestObj.httpMethod = "POST"
            if networkRequestParam.isFileDataRequestBool == true{
                urlRequestObj.httpBody = networkRequestParam.fileRequestDataObj
            }else{
                urlRequestObj.httpBody = networkRequestParam.fileRequestDataObj!
                print(urlRequestObj.httpBody)
                //                urlRequest.httpBody = networkRequestParam.requestData?.data(using: String.Encoding.utf8, allowLossyConversion: true)
            }
        }
        print(urlRequestObj)
        return urlRequestObj
    }
    
   open func serviceResponse(_ urlRequestParam:URLRequest, isWait: Bool) -> NetworkResponse{
        
        let networkResponse:NetworkResponse = NetworkResponse()
        let defaultConfiguration = URLSessionConfiguration.default
        //set the cookie policy
        defaultConfiguration.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.never
        
        let session = URLSession(configuration: defaultConfiguration)
        
        //set the cookie
        
        //        let task = session.dataTask(with: urlRequestParam, completionHandler:(dataParam,urlResponseParam,errorParam) in
        let semaphoreObj = DispatchSemaphore.init(value: 0);
        print(urlRequestParam)
        if self.isNetworkReachable() {
            let task = session.dataTask(with: urlRequestParam, completionHandler:{(data, urlResponse, error) -> Void in
                let errorCode = error as? NSError
                if errorCode != nil{
                    if (errorCode!.domain == "NSURLErrorDomain" && errorCode!.code == NSURLErrorTimedOut){
                        
                    }
                    else if errorCode!.code == NSURLErrorUserCancelledAuthentication{
                        networkResponse.isNetworkCallSuccessBool = false;
                        networkResponse.errorMessageStr = "Session Expired! Please Logout and Login Again";//For Trimble Release we modified @"The connection failed because the user cancelled required authentication.";
                        networkResponse.responseDataObj = nil;
                    }
                }
                else{
                    //                do{
                    let httpResponse = urlResponse as? HTTPURLResponse
                    if (httpResponse!.statusCode >= 200 &&
                        httpResponse!.statusCode < 300) || (httpResponse!.statusCode >= 400 && httpResponse!.statusCode <= 500) && httpResponse!.statusCode != 403 {
                        networkResponse.isNetworkCallSuccessBool = true;
                        networkResponse.errorMessageStr = nil;
                        networkResponse.responseDataObj = data;
                    }else if httpResponse!.statusCode == 403{
                        networkResponse.isNetworkCallSuccessBool = false;
                        networkResponse.errorMessageStr = "Session Expired! Please Logout and Login Again";
                        networkResponse.responseDataObj = nil;
                    }
                    else if httpResponse!.statusCode == 502{
                        networkResponse.isNetworkCallSuccessBool = false;
                        networkResponse.errorMessageStr = "Bad Gateway";
                        networkResponse.responseDataObj = nil;
                    }
                    else if httpResponse!.statusCode == 503{
                        networkResponse.isNetworkCallSuccessBool = false;
                        networkResponse.errorMessageStr = "Bad Gateway";
                        networkResponse.responseDataObj = nil;
                    }
                    else if httpResponse!.statusCode == 504{
                        networkResponse.isNetworkCallSuccessBool = false;
                        networkResponse.errorMessageStr    = "Gateway Timeout";
                        networkResponse.responseDataObj = nil;
                    }
                    else if httpResponse!.statusCode == 505{
                        networkResponse.isNetworkCallSuccessBool = false;
                        networkResponse.errorMessageStr = "Http version not supported";
                        networkResponse.responseDataObj = nil;
                    }
                    else{
                        networkResponse.isNetworkCallSuccessBool = false;
                        networkResponse.errorMessageStr = "No Proper Response From Server";
                        networkResponse.responseDataObj = nil;
                    }
                    //                }catch(){
                    //
                    //                }
                }
                semaphoreObj.signal()
            })
            task.resume()
            semaphoreObj.wait(timeout: .distantFuture)
        }
        else{
            networkResponse.isNetworkCallSuccessBool = false;
            networkResponse.errorMessageStr = "Device Not Connected to Internet";
            networkResponse.responseDataObj = nil;
            
        }
        return networkResponse
    }
    
    
    public func processRequest(networkRequest:NetworkRequest, withWait:Bool) -> NetworkResponse{
        let urlRequest = self.createURLRequest(networkRequest)
        return self.serviceResponse(urlRequest, isWait: withWait)
    }
    
}
