import SotoS3

final class S3Service {

    private let awsClient: AWSClient

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
    }
}
