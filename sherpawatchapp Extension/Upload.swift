//
//  Upload.swift
//  SwiftHTTP
//
//  Created by Dalton Cherry on 6/5/14.
//  Copyright (c) 2014 Vluxe. All rights reserved.
//

import Foundation
import Security

public class SSLCert {
    var certData: NSData?
    var key: SecKeyRef?
    
    /**
    Designated init for certificates
    
    - parameter data: is the binary data of the certificate
    
    - returns: a representation security object to be used with
    */
    public init(data: NSData) {
        self.certData = data
    }
    
    /**
    Designated init for public keys
    
    - parameter key: is the public key to be used
    
    - returns: a representation security object to be used with
    */
    public init(key: SecKeyRef) {
        self.key = key
    }
}

public class HTTPSecurity {
    public var validatedDN = true //should the domain name be validated?
    
    var isReady = false //is the key processing done?
    var certificates: [NSData]? //the certificates
    var pubKeys: [SecKeyRef]? //the public keys
    var usePublicKeys = false //use public keys or certificate validation?
    
    /**
    Use certs from main app bundle
    
    - parameter usePublicKeys: is to specific if the publicKeys or certificates should be used for SSL pinning validation
    
    - returns: a representation security object to be used with
    */
    public convenience init(usePublicKeys: Bool = false) {
        let paths = NSBundle.mainBundle().pathsForResourcesOfType("cer", inDirectory: ".")
        var collect = Array<SSLCert>()
        for path in paths {
            if let d = NSData(contentsOfFile: path as String) {
                collect.append(SSLCert(data: d))
            }
        }
        self.init(certs:collect, usePublicKeys: usePublicKeys)
    }
    
    /**
    Designated init
    
    - parameter keys: is the certificates or public keys to use
    - parameter usePublicKeys: is to specific if the publicKeys or certificates should be used for SSL pinning validation
    
    - returns: a representation security object to be used with
    */
    public init(certs: [SSLCert], usePublicKeys: Bool) {
        self.usePublicKeys = usePublicKeys
        
        if self.usePublicKeys {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), {
                var collect = Array<SecKeyRef>()
                for cert in certs {
                    if let data = cert.certData where cert.key == nil  {
                        cert.key = self.extractPublicKey(data)
                    }
                    if let k = cert.key {
                        collect.append(k)
                    }
                }
                self.pubKeys = collect
                self.isReady = true
            })
        } else {
            var collect = Array<NSData>()
            for cert in certs {
                if let d = cert.certData {
                    collect.append(d)
                }
            }
            self.certificates = collect
            self.isReady = true
        }
    }
    
    /**
    Valid the trust and domain name.
    
    - parameter trust: is the serverTrust to validate
    - parameter domain: is the CN domain to validate
    
    - returns: if the key was successfully validated
    */
    public func isValid(trust: SecTrustRef, domain: String?) -> Bool {
        
        var tries = 0
        while(!self.isReady) {
            usleep(1000)
            tries += 1
            if tries > 5 {
                return false //doesn't appear it is going to ever be ready...
            }
        }
        var policy: SecPolicyRef
        if self.validatedDN {
            policy = SecPolicyCreateSSL(true, domain)
        } else {
            policy = SecPolicyCreateBasicX509()
        }
        SecTrustSetPolicies(trust,policy)
        if self.usePublicKeys {
            if let keys = self.pubKeys {
                var trustedCount = 0
                let serverPubKeys = publicKeyChainForTrust(trust)
                for serverKey in serverPubKeys as [AnyObject] {
                    for key in keys as [AnyObject] {
                        if serverKey.isEqual(key) {
                            trustedCount++
                            break
                        }
                    }
                }
                if trustedCount == serverPubKeys.count {
                    return true
                }
            }
        } else if let certs = self.certificates {
            let serverCerts = certificateChainForTrust(trust)
            var collect = Array<SecCertificate>()
            for cert in certs {
                collect.append(SecCertificateCreateWithData(nil,cert)!)
            }
            SecTrustSetAnchorCertificates(trust,collect)
            var result: SecTrustResultType = 0
            SecTrustEvaluate(trust,&result)
            let r = Int(result)
            if r == kSecTrustResultUnspecified || r == kSecTrustResultProceed {
                var trustedCount = 0
                for serverCert in serverCerts {
                    for cert in certs {
                        if cert == serverCert {
                            trustedCount++
                            break
                        }
                    }
                }
                if trustedCount == serverCerts.count {
                    return true
                }
            }
        }
        return false
    }
    
    /**
    Get the public key from a certificate data
    
    - parameter data: is the certificate to pull the public key from
    
    - returns: a public key
    */
    func extractPublicKey(data: NSData) -> SecKeyRef? {
        let possibleCert = SecCertificateCreateWithData(nil,data)
        if let cert = possibleCert {
            return extractPublicKeyFromCert(cert, policy: SecPolicyCreateBasicX509())
        }
        return nil
    }
    
    /**
    Get the public key from a certificate
    
    - parameter data: is the certificate to pull the public key from
    
    - returns: a public key
    */
    func extractPublicKeyFromCert(cert: SecCertificate, policy: SecPolicy) -> SecKeyRef? {
        var possibleTrust: SecTrust?
        SecTrustCreateWithCertificates(cert, policy, &possibleTrust)
        if let trust = possibleTrust {
            var result: SecTrustResultType = 0
            SecTrustEvaluate(trust, &result)
            return SecTrustCopyPublicKey(trust)
        }
        return nil
    }
    
    /**
    Get the certificate chain for the trust
    
    - parameter trust: is the trust to lookup the certificate chain for
    
    - returns: the certificate chain for the trust
    */
    func certificateChainForTrust(trust: SecTrustRef) -> Array<NSData> {
        var collect = Array<NSData>()
        for var i = 0; i < SecTrustGetCertificateCount(trust); i++ {
            let cert = SecTrustGetCertificateAtIndex(trust,i)
            collect.append(SecCertificateCopyData(cert!))
        }
        return collect
    }
    
    /**
    Get the public key chain for the trust
    
    - parameter trust: is the trust to lookup the certificate chain and extract the public keys
    
    - returns: the public keys from the certifcate chain for the trust
    */
    func publicKeyChainForTrust(trust: SecTrustRef) -> Array<SecKeyRef> {
        var collect = Array<SecKeyRef>()
        let policy = SecPolicyCreateBasicX509()
        for var i = 0; i < SecTrustGetCertificateCount(trust); i++ {
            let cert = SecTrustGetCertificateAtIndex(trust,i)
            if let key = extractPublicKeyFromCert(cert!, policy: policy) {
                collect.append(key)
            }
        }
        return collect
    }
    
    
}

