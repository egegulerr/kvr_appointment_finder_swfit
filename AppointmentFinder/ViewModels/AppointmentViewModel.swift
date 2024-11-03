//
//  AppointmentViewModel.swift
//  KVR_Swift
//
//  Created by Ege Güler on 03.11.24.
//

import Foundation
import SwiftUI


class AppointmentViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var appointmentsFound: Bool? = nil
    
    
    func findAppointments() {
        isLoading = true
        do {
            try await AppointmentFinder.findAppointment()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
