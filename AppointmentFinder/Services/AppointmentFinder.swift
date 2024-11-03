//
//  AppointmentFinder.swift
//  KVR_Swift
//
//  Created by Ege Güler on 03.11.24.
//



import Foundation
import SwiftSoup


extension String {
    func extractAppointmentsJSON() throws -> String {
        let pattern = #"var\s+jsonAppoints\s*=\s*'(.*?)'"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsString = self as NSString
        let results = regex.matches(in: self, options: [], range: NSRange(location: 0, length: nsString.length))
        
        guard let match = results.first, match.numberOfRanges > 1 else {
            throw NSError(domain: "ExtractionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error extracting JSON from script"])
        }
        
        let jsonString = nsString.substring(with: match.range(at: 1))
        return jsonString
    }
}



struct AppointmentFinder {
    
    static func findAppointment() async throws {
        do {
            let homePageUrlString = "https://terminvereinbarung.muenchen.de/abh/termin/?cts=1000113"
            guard let homePageUrl = URL(string: homePageUrlString) else {
                print("Invalid url")
                return
            }
            
            let (data, response) = try await RequestManager.shared.get(url: homePageUrl)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else  {
                print("Failed to fetch home page")
                return
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                print("Failed to decode home page html")
                return
            }
            
            let document: Document = try SwiftSoup.parse(html)
            
            let captchaElement : Element? = try document.select("div.frc-captcha").first()
            let captchaKey = try captchaElement?.attr("data-sitekey")
            
            let formTokenElement: Element? = try document.select("input[name='FRM_CASETYPES_token']").first()
            let formToken = try formTokenElement?.attr("value")
            
            guard let formTokenUnwrapped = formToken else {
                print("Error: Form Token couldnt be found")
                return
            }
            
            guard let captchaKeyUnwrapped = captchaKey else {
                print("Error: Captcha Key could not be found")
                return
            }
            
            let captchaSolver = CaptchaSolver()
            let solvedCaptchaToken = try await captchaSolver.solveCaptcha(captchaKey: captchaKeyUnwrapped)
            
            let (dataAppointmentsPage, responseAppointmentsPage) = try await getAppointmentsPage(formToken: formTokenUnwrapped, captchaToken: solvedCaptchaToken)
            
            guard let httpResponse = responseAppointmentsPage as? HTTPURLResponse, httpResponse.statusCode == 200 else  {
                print("Failed to fetch Appointments  page")
                return
            }
            
            let appointmensHtml = String(data: dataAppointmentsPage, encoding: .utf8) ?? ""
            let jsonData = try appointmensHtml.extractAppointmentsJSON()
            
            let found = checkAppointments(jsonData)
            if found {
                print("Appointments found")
            } else {
                print("No Appointments found")
            }
            
        }
    }
    
    static private func getAppointmentsPage(formToken: String, captchaToken: String) async throws ->  (data: Data, resonse: URLResponse){
        let postURLString = "https://terminvereinbarung.muenchen.de/abh/termin/index.php?cts=1000113"
        
        guard let postUrl = URL(string: postURLString) else {
            throw NSError(domain: "Invalid Post Url", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid POST URL"])
        }
        
        let formData = createFormData(formToken: formToken, captchaToken: captchaToken)
        guard let formDataGuard = formData.query?.data(using: .utf8) else {
            throw NSError(domain: "Cant create form data", code: 0, userInfo: [NSLocalizedDescriptionKey: "Form Data couldnt be created"])
        }
        
        let headers = [
            "Host": "terminvereinbarung.muenchen.de",
            "Referer": "https://terminvereinbarung.muenchen.de/abh/termin/?cts=1000113",
            "Origin": "https://terminvereinbarung.muenchen.de",
        ]
        
        let (data, response) = try await RequestManager.shared.post(url: postUrl, data: formDataGuard, type: .form, headers: headers)
        
        return (data, response)
    }
    
    static private func createFormData(formToken: String, captchaToken: String) -> URLComponents{
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "FRM_CASETYPES_token", value: formToken),
            URLQueryItem(name: "step", value: "WEB_APPOINT_SEARCH_BY_CASETYPES"),
            URLQueryItem(name: "CASETYPES[Notfalltermin UA 35]", value: "1"),
            URLQueryItem(name: "frc-captcha-solution", value: captchaToken)
        ]
        return components
    }
    
    static private func checkAppointments(_ jsonData: String) -> Bool {
        guard let data = jsonData.data(using: .utf8) else {
            print("Invalid appointments json string")
            return false
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            print("JSON Object: \(jsonObject)")
            
            guard let appointData = jsonObject as? [String: Any] else {
                print("JSON is not a dictionary")
                return false
            }
            
            guard let loadBalancer = appointData["LOADBALANCER"] as? [String: Any] else {
                print("'LOADBALANCER' key not found or not a dictionary")
                return false
            }
            
            guard let appoints = loadBalancer["appoints"] as? [String: Any] else {
                print("'appoints' key not found or not a dictionary")
                return false
            }
            
            print("Appoints: \(appoints)")
            
            for (date, slots) in appoints {
                print("Processing Date: \(date), Slots: \(slots)")
                if let slotsArray = slots as? [Any], !slotsArray.isEmpty {
                    print("Date with available slots: \(date)")
                    return true
                }
            }
            
        }
        catch {
            print("Error unmarshaling JSON: \(error)")
        }
        
        return false
    }

}