extension String {
    /**
    A simple extension to the String object to encode it for web request.
    
    :returns: Encoded version of of string it was called as.
    */
    var escaped: String? {
        let set = NSMutableCharacterSet()
        set.formUnionWithCharacterSet(NSCharacterSet.URLQueryAllowedCharacterSet())
        set.removeCharactersInString("[].:/?&=;+!@#$()',*\"") // remove the HTTP ones from the set.
        return self.stringByAddingPercentEncodingWithAllowedCharacters(set)
    }
}

/**
The standard HTTP Verbs
*/
public enum HTTPVerb: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case HEAD = "HEAD"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
    case OPTIONS = "OPTIONS"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
    case UNKNOWN = "UNKNOWN"
}

/**
This is used to create key/value pairs of the parameters
*/
public struct HTTPPair {
    var key: String?
    let storeVal: AnyObject
    /**
    Create the object with a possible key and a value
    */
    init(key: String?, value: AnyObject) {
        self.key = key
        self.storeVal = value
    }
    /**
    Computed property of the string representation of the storedVal
    */
    var upload: String? {
        return storeVal as? String
    }
    /**
    Computed property of the string representation of the storedVal
    */
    var value: String {
        if let v = storeVal as? String {
            return v
        } else if let v = storeVal.description {
            return v
        }
        return ""
    }
    /**
    Computed property of the string representation of the storedVal escaped for URLs
    */
    var escapedValue: String {
        if let v = value.escaped {
            if let k = key {
                if let escapedKey = k.escaped {
                    return "\(escapedKey)=\(v)"
                }
            }
            return v
        }
        return ""
    }
}

/**
Enum used to describe what kind of Parameter is being interacted with.
This allows us to only support an Array or Dictionary and avoid having to use AnyObject
*/
public enum HTTPParamType {
    case Array
    case Dictionary
    case Upload
}

/**
This protocol is used to make the dictionary and array serializable into key/value pairs.
*/
public protocol HTTPParameterProtocol {
    func paramType() -> HTTPParamType
    func createPairs(key: String?) -> Array<HTTPPair>
}

