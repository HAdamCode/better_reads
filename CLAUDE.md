# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Better Reads is a Goodreads alternative with a Flutter mobile app and AWS backend. The repository contains two main components:
- `app/` - Flutter mobile application (iOS/Android)
- `infra/` - AWS CDK infrastructure (TypeScript)

## Commands

### Flutter App (`app/`)
```bash
flutter pub get          # Install dependencies
flutter run              # Run the app
flutter analyze          # Static analysis
flutter test             # Run tests
flutter test test/widget_test.dart  # Run single test file
```

### AWS Infrastructure (`infra/`)
```bash
npm install              # Install dependencies
npm run build            # Compile TypeScript
npm run test             # Run Jest tests
npx cdk deploy           # Deploy to AWS
npx cdk diff             # Compare with deployed stack
npx cdk synth            # Generate CloudFormation template
```

## Architecture

### Data Flow
```
Flutter App → Amplify SDK → AppSync GraphQL → DynamoDB
                ↓
           Cognito Auth
                ↓
              S3 Storage
```

### Flutter App Structure (`app/lib/`)
- **Providers** (`providers/`) - State management using Provider pattern. Each provider handles a domain:
  - `auth_provider.dart` - Authentication state via Amplify Auth
  - `books_provider.dart` - User's book collection, syncs with GraphQL backend
  - `shelves_provider.dart` - Custom shelf management
  - `lending_provider.dart` - Book loan tracking

- **Services** (`services/`) - API integrations:
  - `graphql_service.dart` - All GraphQL operations (singleton pattern)
  - `book_service.dart` - Open Library API for book metadata

- **Models** (`models/`) - Data models with `fromGraphQL()` factory constructors for backend data

- **Screens** (`screens/`) - Full-page UI components
- **Widgets** (`widgets/`) - Reusable UI components
- **Router** (`router.dart`) - GoRouter navigation configuration

### AWS Infrastructure (`infra/lib/`)
- `infra-stack.ts` - Main CDK stack defining all AWS resources
- `schema.graphql` - GraphQL schema for AppSync API

### DynamoDB Tables
| Table | Partition Key | Sort Key | Purpose |
|-------|--------------|----------|---------|
| BetterReads-Users | userId | - | User profiles |
| BetterReads-UserBooks | userId | bookId | User's book shelves |
| BetterReads-CustomShelves | userId | shelfId | Custom shelf definitions |
| BetterReads-BookLoans | userId | loanId | Book lending records |
| BetterReads-Reviews | bookId | reviewId | Book reviews |
| BetterReads-Friends | userId | friendId | Social connections |
| BetterReads-Activity | userId | timestamp | Activity feed |

### Key Patterns
- **Optimistic updates**: Providers update local state immediately, then sync with backend
- **Book metadata caching**: Book details from Open Library are cached locally for offline display
- **GraphQL for user data**: All user data (shelves, loans, ratings) syncs through AppSync to DynamoDB

### Environment Setup
The Flutter app requires `app/.env` file and `app/lib/amplifyconfiguration.dart` (generated from CDK outputs after deployment).

### External APIs
- **Google Books API** - Primary book search (requires API key in `.env`)
- **Open Library API** - Fallback for book metadata and ratings

## Development Guidelines

### Full-Stack Features
New features must be implemented end-to-end:
1. **Schema** - Add types, queries, and mutations to `infra/lib/schema.graphql`
2. **Database** - Add DynamoDB tables/indexes in `infra/lib/infra-stack.ts`
3. **Resolvers** - Add AppSync resolvers in the CDK stack
4. **Deploy** - Run `npx cdk deploy` to update AWS infrastructure
5. **Service** - Add GraphQL operations to `app/lib/services/graphql_service.dart`
6. **Provider** - Create/update provider to sync with backend (not local storage)
7. **UI** - Build screens and widgets

All user data must persist to DynamoDB via GraphQL—do not use SharedPreferences for user data (only for local caching of book metadata).
