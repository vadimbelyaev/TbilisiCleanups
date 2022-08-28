import Foundation
import SotoS3

final class S3Service {
    private let bucketName: String
    private let awsClient: AWSClient
    private let s3: S3 // swiftlint:disable:this identifier_name
    private let config: SotoAWSConfig

    init() throws {
        config = try SotoAWSConfigHelper.getConfig()
        awsClient = AWSClient(
            credentialProvider: .static(
                accessKeyId: config.accessKeyId,
                secretAccessKey: config.secretAccessKey
            ),
            retryPolicy: .default,
            middlewares: [],
            options: .init(),
            httpClientProvider: .createNew,
            logger: .init(label: "AWSClient")
        )
        bucketName = config.s3BucketName
        s3 = S3(client: awsClient, region: config.s3Region)
    }

    /// Uploads data to S3 and return its public URL
    /// - Parameters:
    ///   - data: Data to be uploaded
    ///   - key: File name
    ///   - contentType: MIME type of the content
    /// - Returns: Public URL of the uploaded resource
    func upload(
        data: Data,
        withKey key: String,
        contentType: String?
    ) async throws -> URL {
        let request = S3.PutObjectRequest(
            body: .data(data),
            bucket: bucketName,
            contentType: contentType,
            key: key
        )
        _ = try await s3.putObject(request)
        let urlString =
            """
            https://s3.\(config.s3Region.rawValue).amazonaws.com/\
            \(config.s3BucketName)/\(key)
            """
        guard let url = URL(string: urlString) else {
            throw S3ServiceError.cannotBuildResourceURL
        }
        return url
    }

    enum S3ServiceError: Error {
        case cannotBuildResourceURL
    }
}