/**
Support for the Dictionary type as an HTTPParameter.
*/
extension Dictionary: HTTPParameterProtocol {
    public func paramType() -> HTTPParamType {
        return .Dictionary
    }
    public func createPairs(key: String?) -> Array<HTTPPair> {
        var collect = Array<HTTPPair>()
        for (k, v) in self {
            if let nestedKey = k as? String, let nestedVal = v as? AnyObject {
                let useKey = key != nil ? "\(key!)[\(nestedKey)]" : nestedKey
                if let subParam = nestedVal as? Dictionary { //as? HTTPParameterProtocol <- bug? should work.
                    collect.appendContentsOf(subParam.createPairs(useKey))
                } else if let subParam = nestedVal as? Array<AnyObject> {
                    collect.appendContentsOf(subParam.createPairs(useKey))
                } else {
                    collect.append(HTTPPair(key: useKey, value: nestedVal))
                }
            }
        }
        return collect
    }
}

/**
Support for the Array type as an HTTPParameter.
*/
extension Array: HTTPParameterProtocol {
    public func paramType() -> HTTPParamType {
        return .Array
    }
    
    public func createPairs(key: String?) -> Array<HTTPPair> {
        var collect = Array<HTTPPair>()
        for v in self {
            if let nestedVal = v as? AnyObject {
                let useKey = key != nil ? "\(key!)[]" : key
                if let subParam = nestedVal as? Dictionary<String, AnyObject> {
                    collect.appendContentsOf(subParam.createPairs(useKey))
                } else if let subParam = nestedVal as? Array<AnyObject> {
                    collect.appendContentsOf(subParam.createPairs(useKey))
                } else {
                    collect.append(HTTPPair(key: useKey, value: nestedVal))
                }
            }
        }
        return collect
    }
}

/**
Adds convenience methods to NSMutableURLRequest to make using it with HTTP much simpler.
*/
extension NSMutableURLRequest {
    /**
    Convenience init to allow init with a string.
    -parameter urlString: The string representation of a URL to init with.
    */
    public convenience init?(urlString: String) {
        if let url = NSURL(string: urlString) {
            self.init(URL: url)
        } else {
            return nil
        }
    }
    
    /**
    Convenience method to avoid having to use strings and allow using an enum
    */
    public var verb: HTTPVerb {
        set {
            HTTPMethod = newValue.rawValue
        }
        get {
            if let v = HTTPVerb(rawValue: HTTPMethod) {
                return v
            }
            return .UNKNOWN
        }
    }
    
    /**
    Used to update the content type in the HTTP header as needed
    */
    var contentTypeKey: String {
        return "Content-Type"
    }
    
    /**
    append the parameters using the standard HTTP Query model.
    This is parameters in the query string of the url (e.g. ?first=one&second=two for GET, HEAD, DELETE.
    It uses 'application/x-www-form-urlencoded' for the content type of POST/PUT requests that don't contains files.
    If it contains a file it uses `multipart/form-data` for the content type.
    -parameter parameters: The container (array or dictionary) to convert and append to the URL or Body
    */
    public func appendParameters(parameters: HTTPParameterProtocol) throws {
        if isURIParam() {
            appendParametersAsQueryString(parameters)
        } else if containsFile(parameters) {
            try appendParametersAsMultiPartFormData(parameters)
        } else {
            appendParametersAsUrlEncoding(parameters)
        }
    }
    
    /**
    append the parameters as a HTTP Query string. (e.g. domain.com?first=one&second=two)
    -parameter parameters: The container (array or dictionary) to convert and append to the URL
    */
    public func appendParametersAsQueryString(parameters: HTTPParameterProtocol) {
        let queryString = parameters.createPairs(nil).map({ (pair) in
            return pair.escapedValue
        }).joinWithSeparator("&")
        if let u = self.URL where queryString.characters.count > 0 {
            let para = u.query != nil ? "&" : "?"
            self.URL = NSURL(string: "\(u.absoluteString)\(para)\(queryString)")
        }
    }
    
