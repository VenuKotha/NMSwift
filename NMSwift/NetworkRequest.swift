//
//  NetworkRequest.swift
//  MZNetworkManagerSwift
//
//  Created by Venu Gopal kotha on 05/01/17.
//

import Foundation
@objc open class NetworkRequest:NSObject {
    open var acceptStr:String
    open var baseURLStr:String
    open var contentTypeStr:String
    open var requestDataStr:String?
    open var requestTypeStr:String
    open var serviceURLStr: String
    open var fileRequestDataObj:Data?
    open var isFileDataRequestBool:Bool
    
    public override init(){
        acceptStr = ""
        baseURLStr = ""
        contentTypeStr = ""
        requestDataStr = ""
        requestTypeStr = ""
        serviceURLStr = ""
        fileRequestDataObj = nil
        isFileDataRequestBool = false
    }
    public init(acceptStrParam:String, contentTypeStrParam:String,requestDataStrParam:String,requestTypeStrParam:String, serviceURLStrParam:String,fileRequestDataObjParam:Data,isFileDataRequestBoolParam:Bool, baseURLStrParam:String){
        acceptStr = acceptStrParam
        baseURLStr = baseURLStrParam
        contentTypeStr = contentTypeStrParam
        requestDataStr = requestDataStrParam
        requestTypeStr = requestTypeStrParam
        serviceURLStr = serviceURLStrParam
        fileRequestDataObj = fileRequestDataObjParam
        isFileDataRequestBool = isFileDataRequestBoolParam
    }
}
