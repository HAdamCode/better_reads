import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as appsync from 'aws-cdk-lib/aws-appsync';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';
import * as path from 'path';

export class InfraStack extends cdk.Stack {
  public readonly userPool: cognito.UserPool;
  public readonly userPoolClient: cognito.UserPoolClient;
  public readonly identityPool: cognito.CfnIdentityPool;
  public readonly storageBucket: s3.Bucket;
  public readonly api: appsync.GraphqlApi;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ========================================
    // COGNITO USER POOL (Authentication)
    // ========================================
    this.userPool = new cognito.UserPool(this, 'BetterReadsUserPool', {
      userPoolName: 'better-reads-users',
      selfSignUpEnabled: true,
      signInAliases: {
        email: true,
      },
      autoVerify: {
        email: true,
      },
      standardAttributes: {
        email: {
          required: true,
          mutable: true,
        },
        fullname: {
          required: false,
          mutable: true,
        },
      },
      customAttributes: {
        displayName: new cognito.StringAttribute({ mutable: true }),
        bio: new cognito.StringAttribute({ mutable: true }),
        avatarUrl: new cognito.StringAttribute({ mutable: true }),
      },
      passwordPolicy: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireDigits: true,
        requireSymbols: false,
      },
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // Change to RETAIN for production
    });

    this.userPoolClient = this.userPool.addClient('BetterReadsAppClient', {
      userPoolClientName: 'better-reads-app',
      authFlows: {
        userPassword: true,
        userSrp: true,
      },
      oAuth: {
        flows: {
          authorizationCodeGrant: true,
        },
        scopes: [cognito.OAuthScope.EMAIL, cognito.OAuthScope.OPENID, cognito.OAuthScope.PROFILE],
        callbackUrls: ['betterreads://callback'],
        logoutUrls: ['betterreads://signout'],
      },
      preventUserExistenceErrors: true,
    });

    // ========================================
    // S3 STORAGE BUCKET (Profile Pictures)
    // ========================================
    this.storageBucket = new s3.Bucket(this, 'BetterReadsStorage', {
      bucketName: `better-reads-storage-${this.account}-${this.region}`,
      cors: [
        {
          allowedMethods: [
            s3.HttpMethods.GET,
            s3.HttpMethods.PUT,
            s3.HttpMethods.POST,
            s3.HttpMethods.DELETE,
            s3.HttpMethods.HEAD,
          ],
          allowedOrigins: ['*'],
          allowedHeaders: ['*'],
          exposedHeaders: [
            'x-amz-server-side-encryption',
            'x-amz-request-id',
            'x-amz-id-2',
            'ETag',
          ],
          maxAge: 3000,
        },
      ],
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    // ========================================
    // COGNITO IDENTITY POOL (For S3 Access)
    // ========================================
    this.identityPool = new cognito.CfnIdentityPool(this, 'BetterReadsIdentityPool', {
      identityPoolName: 'better_reads_identity_pool',
      allowUnauthenticatedIdentities: false,
      cognitoIdentityProviders: [
        {
          clientId: this.userPoolClient.userPoolClientId,
          providerName: this.userPool.userPoolProviderName,
        },
      ],
    });

    // Authenticated role for identity pool
    const authenticatedRole = new iam.Role(this, 'CognitoAuthenticatedRole', {
      assumedBy: new iam.FederatedPrincipal(
        'cognito-identity.amazonaws.com',
        {
          StringEquals: {
            'cognito-identity.amazonaws.com:aud': this.identityPool.ref,
          },
          'ForAnyValue:StringLike': {
            'cognito-identity.amazonaws.com:amr': 'authenticated',
          },
        },
        'sts:AssumeRoleWithWebIdentity'
      ),
    });

    // Grant S3 access to authenticated users
    authenticatedRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['s3:GetObject', 's3:PutObject', 's3:DeleteObject'],
        resources: [
          `${this.storageBucket.bucketArn}/private/*`,
          `${this.storageBucket.bucketArn}/protected/*`,
          `${this.storageBucket.bucketArn}/public/*`,
        ],
      })
    );

    // Allow listing objects
    authenticatedRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['s3:ListBucket'],
        resources: [this.storageBucket.bucketArn],
      })
    );

    // Attach roles to identity pool
    new cognito.CfnIdentityPoolRoleAttachment(this, 'IdentityPoolRoleAttachment', {
      identityPoolId: this.identityPool.ref,
      roles: {
        authenticated: authenticatedRole.roleArn,
      },
    });

    // ========================================
    // DYNAMODB TABLES
    // ========================================

    // Users table
    const usersTable = new dynamodb.Table(this, 'UsersTable', {
      tableName: 'BetterReads-Users',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Add GSI for email lookup
    usersTable.addGlobalSecondaryIndex({
      indexName: 'byEmail',
      partitionKey: { name: 'email', type: dynamodb.AttributeType.STRING },
    });

    // Books cache table
    const booksTable = new dynamodb.Table(this, 'BooksTable', {
      tableName: 'BetterReads-Books',
      partitionKey: { name: 'isbn', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      timeToLiveAttribute: 'ttl', // Cache expiration
    });

    // UserBooks table (shelves)
    const userBooksTable = new dynamodb.Table(this, 'UserBooksTable', {
      tableName: 'BetterReads-UserBooks',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'bookId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Add GSI for shelf queries
    userBooksTable.addGlobalSecondaryIndex({
      indexName: 'byShelf',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'shelf', type: dynamodb.AttributeType.STRING },
    });

    // Reviews table
    const reviewsTable = new dynamodb.Table(this, 'ReviewsTable', {
      tableName: 'BetterReads-Reviews',
      partitionKey: { name: 'bookId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'reviewId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Add GSI for user's reviews
    reviewsTable.addGlobalSecondaryIndex({
      indexName: 'byUser',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'createdAt', type: dynamodb.AttributeType.STRING },
    });

    // Friends table
    const friendsTable = new dynamodb.Table(this, 'FriendsTable', {
      tableName: 'BetterReads-Friends',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'friendId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Activity feed table
    const activityTable = new dynamodb.Table(this, 'ActivityTable', {
      tableName: 'BetterReads-Activity',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'timestamp', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      timeToLiveAttribute: 'ttl', // Auto-cleanup old activity
    });

    // Reading stats table
    const readingStatsTable = new dynamodb.Table(this, 'ReadingStatsTable', {
      tableName: 'BetterReads-ReadingStats',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'period', type: dynamodb.AttributeType.STRING }, // e.g., "2024", "2024-01"
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Custom shelves table
    const customShelvesTable = new dynamodb.Table(this, 'CustomShelvesTable', {
      tableName: 'BetterReads-CustomShelves',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'shelfId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Book loans table
    const bookLoansTable = new dynamodb.Table(this, 'BookLoansTable', {
      tableName: 'BetterReads-BookLoans',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'loanId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Add GSI for active loans lookup by bookId
    bookLoansTable.addGlobalSecondaryIndex({
      indexName: 'byBook',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'bookId', type: dynamodb.AttributeType.STRING },
    });

    // ========================================
    // APPSYNC GRAPHQL API
    // ========================================
    this.api = new appsync.GraphqlApi(this, 'BetterReadsApi', {
      name: 'BetterReadsApi',
      definition: appsync.Definition.fromFile(path.join(__dirname, 'schema.graphql')),
      authorizationConfig: {
        defaultAuthorization: {
          authorizationType: appsync.AuthorizationType.USER_POOL,
          userPoolConfig: {
            userPool: this.userPool,
          },
        },
        additionalAuthorizationModes: [
          {
            authorizationType: appsync.AuthorizationType.IAM,
          },
        ],
      },
      logConfig: {
        fieldLogLevel: appsync.FieldLogLevel.ERROR,
      },
      xrayEnabled: true,
    });

    // Create DynamoDB data sources
    const usersDataSource = this.api.addDynamoDbDataSource('UsersDataSource', usersTable);
    const booksDataSource = this.api.addDynamoDbDataSource('BooksDataSource', booksTable);
    const userBooksDataSource = this.api.addDynamoDbDataSource('UserBooksDataSource', userBooksTable);
    const reviewsDataSource = this.api.addDynamoDbDataSource('ReviewsDataSource', reviewsTable);
    const friendsDataSource = this.api.addDynamoDbDataSource('FriendsDataSource', friendsTable);
    const activityDataSource = this.api.addDynamoDbDataSource('ActivityDataSource', activityTable);
    const readingStatsDataSource = this.api.addDynamoDbDataSource('ReadingStatsDataSource', readingStatsTable);
    const customShelvesDataSource = this.api.addDynamoDbDataSource('CustomShelvesDataSource', customShelvesTable);
    const bookLoansDataSource = this.api.addDynamoDbDataSource('BookLoansDataSource', bookLoansTable);

    // ========================================
    // RESOLVERS
    // ========================================

    // User resolvers
    usersDataSource.createResolver('GetUserResolver', {
      typeName: 'Query',
      fieldName: 'getUser',
      requestMappingTemplate: appsync.MappingTemplate.dynamoDbGetItem('userId', 'userId'),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    usersDataSource.createResolver('GetMeResolver', {
      typeName: 'Query',
      fieldName: 'me',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "GetItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    usersDataSource.createResolver('CreateUserResolver', {
      typeName: 'Mutation',
      fieldName: 'createUser',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "PutItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
          },
          "attributeValues": {
            "email": $util.dynamodb.toDynamoDBJson($ctx.args.input.email),
            "displayName": $util.dynamodb.toDynamoDBJson($ctx.args.input.displayName),
            "createdAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601()),
            "updatedAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601())
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // UserBooks resolvers
    userBooksDataSource.createResolver('GetUserBooksResolver', {
      typeName: 'Query',
      fieldName: 'getUserBooks',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "Query",
          "query": {
            "expression": "userId = :userId",
            "expressionValues": {
              ":userId": $util.dynamodb.toDynamoDBJson($ctx.args.userId)
            }
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultList(),
    });

    userBooksDataSource.createResolver('GetMyBooksResolver', {
      typeName: 'Query',
      fieldName: 'myBooks',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "Query",
          "query": {
            "expression": "userId = :userId",
            "expressionValues": {
              ":userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
            }
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultList(),
    });

    userBooksDataSource.createResolver('AddBookToShelfResolver', {
      typeName: 'Mutation',
      fieldName: 'addBookToShelf',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "PutItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
            "bookId": $util.dynamodb.toDynamoDBJson($ctx.args.input.bookId)
          },
          "attributeValues": {
            "shelf": $util.dynamodb.toDynamoDBJson($ctx.args.input.shelf),
            "addedAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601()),
            #if($ctx.args.input.customShelfIds)
            "customShelfIds": $util.dynamodb.toDynamoDBJson($ctx.args.input.customShelfIds),
            #end
            #if($ctx.args.input.rating)
            "rating": $util.dynamodb.toDynamoDBJson($ctx.args.input.rating),
            #end
            #if($ctx.args.input.startedAt)
            "startedAt": $util.dynamodb.toDynamoDBJson($ctx.args.input.startedAt),
            #end
            #if($ctx.args.input.finishedAt)
            "finishedAt": $util.dynamodb.toDynamoDBJson($ctx.args.input.finishedAt),
            #end
            #if($ctx.args.input.pagesRead)
            "pagesRead": $util.dynamodb.toDynamoDBJson($ctx.args.input.pagesRead),
            #end
            "updatedAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601())
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    userBooksDataSource.createResolver('UpdateBookShelfResolver', {
      typeName: 'Mutation',
      fieldName: 'updateBookShelf',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        #set($expression = "SET #shelf = :shelf, updatedAt = :updatedAt")
        #set($expressionValues = {
          ":shelf": $util.dynamodb.toDynamoDB($ctx.args.input.shelf),
          ":updatedAt": $util.dynamodb.toDynamoDB($util.time.nowISO8601())
        })
        #if($ctx.args.input.customShelfIds)
          #set($expression = "$expression, customShelfIds = :customShelfIds")
          $util.qr($expressionValues.put(":customShelfIds", $util.dynamodb.toDynamoDB($ctx.args.input.customShelfIds)))
        #end
        #if($ctx.args.input.rating)
          #set($expression = "$expression, rating = :rating")
          $util.qr($expressionValues.put(":rating", $util.dynamodb.toDynamoDB($ctx.args.input.rating)))
        #end
        #if($ctx.args.input.startedAt)
          #set($expression = "$expression, startedAt = :startedAt")
          $util.qr($expressionValues.put(":startedAt", $util.dynamodb.toDynamoDB($ctx.args.input.startedAt)))
        #end
        #if($ctx.args.input.finishedAt)
          #set($expression = "$expression, finishedAt = :finishedAt")
          $util.qr($expressionValues.put(":finishedAt", $util.dynamodb.toDynamoDB($ctx.args.input.finishedAt)))
        #end
        #if($ctx.args.input.pagesRead)
          #set($expression = "$expression, pagesRead = :pagesRead")
          $util.qr($expressionValues.put(":pagesRead", $util.dynamodb.toDynamoDB($ctx.args.input.pagesRead)))
        #end
        {
          "version": "2017-02-28",
          "operation": "UpdateItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
            "bookId": $util.dynamodb.toDynamoDBJson($ctx.args.input.bookId)
          },
          "update": {
            "expression": "$expression",
            "expressionNames": {
              "#shelf": "shelf"
            },
            "expressionValues": $util.toJson($expressionValues)
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    userBooksDataSource.createResolver('RemoveBookFromShelfResolver', {
      typeName: 'Mutation',
      fieldName: 'removeBookFromShelf',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "DeleteItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
            "bookId": $util.dynamodb.toDynamoDBJson($ctx.args.bookId)
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // Review resolvers
    reviewsDataSource.createResolver('GetBookReviewsResolver', {
      typeName: 'Query',
      fieldName: 'getBookReviews',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "Query",
          "query": {
            "expression": "bookId = :bookId",
            "expressionValues": {
              ":bookId": $util.dynamodb.toDynamoDBJson($ctx.args.bookId)
            }
          },
          "limit": $util.defaultIfNull($ctx.args.limit, 20),
          "scanIndexForward": false
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultList(),
    });

    reviewsDataSource.createResolver('CreateReviewResolver', {
      typeName: 'Mutation',
      fieldName: 'createReview',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "PutItem",
          "key": {
            "bookId": $util.dynamodb.toDynamoDBJson($ctx.args.input.bookId),
            "reviewId": $util.dynamodb.toDynamoDBJson($util.autoId())
          },
          "attributeValues": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
            "rating": $util.dynamodb.toDynamoDBJson($ctx.args.input.rating),
            "content": $util.dynamodb.toDynamoDBJson($ctx.args.input.content),
            "createdAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601())
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // Friends resolvers
    friendsDataSource.createResolver('GetFriendsResolver', {
      typeName: 'Query',
      fieldName: 'getFriends',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "Query",
          "query": {
            "expression": "userId = :userId",
            "expressionValues": {
              ":userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
            }
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultList(),
    });

    friendsDataSource.createResolver('AddFriendResolver', {
      typeName: 'Mutation',
      fieldName: 'addFriend',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "PutItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
            "friendId": $util.dynamodb.toDynamoDBJson($ctx.args.friendId)
          },
          "attributeValues": {
            "status": $util.dynamodb.toDynamoDBJson("PENDING"),
            "createdAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601())
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // Activity resolvers
    activityDataSource.createResolver('GetActivityFeedResolver', {
      typeName: 'Query',
      fieldName: 'getActivityFeed',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "Query",
          "query": {
            "expression": "userId = :userId",
            "expressionValues": {
              ":userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
            }
          },
          "limit": $util.defaultIfNull($ctx.args.limit, 20),
          "scanIndexForward": false
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultList(),
    });

    // Reading stats resolvers
    readingStatsDataSource.createResolver('GetReadingStatsResolver', {
      typeName: 'Query',
      fieldName: 'getReadingStats',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "Query",
          "query": {
            "expression": "userId = :userId",
            "expressionValues": {
              ":userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
            }
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultList(),
    });

    // ========================================
    // CUSTOM SHELVES RESOLVERS
    // ========================================
    customShelvesDataSource.createResolver('GetMyCustomShelvesResolver', {
      typeName: 'Query',
      fieldName: 'myCustomShelves',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "Query",
          "query": {
            "expression": "userId = :userId",
            "expressionValues": {
              ":userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
            }
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultList(),
    });

    customShelvesDataSource.createResolver('CreateCustomShelfResolver', {
      typeName: 'Mutation',
      fieldName: 'createCustomShelf',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "PutItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
            "shelfId": $util.dynamodb.toDynamoDBJson($util.autoId())
          },
          "attributeValues": {
            "name": $util.dynamodb.toDynamoDBJson($ctx.args.input.name),
            #if($ctx.args.input.description)
            "description": $util.dynamodb.toDynamoDBJson($ctx.args.input.description),
            #end
            "createdAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601()),
            "updatedAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601())
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    customShelvesDataSource.createResolver('UpdateCustomShelfResolver', {
      typeName: 'Mutation',
      fieldName: 'updateCustomShelf',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "UpdateItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
            "shelfId": $util.dynamodb.toDynamoDBJson($ctx.args.input.shelfId)
          },
          "update": {
            "expression": "SET #name = if_not_exists(:name, #name), updatedAt = :updatedAt #if($ctx.args.input.description), description = :description #end",
            "expressionNames": {
              "#name": "name"
            },
            "expressionValues": {
              ":name": $util.dynamodb.toDynamoDBJson($ctx.args.input.name),
              ":updatedAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601())
              #if($ctx.args.input.description)
              ,":description": $util.dynamodb.toDynamoDBJson($ctx.args.input.description)
              #end
            }
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    customShelvesDataSource.createResolver('DeleteCustomShelfResolver', {
      typeName: 'Mutation',
      fieldName: 'deleteCustomShelf',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "DeleteItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
            "shelfId": $util.dynamodb.toDynamoDBJson($ctx.args.shelfId)
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    customShelvesDataSource.createResolver('UpdateShelfBookRatingResolver', {
      typeName: 'Mutation',
      fieldName: 'updateShelfBookRating',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        #if($ctx.args.rating)
          ## Set or update the rating for this book
          ## First ensure bookRatings map exists, then set the nested key
          {
            "version": "2017-02-28",
            "operation": "UpdateItem",
            "key": {
              "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
              "shelfId": $util.dynamodb.toDynamoDBJson($ctx.args.shelfId)
            },
            "update": {
              "expression": "SET #bookRatings = if_not_exists(#bookRatings, :emptyMap), #bookRatings.#bookId = :rating, updatedAt = :updatedAt",
              "expressionNames": {
                "#bookRatings": "bookRatings",
                "#bookId": "$ctx.args.bookId"
              },
              "expressionValues": {
                ":emptyMap": { "M": {} },
                ":rating": $util.dynamodb.toDynamoDBJson($ctx.args.rating),
                ":updatedAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601())
              }
            }
          }
        #else
          ## Remove the rating for this book
          {
            "version": "2017-02-28",
            "operation": "UpdateItem",
            "key": {
              "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
              "shelfId": $util.dynamodb.toDynamoDBJson($ctx.args.shelfId)
            },
            "update": {
              "expression": "REMOVE bookRatings.#bookId SET updatedAt = :updatedAt",
              "expressionNames": {
                "#bookId": "$ctx.args.bookId"
              },
              "expressionValues": {
                ":updatedAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601())
              }
            }
          }
        #end
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // ========================================
    // BOOK LOANS RESOLVERS
    // ========================================
    bookLoansDataSource.createResolver('GetMyLoansResolver', {
      typeName: 'Query',
      fieldName: 'myLoans',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "Query",
          "query": {
            "expression": "userId = :userId",
            "expressionValues": {
              ":userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
            }
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultList(),
    });

    bookLoansDataSource.createResolver('GetActiveLoansResolver', {
      typeName: 'Query',
      fieldName: 'activeLoans',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "Query",
          "query": {
            "expression": "userId = :userId",
            "expressionValues": {
              ":userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
            }
          },
          "filter": {
            "expression": "attribute_not_exists(returnedAt)"
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultList(),
    });

    bookLoansDataSource.createResolver('LendBookResolver', {
      typeName: 'Mutation',
      fieldName: 'lendBook',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "PutItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
            "loanId": $util.dynamodb.toDynamoDBJson($util.autoId())
          },
          "attributeValues": {
            "bookId": $util.dynamodb.toDynamoDBJson($ctx.args.input.bookId),
            "borrowerName": $util.dynamodb.toDynamoDBJson($ctx.args.input.borrowerName),
            "lentAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601())
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    bookLoansDataSource.createResolver('ReturnBookResolver', {
      typeName: 'Mutation',
      fieldName: 'returnBook',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "UpdateItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
            "loanId": $util.dynamodb.toDynamoDBJson($ctx.args.loanId)
          },
          "update": {
            "expression": "SET returnedAt = :returnedAt",
            "expressionValues": {
              ":returnedAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601())
            }
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    bookLoansDataSource.createResolver('UpdateLoanResolver', {
      typeName: 'Mutation',
      fieldName: 'updateLoan',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "UpdateItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
            "loanId": $util.dynamodb.toDynamoDBJson($ctx.args.input.loanId)
          },
          "update": {
            "expression": "SET borrowerName = :borrowerName",
            "expressionValues": {
              ":borrowerName": $util.dynamodb.toDynamoDBJson($ctx.args.input.borrowerName)
            }
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    bookLoansDataSource.createResolver('DeleteLoanResolver', {
      typeName: 'Mutation',
      fieldName: 'deleteLoan',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
        {
          "version": "2017-02-28",
          "operation": "DeleteItem",
          "key": {
            "userId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub),
            "loanId": $util.dynamodb.toDynamoDBJson($ctx.args.loanId)
          }
        }
      `),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // ========================================
    // OUTPUTS
    // ========================================
    new cdk.CfnOutput(this, 'UserPoolId', {
      value: this.userPool.userPoolId,
      description: 'Cognito User Pool ID',
    });

    new cdk.CfnOutput(this, 'UserPoolClientId', {
      value: this.userPoolClient.userPoolClientId,
      description: 'Cognito User Pool Client ID',
    });

    new cdk.CfnOutput(this, 'GraphQLApiUrl', {
      value: this.api.graphqlUrl,
      description: 'AppSync GraphQL API URL',
    });

    new cdk.CfnOutput(this, 'GraphQLApiId', {
      value: this.api.apiId,
      description: 'AppSync GraphQL API ID',
    });

    new cdk.CfnOutput(this, 'Region', {
      value: this.region,
      description: 'AWS Region',
    });

    new cdk.CfnOutput(this, 'IdentityPoolId', {
      value: this.identityPool.ref,
      description: 'Cognito Identity Pool ID',
    });

    new cdk.CfnOutput(this, 'StorageBucketName', {
      value: this.storageBucket.bucketName,
      description: 'S3 Storage Bucket Name',
    });
  }
}