    /**
    append the parameters as a url encoded string. (e.g. in the body of the request as: first=one&second=two)
    -parameter parameters: The container (array or dictionary) to convert and append to the HTTP body
    */
    public func appendParametersAsUrlEncoding(parameters: HTTPParameterProtocol) {
        if valueForHTTPHeaderField(contentTypeKey) == nil {
            let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))
            setValue("application/x-www-form-urlencoded; charset=\(charset)",
                forHTTPHeaderField:contentTypeKey)
            
        }
        let queryString = parameters.createPairs(nil).map({ (pair) in
            return pair.escapedValue
        }).joinWithSeparator("&")
        HTTPBody = queryString.dataUsingEncoding(NSUTF8StringEncoding)
    }
    
    /**
    append the parameters as a multpart form body. This is the type normally used for file uploads.
    -parameter parameters: The container (array or dictionary) to convert and append to the HTTP body
    */
    public func appendParametersAsMultiPartFormData(parameters: HTTPParameterProtocol) throws {
        let boundary = "Boundary+\(arc4random())\(arc4random())"
        if valueForHTTPHeaderField(contentTypeKey) == nil {
            setValue("multipart/form-data; boundary=\(boundary)",
                forHTTPHeaderField:contentTypeKey)
        }
        let mutData = NSMutableData()
        let multiCRLF = "\r\n"
        mutData.appendData("--\(boundary)".dataUsingEncoding(NSUTF8StringEncoding)!)
        for pair in parameters.createPairs(nil) {
            guard let key = pair.key else { continue } //this won't happen, but just to properly unwrap
            mutData.appendData("\(multiCRLF)".dataUsingEncoding(NSUTF8StringEncoding)!)
            if let _ = pair.upload {
            } else {
                let str = "\(multiFormHeader(key, fileName: nil, type: nil, multiCRLF: multiCRLF))\(pair.value)"
                mutData.appendData(str.dataUsingEncoding(NSUTF8StringEncoding)!)
            }
            mutData.appendData("\(multiCRLF)--\(boundary)".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        mutData.appendData("--\(multiCRLF)".dataUsingEncoding(NSUTF8StringEncoding)!)
        HTTPBody = mutData
    }
    
    /**
    Helper method to create the multipart form data
    */
    func multiFormHeader(name: String, fileName: String?, type: String?, multiCRLF: String) -> String {
        var str = "Content-Disposition: form-data; name=\"\(name.escaped!)\""
        if let name = fileName {
            str += "; filename=\"\(name)\""
        }
        str += multiCRLF
        if let t = type {
            str += "Content-Type: \(t)\(multiCRLF)"
        }
        str += multiCRLF
        return str
    }
    
    
    /**
    send the parameters as a body of JSON
    -parameter parameters: The container (array or dictionary) to convert and append to the URL or Body
    */
    public func appendParametersAsJSON(parameters: HTTPParameterProtocol) throws {
        if isURIParam() {
            appendParametersAsQueryString(parameters)
        } else {
            do {
                HTTPBody = try NSJSONSerialization.dataWithJSONObject(parameters as! AnyObject, options: NSJSONWritingOptions())
            } catch let error {
                throw error
            }
            let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))
            setValue("application/json; charset=\(charset)", forHTTPHeaderField: contentTypeKey)
        }
    }
    
    /**
    Check if the request requires the parameters to be appended to the URL
    */
    public func isURIParam() -> Bool {
        if verb == .GET || verb == .HEAD || verb == .DELETE {
            return true
        }
        return false
    }
    
    /**
    check if the parameters contain a file object within them
    -parameter parameters: The parameters to search through for an upload object
    */
    public func containsFile(parameters: Any) -> Bool {
        guard let params = parameters as? HTTPParameterProtocol else { return false }
        for pair in params.createPairs(nil) {
            if let _ = pair.upload {
                return true
            }
        }
        return false
    }
}

enum HTTPOptError: ErrorType {
    case InvalidRequest
}

/**
This protocol exist to allow easy and customizable swapping of a serializing format within an class methods of HTTP.
*/
public protocol HTTPSerializeProtocol {
    
    /**
    implement this protocol to support serializing parameters to the proper HTTP body or URL
    -parameter request: The NSMutableURLRequest object you will modify to add the parameters to
    -parameter parameters: The container (array or dictionary) to convert and append to the URL or Body
    */
    func serialize(request: NSMutableURLRequest, parameters: HTTPParameterProtocol) throws
}

/**
Standard HTTP encoding
*/
public struct HTTPParameterSerializer: HTTPSerializeProtocol {
    public init() { }
    public func serialize(request: NSMutableURLRequest, parameters: HTTPParameterProtocol) throws {
        try request.appendParameters(parameters)
    }
}

/**
Send the data as a JSON body
*/
public struct JSONParameterSerializer: HTTPSerializeProtocol {
    public init() { }
    public func serialize(request: NSMutableURLRequest, parameters: HTTPParameterProtocol) throws {
        try request.appendParametersAsJSON(parameters)
    }
}

