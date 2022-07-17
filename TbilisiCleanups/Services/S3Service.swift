import Foundation
import SotoS3

final class S3Service {

    private let bucketName: String
    private let awsClient: AWSClient
    private let s3: S3

    init() throws {
        let config = try SotoAWSConfigHelper.getConfig()
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
        s3 = S3(client: awsClient, region: .eucentral1)
    }

    func upload(data: Data, withKey key: String) async throws {
        let request = S3.PutObjectRequest(
            body: .data(data),
            bucket: bucketName,
            key: key
        )
        let _ = try await s3.putObject(request)
    }
}
