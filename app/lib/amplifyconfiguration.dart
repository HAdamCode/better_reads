const amplifyconfig = '''{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.1.0",
        "Version": "0.1.0",
        "IdentityManager": {
          "Default": {}
        },
        "CredentialsProvider": {
          "CognitoIdentity": {
            "Default": {
              "PoolId": "us-east-1:7f7e53ad-a150-4600-97b7-0d19a24dd829",
              "Region": "us-east-1"
            }
          }
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_Z7p84sjCu",
            "AppClientId": "5pn8fc00fctv0s8kjb0s01ivi3",
            "Region": "us-east-1"
          }
        }
      }
    }
  },
  "api": {
    "plugins": {
      "awsAPIPlugin": {
        "BetterReadsApi": {
          "endpointType": "GraphQL",
          "endpoint": "https://xtdegomfevfdvdwu2runzhqbay.appsync-api.us-east-1.amazonaws.com/graphql",
          "region": "us-east-1",
          "authorizationType": "AMAZON_COGNITO_USER_POOLS"
        }
      }
    }
  },
  "storage": {
    "plugins": {
      "awsS3StoragePlugin": {
        "bucket": "better-reads-storage-972890651266-us-east-1",
        "region": "us-east-1",
        "defaultAccessLevel": "protected"
      }
    }
  }
}''';
