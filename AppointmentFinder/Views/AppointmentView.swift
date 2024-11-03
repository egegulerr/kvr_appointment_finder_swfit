//
//  AppointmentView.swift
//  KVR_Swift
//
//  Created by Ege Güler on 03.11.24.
//

import SwiftUI

struct AppointmentView: View {
    
    @StateObject private var viewModel = AppointmentViewModel()
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: {
                Task{
                    await viewModel.findAppointment()
                }
            }) {
                Text("Find Appointments").font(.headline).padding().frame(maxWidth: .infinity).background(Color.blue).foregroundColor(.white).cornerRadius(10).padding(.horizontal, 40)
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView("Searching for appointment").padding()
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if viewModel.appointmentsFound {
                    Text("Appointments found").foregroundColor(.green).padding()
                } else if viewModel.appointmentsFound == false {
                    Text("No Appointments available.").foregroundColor(.gray).padding()
                }
                
                Spacer()
                
            }
        }.navigationTitle("Appointment Finder")
    }
}

struct AppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentView()
    }
}
