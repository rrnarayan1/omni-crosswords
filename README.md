# omni-crosswords
Omni Crosswords is an iOS app that fetches crosswords from Firebase Cloud Firestore and enables users to complete them on a iOS Device..

## Development
Omni Crosswords uses SwiftUI. 

Use XCode to open the .xcodeproj file. There are two options to enable a successful build.

### Firebase
Set up Firebase Cloud Firestore, and add the `GoogleService-Info.plist` file to the root directory. Make sure anonymous authentication is enabled.

The app expects a collection named "crosswords". An example document (in JSON) can be found in [sampleData.json](crosswords/SampleDataFiles/sampleData.json). 
The "id" field contains the expected format of the document id. Data is transformed from Firebase in [JsonToCrossword.swift](crosswords/Utils/DataUtils.swift).

### LocalMode
1. Remove the dependency in the build on `GoogleService-Info.plist` in Build Phases > Copy Bundle Resources
2. Change [DevOverrides.plist](crosswords/DevOverrides.plist) to set `localMode` to `true`
  * This will automatically show one crossword in the list - this crossword data be changed by
     changing [sampleData.json](crosswords/SampleDataFiles/sampleData.json). It will only show one crossword.
  * If you want to add another crossword for testing, you can visit the "Upload" tab in localMode, and you can type in a filename to add
    (don't include the .json extension) - you can add the other files in the [SampleDataFiles](crosswords/SampleDataFiles) directory
3. Do not commit these changes. (git update-index --skip-worktree crosswords/DevOverrides.plist is your friend!)
