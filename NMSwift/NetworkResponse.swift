//
//  NetworkResponse.swift
//  MZNetworkManagerSwift
//
//  Created by Venu Gopal kotha on 05/01/17.
//

import Foundation
@objc open class NetworkResponse:NSObject {
    open var isNetworkCallSuccessBool:Bool
    open var errorMessageStr:String?
    open var responseDataObj:Data?
    public override init(){
        isNetworkCallSuccessBool = false
        errorMessageStr = " "
        responseDataObj = nil
    }
}