/**
All the things of an HTTP response
*/
public class Response {
    /// The header values in HTTP response.
    public var headers: Dictionary<String,String>?
    /// The mime type of the HTTP response.
    public var mimeType: String?
    /// The suggested filename for a downloaded file.
    public var suggestedFilename: String?
    /// The body data of the HTTP response.
    public var data: NSData {
        return collectData
    }
    /// The status code of the HTTP response.
    public var statusCode: Int?
    /// The URL of the HTTP response.
    public var URL: NSURL?
    /// The Error of the HTTP response (if there was one).
    public var error: NSError?
    ///Returns the response as a string
    public var text: String? {
        return  NSString(data: data, encoding: NSUTF8StringEncoding) as? String
    }
    ///get the description of the response
    public var description: String {
        var buffer = ""
        if let u = URL {
            buffer += "URL:\n\(u)\n\n"
        }
        if let code = self.statusCode {
            buffer += "Status Code:\n\(code)\n\n"
        }
        if let heads = headers {
            buffer += "Headers:\n"
            for (key, value) in heads {
                buffer += "\(key): \(value)\n"
            }
            buffer += "\n"
        }
        if let t = text {
            buffer += "Payload:\n\(t)\n"
        }
        return buffer
    }
    ///private things
    
    ///holds the collected data
    var collectData = NSMutableData()
    ///finish closure
    var completionHandler:((Response) -> Void)?
    
    //progress closure. Progress is between 0 and 1.
    var progressHandler:((Float) -> Void)?
    
    ///This gets called on auth challenges. If nil, default handling is use.
    ///Returning nil from this method will cause the request to be rejected and cancelled
    var auth:((NSURLAuthenticationChallenge) -> NSURLCredential?)?
    
    ///This is for doing SSL pinning
    var security: HTTPSecurity?
}

/**
The class that does the magic. Is a subclass of NSOperation so you can use it with operation queues or just a good ole HTTP request.
*/
public class HTTP: NSOperation {
    /**
    Get notified with a request finishes.
    */
    public var onFinish:((Response) -> Void)? {
        didSet {
            if let handler = onFinish {
                DelegateManager.sharedInstance.addTask(task, completionHandler: { (response: Response) in
                    self.finish()
                    handler(response)
                })
            }
        }
    }
    ///This is for handling authenication
    public var auth:((NSURLAuthenticationChallenge) -> NSURLCredential?)? {
        set {
            guard let resp = DelegateManager.sharedInstance.responseForTask(task) else { return }
            resp.auth = newValue
        }
        get {
            guard let resp = DelegateManager.sharedInstance.responseForTask(task) else { return nil }
            return resp.auth
        }
    }
    
    ///This is for doing SSL pinning
    public var security: HTTPSecurity? {
        set {
            guard let resp = DelegateManager.sharedInstance.responseForTask(task) else { return }
            resp.security = newValue
        }
        get {
            guard let resp = DelegateManager.sharedInstance.responseForTask(task) else { return nil }
            return resp.security
        }
    }
    
    ///This is for monitoring progress
    public var progress: ((Float) -> Void)? {
        set {
            guard let resp = DelegateManager.sharedInstance.responseForTask(task) else { return }
            resp.progressHandler = newValue
        }
        get {
            guard let resp = DelegateManager.sharedInstance.responseForTask(task) else { return nil }
            return resp.progressHandler
        }
    }
    
    ///the actual task
    var task: NSURLSessionDataTask!
    /// Reports if the task is currently running
    private var running = false
    /// Reports if the task is finished or not.
    private var done = false
    
    /**
    creates a new HTTP request.
    */
    public init(_ req: NSURLRequest, session: NSURLSession = SharedSession.defaultSession) {
        super.init()
        task = session.dataTaskWithRequest(req)
        DelegateManager.sharedInstance.addResponseForTask(task)
    }
    
    //MARK: Subclassed NSOperation Methods
    
    /// Returns if the task is asynchronous or not. NSURLSessionTask requests are asynchronous.
    override public var asynchronous: Bool {
        return true
    }
    
    /// Returns if the task is current running.
    override public var executing: Bool {
        return running
    }
    
    /// Returns if the task is finished.
    override public var finished: Bool {
        return done
    }
    
    /**
    start/sends the HTTP task with a completionHandler. Use this when *NOT* using an NSOperationQueue.
    */
    public func start(completionHandler:((Response) -> Void)) {
        onFinish = completionHandler
        start()
    }
    
    /**
    Start the HTTP task. Make sure to set the onFinish closure before calling this to get a response.
    */
    override public func start() {
        if cancelled {
            self.willChangeValueForKey("isFinished")
            done = true
            self.didChangeValueForKey("isFinished")
            return
        }
        
        self.willChangeValueForKey("isExecuting")
        self.willChangeValueForKey("isFinished")
        
        running = true
        done = false
        
        self.didChangeValueForKey("isExecuting")
        self.didChangeValueForKey("isFinished")
        
        task.resume()
    }
    
