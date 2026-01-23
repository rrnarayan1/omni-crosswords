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
    @Environment(\.dismiss) var dismiss

    @ObservedObject var userSettings: UserSettings

    @State var showFilePicker: Bool = false
    @State var showError: Bool = false
    @State var showLoader: Bool = false
    @State var token: String = ""
    @State var openedFileUrl: URL? = nil
    @State var overridenOutletName: String = ""

    var body: some View {
        VStack {
            if (!self.showError && self.showLoader) {
                ProgressView("Uploading...")
            } else {
                if (self.showError) {
                    Text("Something went wrong. Try again and check the formatting of your file")
                        .foregroundColor(.red)
                        .padding()
                }

                if (self.openedFileUrl == nil) {
                    Button("Select .puz file") {
                        self.showFilePicker.toggle()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text("Your selected file: " + (self.openedFileUrl?.lastPathComponent ?? "none"))
                    HStack {
                        Text("Displayed Outlet Name:")
                        TextField("Displayed Outlet Name:", text: self.$overridenOutletName,
                                  prompt: Text("Custom"))
                            .border(.secondary)
                            .textFieldStyle(.roundedBorder)
                            .padding(.leading, 10)
                    }

                    HStack {
                        Button("Cancel") {
                            self.openedFileUrl = nil
                        }
                        .padding()
                        .buttonStyle(.bordered)

                        Button("Upload") {
                            self.showLoader = true
                            self.uploadFile(fileUrl: self.openedFileUrl!)
                        }
                        .padding()
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .frame(width: min(UIScreen.screenWidth * 0.9, 400))
        .fileImporter(
            isPresented: self.$showFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { fileUrl in
            do {
                guard let selectedFileUrl: URL = try fileUrl.get().first else { return }
                self.openedFileUrl = selectedFileUrl
            } catch {
                // Handle failure.
                print("Error info: \(error)")
            }
        }
        .onAppear(perform: {
            guard self.userSettings.user != nil else {
                return
            }
            self.userSettings.user?.getIDToken(completion: {(result, err) in
                if (err != nil || result == nil) {
                    print("Error obtaining token for network request")
                    return
                }
                self.token = result!
            })
        })
    }

    // Show error
    func uploadFileErrorHandler() -> Void {
        self.openedFileUrl = nil
        self.showLoader = false
        self.showError = true
    }

    // Dismiss page, go back to list view
    func uploadFileCompletionHandler() -> Void {
        self.dismiss()
    }

    func uploadFile(fileUrl: URL) -> Void {
        do {
            // copy the file to a cache directory so that we can read it?
            guard fileUrl.startAccessingSecurityScopedResource() else {
                print("Could not access file")
                return self.uploadFileErrorHandler()
            }

            let appCacheUrl =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let copiedSelectedFile = appCacheUrl.appendingPathComponent(fileUrl.lastPathComponent)

            if let dataFromURL = NSData(contentsOf: fileUrl) {
                if dataFromURL.write(to: copiedSelectedFile, atomically: true) {
                    print("file saved [\(copiedSelectedFile.path)]")
                } else {
                    print("Error saving file before uploading")
                    return self.uploadFileErrorHandler()
                }
            }
            fileUrl.stopAccessingSecurityScopedResource()

            let requestUrl = URL(string: "https://omni-crosswords-server-rtluzv2sqq-uc.a.run.app/parsePuzfile")!
            //let requestUrl = URL(string: "http://localhost:8080/parsePuzfile")!
            var request = URLRequest(url: requestUrl)
            request.setValue("Bearer "+self.token, forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"

            // execute network request
            let task = URLSession.shared.uploadTask(with: request, fromFile: copiedSelectedFile) {
                data, response, httpError in
                do {
                    let httpResponse = response as? HTTPURLResponse
                    if (httpError != nil) {
                        print(httpError!.localizedDescription)
                        return self.uploadFileErrorHandler()
                    }
                    if httpResponse!.statusCode != 201 {
                        print("Got a \(httpResponse!.statusCode) on parsePuzfile")
                        print(httpResponse ?? "unknown response")
                        return self.uploadFileErrorHandler()
                    }
                    let crosswordResponse = try JSONDecoder().decode(CrosswordResponse.self, from: data!)
                    DispatchQueue.main.async {
                        do {
                            let crossword = Crossword(context: self.managedObjectContext)
                            DataUtils.jsonToCrossword(crossword: crossword, data: crosswordResponse)
                            crossword.isCustomUpload = true
                            if (!self.overridenOutletName.isEmpty) {
                                crossword.outletName = self.overridenOutletName
                            }
                            try self.managedObjectContext.save()
                            return self.uploadFileCompletionHandler()
                        } catch {
                            print("Error while processing the parsed file locally: \(error)")
                            return self.uploadFileErrorHandler()
                        }
                    }
                } catch {
                    print("Error info: \(error)")
                }
            }
            task.resume()
        }
    }
}
