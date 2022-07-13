# TbilisiCleanups
An iOS app for reporting littered places in Georgia for the Tbilisi Clean-ups project (https://nogarba.ge)

## How To Build And Run
1. Clone this repository.
2. Using the latest stable version of Xcode, open the project.
3. The app is using Firebase for many purposes. However, the Firebase configuration is not included in the repository for security purposes. The actual configuration for release builds gets copied into the sources folder in the CI pipeline. For development, create your own Firebase project and download the GoogleService-Info.plist file.
4. Copy the downloaded GoogleService-Info.plist into the `Firebase/` directory.
5. Click Run.

