//
//  UploadPuzzleView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/23/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct UploadPuzzleView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var userSettings = UserSettings()

    @State var showFilePicker: Bool = false
    @State var showError: Bool = false
    @State var token: String = ""

    var body: some View {
        VStack {
            if (self.showError) {
                Text("Something went wrong. Try again and check the formatting of your file")
            }
            Button(action: {
                self.showFilePicker.toggle()
            }) {
                Text("Upload .puz file")
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { fileUrl in
            do {
                guard let selectedFile: URL = try fileUrl.get().first else { return }

                let requestUrl = URL(string: "https://omni-crosswords-server-rtluzv2sqq-uc.a.run.app/parsePuzfile")!
                //let requestUrl = URL(string: "http://192.168.86.111:8080/parsePuzfile")!
                var request = URLRequest(url: requestUrl)
                request.setValue("Bearer "+self.token, forHTTPHeaderField: "Authorization")
                request.httpMethod = "POST"

                let task = URLSession.shared.uploadTask(with: request, fromFile: selectedFile) { data, response, error in
                    do {
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode != 201 {
                                showError = true
                                print(httpResponse)
                                return
                            }
                        }
                        let crosswordResponse = try JSONDecoder().decode(CrosswordResponse.self, from: data!)
                        DispatchQueue.main.async {
                            do {
                                let crossword = Crossword(context: managedObjectContext)
                                jsonToCrossword(crossword: crossword, data: crosswordResponse)
                                try self.managedObjectContext.save()
                            } catch {
                                showError = true
                                print(error.localizedDescription)
                            }
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        return
                    } catch {
                        showError = true
                        print("Error info: \(error)")
                    }
                    return
                }

                task.resume()
            } catch {
                // Handle failure.
                print("Error info: \(error)")
            }
        }
        .onAppear(perform: {
            guard self.userSettings.user != nil else {
                return
            }
            userSettings.user?.getIDToken(completion: {(result, err) in
                if err != nil || result == nil {
                    return
                }
                self.token = result!
            })
        })
    }
}