    /**
    Cancel the running task
    */
    override public func cancel() {
        task.cancel()
        finish()
    }
    /**
    Sets the task to finished.
    If you aren't using the DelegateManager, you will have to call this in your delegate's URLSession:dataTask:didCompleteWithError: method
    */
    public func finish() {
        self.willChangeValueForKey("isExecuting")
        self.willChangeValueForKey("isFinished")
        
        running = false
        done = true
        
        self.didChangeValueForKey("isExecuting")
        self.didChangeValueForKey("isFinished")
    }
    
    /**
    Class method to create a GET request that handles the NSMutableURLRequest and parameter encoding for you.
    */
    public class func GET(url: String, parameters: HTTPParameterProtocol? = nil, headers: [String:String]? = nil,
        requestSerializer: HTTPSerializeProtocol = HTTPParameterSerializer()) throws -> HTTP  {
            return try HTTP.New(url, method: .GET, parameters: parameters, headers: headers, requestSerializer: requestSerializer)
    }
    
    /**
    Class method to create a HEAD request that handles the NSMutableURLRequest and parameter encoding for you.
    */
    public class func HEAD(url: String, parameters: HTTPParameterProtocol? = nil, headers: [String:String]? = nil, requestSerializer: HTTPSerializeProtocol = HTTPParameterSerializer()) throws -> HTTP  {
        return try HTTP.New(url, method: .HEAD, parameters: parameters, headers: headers, requestSerializer: requestSerializer)
    }
    
    /**
    Class method to create a DELETE request that handles the NSMutableURLRequest and parameter encoding for you.
    */
    public class func DELETE(url: String, parameters: HTTPParameterProtocol? = nil, headers: [String:String]? = nil, requestSerializer: HTTPSerializeProtocol = HTTPParameterSerializer()) throws -> HTTP  {
        return try HTTP.New(url, method: .DELETE, parameters: parameters, headers: headers, requestSerializer: requestSerializer)
    }
    
    /**
    Class method to create a POST request that handles the NSMutableURLRequest and parameter encoding for you.
    */
    public class func POST(url: String, parameters: HTTPParameterProtocol? = nil, headers: [String:String]? = nil, requestSerializer: HTTPSerializeProtocol = HTTPParameterSerializer()) throws -> HTTP  {
        return try HTTP.New(url, method: .POST, parameters: parameters, headers: headers, requestSerializer: requestSerializer)
    }
    
    /**
    Class method to create a PUT request that handles the NSMutableURLRequest and parameter encoding for you.
    */
    public class func PUT(url: String, parameters: HTTPParameterProtocol? = nil, headers: [String:String]? = nil,
        requestSerializer: HTTPSerializeProtocol = HTTPParameterSerializer()) throws -> HTTP  {
            return try HTTP.New(url, method: .PUT, parameters: parameters, headers: headers, requestSerializer: requestSerializer)
    }
    
    /**
    Class method to create a PUT request that handles the NSMutableURLRequest and parameter encoding for you.
    */
    public class func PATCH(url: String, parameters: HTTPParameterProtocol? = nil, headers: [String:String]? = nil, requestSerializer: HTTPSerializeProtocol = HTTPParameterSerializer()) throws -> HTTP  {
        return try HTTP.New(url, method: .PATCH, parameters: parameters, headers: headers, requestSerializer: requestSerializer)
    }
    
    /**
    Class method to create a HTTP request that handles the NSMutableURLRequest and parameter encoding for you.
    */
    public class func New(url: String, method: HTTPVerb, parameters: HTTPParameterProtocol? = nil, headers: [String:String]? = nil, requestSerializer: HTTPSerializeProtocol = HTTPParameterSerializer()) throws -> HTTP  {
        guard let req = NSMutableURLRequest(urlString: url) else { throw HTTPOptError.InvalidRequest }
        if let handler = DelegateManager.sharedInstance.requestHandler {
            handler(req)
        }
        req.verb = method
        if let params = parameters {
            try requestSerializer.serialize(req, parameters: params)
        }
        if let heads = headers {
            for (key,value) in heads {
                req.addValue(value, forHTTPHeaderField: key)
            }
        }
        return HTTP(req)
    }
    
    /**
    Set the global auth handler
    */
    public class func globalAuth(handler: ((NSURLAuthenticationChallenge) -> NSURLCredential?)?) {
        DelegateManager.sharedInstance.auth = handler
    }
    
