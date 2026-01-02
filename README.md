# Better Reads

A modern Goodreads alternative with better UI/UX, smart recommendations, social features, and reading analytics.

## Tech Stack

- **Mobile**: Flutter (iOS + Android)
- **Backend**: AWS Amplify + AppSync (GraphQL)
- **Database**: DynamoDB
- **Auth**: AWS Cognito
- **IaC**: AWS CDK (TypeScript)
- **Book Data**: Open Library API

## Project Structure

```
better_reads/
├── app/                    # Flutter mobile app
│   ├── lib/
│   │   ├── models/         # Data models
│   │   ├── screens/        # UI screens
│   │   ├── widgets/        # Reusable components
│   │   ├── services/       # API services
│   │   ├── providers/      # State management
│   │   └── utils/          # Helpers
│   └── pubspec.yaml
├── infra/                  # AWS CDK infrastructure
│   ├── lib/
│   │   ├── infra-stack.ts
│   │   └── schema.graphql
│   └── package.json
└── README.md
```

## Features

- **Book Search**: Search millions of books via Open Library API
- **Shelves**: Organize books into Want to Read, Currently Reading, and Read
- **Ratings & Reviews**: Rate and review books
- **Reading Stats**: Track your reading progress and goals
- **Social**: Connect with friends and see their activity
- **Recommendations**: Discover new books based on your reading history

## Getting Started

### Prerequisites

- Flutter SDK 3.9+
- Node.js 18+
- AWS CLI configured
- AWS CDK CLI (`npm install -g aws-cdk`)

### Flutter App

```bash
cd app
flutter pub get
flutter run
```

### Deploy Infrastructure

```bash
cd infra
npm install
npx cdk deploy
```

After deployment, copy the outputs (UserPoolId, UserPoolClientId, GraphQLApiUrl) to configure Amplify in the Flutter app.

## Development

The app currently works in offline mode with local state. To enable backend sync:

1. Deploy the CDK infrastructure
2. Configure `amplifyconfiguration.dart` with the deployment outputs
3. Uncomment the Amplify initialization in `main.dart`
