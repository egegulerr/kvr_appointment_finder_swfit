//
//  RequestManager.swift
//  KVR_Swift
//
//  Created by Ege Güler on 01.11.24.
//

import Foundation

enum PostMethodType {
    case json, form
}

class RequestManager: @unchecked Sendable {
    
    static let shared = RequestManager()
    
    let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpShouldSetCookies = true
        configuration.httpAdditionalHeaders =  [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:131.0) Gecko/20100101 Firefox/131."
        ]
        self.session = URLSession(configuration: configuration)
    }
    
    func get(url: URL, headers: [String: String]? = nil) async throws -> (Data, URLResponse) {
        var request =  URLRequest(url: url)
        request.httpMethod = "GET"
        headers?.forEach {
            key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if #available(macOS 12.0, *) {
            return try await session.data(for: request)
        } else {
            throw NSError(domain: "Unsupported macOS version", code: -1, userInfo: [NSLocalizedDescriptionKey: "This functionality requires macOS 12.0 or newer."])
        }
    }
    
    func post(url: URL, data:Data, type: PostMethodType,headers: [String: String]? = nil) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data

        request.setValue(type == .json ?  "application/json" : "application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        headers?.forEach{
            key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if #available(macOS 12.0, *) {
            return try await session.data(for: request)
        } else {
            throw NSError(domain: "Unsupported macOS version", code: -1, userInfo: [NSLocalizedDescriptionKey: "This functionality requires macOS 12.0 or newer."])
        }
    }
    
    
}