    /**
    Set the global security handler
    */
    public class func globalSecurity(security: HTTPSecurity?) {
        DelegateManager.sharedInstance.security = security
    }
    
    /**
    Set the global request handler
    */
    public class func globalRequest(handler: ((NSMutableURLRequest) -> Void)?) {
        DelegateManager.sharedInstance.requestHandler = handler
    }
}

/**
Absorb all the delegates methods of NSURLSession and forwards them to pretty closures.
This is basically the sin eater for NSURLSession.
*/
class DelegateManager: NSObject, NSURLSessionDataDelegate {
    //the singleton to handle delegate needs of NSURLSession
    static let sharedInstance = DelegateManager()
    
    /// this is for global authenication handling
    var auth:((NSURLAuthenticationChallenge) -> NSURLCredential?)?
    
    ///This is for global SSL pinning
    var security: HTTPSecurity?
    
    /// this is for global request handling
    var requestHandler:((NSMutableURLRequest) -> Void)?
    
    var taskMap = Dictionary<Int,Response>()
    //"install" a task by adding the task to the map and setting the completion handler
    func addTask(task: NSURLSessionTask, completionHandler:((Response) -> Void)) {
        addResponseForTask(task)
        if let resp = responseForTask(task) {
            resp.completionHandler = completionHandler
        }
    }
    
    //"remove" a task by removing the task from the map
    func removeTask(task: NSURLSessionTask) {
        taskMap.removeValueForKey(task.taskIdentifier)
    }
    
    //add the response task
    func addResponseForTask(task: NSURLSessionTask) {
        if taskMap[task.taskIdentifier] == nil {
            taskMap[task.taskIdentifier] = Response()
        }
    }
    //get the response object for the task
    func responseForTask(task: NSURLSessionTask) -> Response? {
        return taskMap[task.taskIdentifier]
    }
    
    //handle getting data
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        addResponseForTask(dataTask)
        guard let resp = responseForTask(dataTask) else { return }
        resp.collectData.appendData(data)
        if resp.progressHandler != nil { //don't want the extra cycles for no reason
            guard let taskResp = dataTask.response else { return }
            progressHandler(resp, expectedLength: taskResp.expectedContentLength, currentLength: Int64(resp.collectData.length))
        }
    }
    
    //handle task finishing
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        guard let resp = responseForTask(task) else { return }
        resp.error = error
        if let hresponse = task.response as? NSHTTPURLResponse {
            resp.headers = hresponse.allHeaderFields as? Dictionary<String,String>
            resp.mimeType = hresponse.MIMEType
            resp.suggestedFilename = hresponse.suggestedFilename
            resp.statusCode = hresponse.statusCode
            resp.URL = hresponse.URL
        }
        if let code = resp.statusCode where resp.statusCode > 299 {
            resp.error = createError(code)
        }
        if let handler = resp.completionHandler {
            handler(resp)
        }
        removeTask(task)
    }
    
    //handle authenication
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        var sec = security
        var au = auth
        if let resp = responseForTask(task) {
            if let s = resp.security {
                sec = s
            }
            if let a = resp.auth {
                au = a
            }
        }
        if let sec = sec where challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let space = challenge.protectionSpace
            if let trust = space.serverTrust {
                if sec.isValid(trust, domain: space.host) {
                    completionHandler(.UseCredential, NSURLCredential(trust: trust))
                    return
                }
            }
            completionHandler(.CancelAuthenticationChallenge, nil)
            return
            
        } else if let a = au {
            let cred = a(challenge)
            if let c = cred {
                completionHandler(.UseCredential, c)
                return
            }
            completionHandler(.RejectProtectionSpace, nil)
            return
        }
        completionHandler(.PerformDefaultHandling, nil)
    }
    //upload progress
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let resp = responseForTask(task) else { return }
        progressHandler(resp, expectedLength: totalBytesExpectedToSend, currentLength: totalBytesSent)
    }
    //download progress
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let resp = responseForTask(downloadTask) else { return }
        progressHandler(resp, expectedLength: totalBytesExpectedToWrite, currentLength: bytesWritten)
    }
    
    //handle progress
    func progressHandler(response: Response, expectedLength: Int64, currentLength: Int64) {
        guard let handler = response.progressHandler else { return }
        let slice = 1/expectedLength
        handler(Float(slice*currentLength))
    }
    
    /**
    Create an error for response you probably don't want (400-500 HTTP responses for example).
    
    -parameter code: Code for error.
    
    -returns An NSError.
    */
    private func createError(code: Int) -> NSError {
        let text = HTTPStatusCode(statusCode: code).statusDescription
        return NSError(domain: "HTTP", code: code, userInfo: [NSLocalizedDescriptionKey: text])
    }
}

