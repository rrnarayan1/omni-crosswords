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
    @State var showLoader: Bool = false
    @State var token: String = ""

    var body: some View {
        VStack {
            if (!self.showError && self.showLoader) {
                ProgressView("Uploading...")
            } else {
                if (self.showError) {
                    Text("Something went wrong. Try again and check the formatting of your file")
                        .foregroundColor(.red)
                        .padding(.bottom, 20)
                }
                
                Button(action: {
                    self.showFilePicker.toggle()
                }) {
                    Text("Upload .puz file")
                }
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { fileUrl in
            do {
                showLoader = true
                guard let selectedFile: URL = try fileUrl.get().first else { return }

                let requestUrl = URL(string: "https://omni-crosswords-server-rtluzv2sqq-uc.a.run.app/parsePuzfile")!
                //let requestUrl = URL(string: "http://192.168.86.111:8080/parsePuzfile")!
                var request = URLRequest(url: requestUrl)
                request.setValue("Bearer "+self.token, forHTTPHeaderField: "Authorization")
                request.httpMethod = "POST"
                
                guard selectedFile.startAccessingSecurityScopedResource() else {
                    showLoader = false
                    showError = true
                    return
                }

                let appCacheUrl =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let copiedSelectedFile = appCacheUrl.appendingPathComponent(selectedFile.lastPathComponent)

                if let dataFromURL = NSData(contentsOf: selectedFile) {
                    if dataFromURL.write(to: copiedSelectedFile, atomically: true) {
                        print("file saved [\(copiedSelectedFile.path)]")
                    } else {
                        showLoader = false
                        showError = true
                        print("error saving file before uploading")
                    }
                }

                selectedFile.stopAccessingSecurityScopedResource()

                let task = URLSession.shared.uploadTask(with: request, fromFile: copiedSelectedFile) { data, response, error in
                    do {
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode != 201 {
                                showLoader = false
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
                                showLoader = false
                                showError = true
                                print(error.localizedDescription)
                            }
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        return
                    } catch {
                        showLoader = false
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
