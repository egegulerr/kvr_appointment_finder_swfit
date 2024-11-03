//
//  CaptchaSolver.swift
//  KVR_Swift
//
//  Created by Ege Güler on 01.11.24.
//

import Foundation

enum CaptchaSolvedResult {
    case success(token: String)
    case error(description: String)
    case processing
}

class CaptchaSolver {
    // TODO DO NOT STORE CLIENT KEY HERE
    let clientKey = "b6b0da116555559c3cfe7d39657ce2f0"
    let createTaskURL = URL(string: "https://api.2captcha.com/createTask")!
    let getTaskResultURL = URL(string: "https://api.2captcha.com/getTaskResult")!
    let websiteURL = "https://terminvereinbarung.muenchen.de/abh/termin/?cts=1000113"

    
    func solveCaptcha(captchaKey: String) async throws -> String {
        let payload: [String: Any] = [
            "clientKey": self.clientKey,
            "task": [
                "type": "FriendlyCaptchaTaskProxyless",
                    "websiteURL": websiteURL,
                    "websiteKey": captchaKey
            ]
        ]
        
        let jsonPayloadData = try JSONSerialization.data(withJSONObject: payload)
        let (createdTaskResponse, _ ) = try await RequestManager.shared.post(url: createTaskURL, data: jsonPayloadData, type: .json)
        let createdTaskJson = try JSONDecoder().decode(CreatedTaskResponse.self, from: createdTaskResponse)
        print("Created task for captcha solving. Response: \(String(data: createdTaskResponse, encoding: .utf8) ?? "" )")
        
        
        while true {
            try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            // TODO Find Better Naming
            let resultPayload: [String: Any] = [
                "clientKey": clientKey,
                "taskId": createdTaskJson.taskId
            ]
            
            let resultPayloadData = try JSONSerialization.data(withJSONObject: resultPayload)
            let (resultDataResponse, _ ) = try await RequestManager.shared.post(url: getTaskResultURL, data: resultPayloadData, type: .json)
            
            let solvedResult = try parseTaskResultResponse(data: resultDataResponse)
            
            switch solvedResult {
            case .success(let token):
                print("Captcha Solved successfully. Token: \(token)")
                return token
            case .error(let description):
                fatalError("Error solving Captcha: \(description)")
            case .processing:
                print("Captcha solving in progess.....")
            }
            
        }
    }
    
    func parseTaskResultResponse(data: Data) throws -> CaptchaSolvedResult {
        let decoder = JSONDecoder()
        let temp = try decoder.decode([String: AnyDecodable].self, from: data)
        
        if let errorId = temp["errorId"]?.value as? Int, errorId != 0 {
            if let errorDescription = temp["errorDescription"]?.value as? String {
                return .error(description: errorDescription)
            }
            return .error(description: "Unknown error while solving captcha")
        }
        
        if let status = temp["status"]?.value as? String{
            switch status {
            case "ready":
                let successResponse = try decoder.decode(SolvedTaskResponseSuccess.self, from: data)
                return .success(token: successResponse.solution.token)
            case "processing":
                return .processing
            default:
                return .error(description: "Unknown status: \(status)")
            }
        }
        
        throw NSError(domain: "CaptchaTaskResultParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown solved task response format"])
    }
}
