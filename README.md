# TbilisiCleanups
An iOS app for reporting littered places in Georgia for the Tbilisi Clean-ups project (https://nogarba.ge)


## How To Build And Run

### Preparation Steps

#### Firebase

The app is using Firebase for many purposes.

However, the Firebase configuration is not included in the repository for security purposes. 

The actual configuration for release builds gets copied into the sources folder in the CI pipeline.
 
For development, create your own Firebase project and download the `GoogleService-Info.plist` file.

You will later need to copy this file into the project, as described in the "Main Steps" section.

#### AWS S3 Configuration

The app is using the [Soto](https://github.com/soto-project/soto) library to upload images and videos to S3.

The configuration is again not stored in the repository.

Prepare a SotoAWS.plist file with the following keys:
* `ACCESS_KEY_ID` (String) — AWS access key ID.
* `SECRET_ACCESS_KEY` (String) — AWS secret access key.
* `S3_BUCKET_NAME` (String) — Name of the bucket where the app should upload media content.
* `S3_REGION` (String) — Region of the bucket. For example, `eu-west-1`.

You will later need to copy this file into the project, as described in the "Main Steps" section.

### Main Steps

1. Clone this repository.
2. Using the latest stable version of Xcode, open the project. 
3. Copy the downloaded `GoogleService-Info.plist` file into the `Firebase/` directory.
4. Copy the prepared `SotoAWS.plist` file into the `AWS/` directory.
5. Click Run.