/**
Handles providing singletons of NSURLSession.
*/
class SharedSession {
    static let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
        delegate: DelegateManager.sharedInstance, delegateQueue: nil)
    static let ephemeralSession = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(),
        delegate: DelegateManager.sharedInstance, delegateQueue: nil)
}

/// HTTP Status Code (RFC 2616)
public enum HTTPStatusCode: Int {
    case Continue = 100,
    SwitchingProtocols = 101
    
    case OK = 200,
    Created = 201,
    Accepted = 202,
    NonAuthoritativeInformation = 203,
    NoContent = 204,
    ResetContent = 205,
    PartialContent = 206
    
    case MultipleChoices = 300,
    MovedPermanently = 301,
    Found = 302,
    SeeOther = 303,
    NotModified = 304,
    UseProxy = 305,
    Unused = 306,
    TemporaryRedirect = 307
    
    case BadRequest = 400,
    Unauthorized = 401,
    PaymentRequired = 402,
    Forbidden = 403,
    NotFound = 404,
    MethodNotAllowed = 405,
    NotAcceptable = 406,
    ProxyAuthenticationRequired = 407,
    RequestTimeout = 408,
    Conflict = 409,
    Gone = 410,
    LengthRequired = 411,
    PreconditionFailed = 412,
    RequestEntityTooLarge = 413,
    RequestUriTooLong = 414,
    UnsupportedMediaType = 415,
    RequestedRangeNotSatisfiable = 416,
    ExpectationFailed = 417
    
    case InternalServerError = 500,
    NotImplemented = 501,
    BadGateway = 502,
    ServiceUnavailable = 503,
    GatewayTimeout = 504,
    HttpVersionNotSupported = 505
    
    case InvalidUrl = -1001
    
    case UnknownStatus = 0
    
    init(statusCode: Int) {
        self = HTTPStatusCode(rawValue: statusCode) ?? .UnknownStatus
    }
    
    public var statusDescription: String {
        get {
            switch self {
            case .Continue:
                return "Continue"
            case .SwitchingProtocols:
                return "Switching protocols"
            case .OK:
                return "OK"
            case .Created:
                return "Created"
            case .Accepted:
                return "Accepted"
            case .NonAuthoritativeInformation:
                return "Non authoritative information"
            case .NoContent:
                return "No content"
            case .ResetContent:
                return "Reset content"
            case .PartialContent:
                return "Partial Content"
            case .MultipleChoices:
                return "Multiple choices"
            case .MovedPermanently:
                return "Moved Permanently"
            case .Found:
                return "Found"
            case .SeeOther:
                return "See other Uri"
            case .NotModified:
                return "Not modified"
            case .UseProxy:
                return "Use proxy"
            case .Unused:
                return "Unused"
            case .TemporaryRedirect:
                return "Temporary redirect"
            case .BadRequest:
                return "Bad request"
            case .Unauthorized:
                return "Access denied"
            case .PaymentRequired:
                return "Payment required"
            case .Forbidden:
                return "Forbidden"
            case .NotFound:
                return "Page not found"
            case .MethodNotAllowed:
                return "Method not allowed"
            case .NotAcceptable:
                return "Not acceptable"
            case .ProxyAuthenticationRequired:
                return "Proxy authentication required"
            case .RequestTimeout:
                return "Request timeout"
            case .Conflict:
                return "Conflict request"
            case .Gone:
                return "Page is gone"
            case .LengthRequired:
                return "Lack content length"
            case .PreconditionFailed:
                return "Precondition failed"
            case .RequestEntityTooLarge:
                return "Request entity is too large"
            case .RequestUriTooLong:
                return "Request uri is too long"
            case .UnsupportedMediaType:
                return "Unsupported media type"
            case .RequestedRangeNotSatisfiable:
                return "Request range is not satisfiable"
            case .ExpectationFailed:
                return "Expected request is failed"
            case .InternalServerError:
                return "Internal server error"
            case .NotImplemented:
                return "Server does not implement a feature for request"
            case .BadGateway:
                return "Bad gateway"
            case .ServiceUnavailable:
                return "Service unavailable"
            case .GatewayTimeout:
                return "Gateway timeout"
            case .HttpVersionNotSupported:
                return "Http version not supported"
            case .InvalidUrl:
                return "Invalid url"
            default:
                return "Unknown status code"
            }
        }
    }
}
