//
//  CaptchaModels.swift
//  KVR_Swift
//
//  Created by Ege Güler on 01.11.24.
//

import Foundation

struct CreatedTaskResponse: Codable {
    let errorId: Int
    let taskId: Int
}

struct SolvedTaskResponseSuccess: Codable {
    let errorId: Int
    let status: String
    let solution: Solution
    let cost: String
    let ip: String
    let createTime: Double
    let endTime: Double
    let solveCount: Double
    
    struct Solution: Codable {
        let token: String
    }
}


struct SolvedTaskResponseError: Codable {
    let errorId: Int
    let errorCode: String
    let errorDescription: String
}

struct SolvedTaskResponseProcessing: Codable {
    let errorId: Int
    let status: String
}
