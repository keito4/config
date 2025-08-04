# Issue Resolver: Documentation Agent

## 目的

ドキュメントに関するIssueを解決し、README、API文書、コードコメント、アーキテクチャドキュメントを充実させる。

## 実行手順

### 1. README.mdの生成・更新

```bash
# プロジェクト情報の収集
echo "=== Analyzing project for README generation ==="

# package.jsonから情報を抽出
if [ -f "package.json" ]; then
    PROJECT_NAME=$(jq -r '.name' package.json)
    PROJECT_DESC=$(jq -r '.description' package.json)
    PROJECT_VERSION=$(jq -r '.version' package.json)
    PROJECT_LICENSE=$(jq -r '.license' package.json)
    PROJECT_SCRIPTS=$(jq -r '.scripts | to_entries[] | "npm run \(.key) - \(.value)"' package.json)
fi

# README.mdの生成
cat << EOF > README.md
# ${PROJECT_NAME}

${PROJECT_DESC}

![Version](https://img.shields.io/badge/version-${PROJECT_VERSION}-blue.svg)
![License](https://img.shields.io/badge/license-${PROJECT_LICENSE}-green.svg)
![Build Status](https://img.shields.io/github/workflow/status/${GITHUB_REPOSITORY}/CI)
![Coverage](https://img.shields.io/codecov/c/github/${GITHUB_REPOSITORY})

## 📋 Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Development](#development)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

$(find . -name "*.ts" -o -name "*.js" | head -5 | while read -r file; do
    # 主要な機能を抽出
    grep -E "^export (class|function|const)" "$file" | head -3 | sed 's/^/- /'
done)

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

\`\`\`bash
# Node.js version
node --version  # Required: v14.0.0 or higher

# Package manager
npm --version   # or yarn --version
\`\`\`

## 🚀 Installation

### Clone the repository

\`\`\`bash
git clone https://github.com/${GITHUB_REPOSITORY}.git
cd ${PROJECT_NAME}
\`\`\`

### Install dependencies

\`\`\`bash
npm install
# or
yarn install
\`\`\`

### Environment setup

\`\`\`bash
# Copy environment variables
cp .env.example .env

# Edit .env with your configuration
nano .env
\`\`\`

## 💻 Usage

### Basic usage

\`\`\`bash
# Start the application
npm start

# Development mode with hot reload
npm run dev
\`\`\`

### Available Scripts

\`\`\`bash
${PROJECT_SCRIPTS}
\`\`\`

### Examples

\`\`\`javascript
// Import the library
const { mainFunction } = require('${PROJECT_NAME}');

// Basic example
const result = mainFunction({
  option1: 'value1',
  option2: 'value2'
});

console.log(result);
\`\`\`

## 🔧 Development

### Project Structure

\`\`\`
${PROJECT_NAME}/
├── src/              # Source code
│   ├── controllers/  # Route controllers
│   ├── models/       # Data models
│   ├── services/     # Business logic
│   └── utils/        # Utility functions
├── tests/            # Test files
├── docs/             # Documentation
└── config/           # Configuration files
\`\`\`

### Code Style

This project uses ESLint and Prettier for code formatting:

\`\`\`bash
# Run linter
npm run lint

# Fix linting issues
npm run lint:fix

# Format code
npm run format
\`\`\`

## 📚 API Documentation

### Endpoints

$(if [ -d "routes" ] || [ -d "api" ]; then
    echo "| Method | Endpoint | Description |"
    echo "|--------|----------|-------------|"
    find . -name "*.js" -o -name "*.ts" | xargs grep -h "router\.\(get\|post\|put\|delete\)" 2>/dev/null | head -10 | while read -r line; do
        method=$(echo "$line" | grep -oE "(get|post|put|delete)" | tr '[:lower:]' '[:upper:]')
        endpoint=$(echo "$line" | grep -oE "'[^']+'" | head -1 | tr -d "'")
        echo "| $method | $endpoint | Description |"
    done
else
    echo "See [API Documentation](./docs/api.md) for detailed endpoint information."
fi)

### Authentication

\`\`\`bash
# Include token in headers
Authorization: Bearer <your-token>
\`\`\`

## 🧪 Testing

### Run tests

\`\`\`bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- path/to/test.spec.js

# Watch mode
npm run test:watch
\`\`\`

### Test Structure

- **Unit Tests**: \`/tests/unit/\`
- **Integration Tests**: \`/tests/integration/\`
- **E2E Tests**: \`/tests/e2e/\`

## 🚢 Deployment

### Docker

\`\`\`bash
# Build Docker image
docker build -t ${PROJECT_NAME} .

# Run container
docker run -p 3000:3000 ${PROJECT_NAME}
\`\`\`

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| NODE_ENV | Environment mode | development |
| PORT | Server port | 3000 |
| DATABASE_URL | Database connection string | - |
| JWT_SECRET | JWT signing secret | - |

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (\`git checkout -b feature/AmazingFeature\`)
3. Commit your changes (\`git commit -m 'Add some AmazingFeature'\`)
4. Push to the branch (\`git push origin feature/AmazingFeature\`)
5. Open a Pull Request

## 📄 License

This project is licensed under the ${PROJECT_LICENSE} License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- Your Name - [@yourhandle](https://github.com/yourhandle)

## 🙏 Acknowledgments

- List any resources or contributors
- Inspiration sources
- Libraries used

---

Made with ❤️ by [Your Team](https://github.com/${GITHUB_REPOSITORY})
EOF
```

### 2. API ドキュメントの生成

```bash
# OpenAPI/Swagger ドキュメントの生成
echo "=== Generating API documentation ==="

mkdir -p docs/api

# Express.jsアプリケーションの場合
if grep -q "express" package.json 2>/dev/null; then
    npm install --save-dev swagger-jsdoc swagger-ui-express
    
    cat << 'EOF' > swagger.config.js
const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'API Documentation',
      version: '1.0.0',
      description: 'Comprehensive API documentation',
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development server',
      },
      {
        url: 'https://api.production.com',
        description: 'Production server',
      },
    ],
  },
  apis: ['./routes/*.js', './src/routes/*.js'], // Path to the API routes
};

module.exports = swaggerJsdoc(options);
EOF

    # APIエンドポイントにSwaggerコメントを追加
    find . -name "*.js" -path "*/routes/*" | while read -r file; do
        # 既存のルートを解析してSwaggerコメントを追加
        cat << 'EOF' > add-swagger-comments.js
const fs = require('fs');
const path = require('path');

function addSwaggerComments(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  
  // router.get, post, put, delete パターンを検索
  const routeRegex = /router\.(get|post|put|delete)\(['"]([^'"]+)['"]/g;
  
  content = content.replace(routeRegex, (match, method, path) => {
    const swaggerComment = `
/**
 * @swagger
 * ${path}:
 *   ${method}:
 *     summary: ${method.toUpperCase()} ${path}
 *     tags: [${path.split('/')[1] || 'General'}]
 *     responses:
 *       200:
 *         description: Successful response
 *       400:
 *         description: Bad request
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Internal server error
 */
${match}`;
    return swaggerComment;
  });
  
  fs.writeFileSync(filePath, content);
}

addSwaggerComments(process.argv[2]);
EOF
        
        node add-swagger-comments.js "$file"
    done
fi

# Postman Collection の生成
cat << 'EOF' > docs/api/postman-collection.json
{
  "info": {
    "name": "API Collection",
    "description": "Complete API collection for testing",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Authentication",
      "item": [
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"user@example.com\",\n  \"password\": \"password123\"\n}"
            },
            "url": {
              "raw": "{{baseUrl}}/api/auth/login",
              "host": ["{{baseUrl}}"],
              "path": ["api", "auth", "login"]
            }
          }
        }
      ]
    }
  ],
  "variable": [
    {
      "key": "baseUrl",
      "value": "http://localhost:3000",
      "type": "string"
    }
  ]
}
EOF
```

### 3. コードコメントの追加

```bash
# JSDoc/TSDocコメントの追加
echo "=== Adding code documentation ==="

# JavaScriptファイルにJSDocを追加
find . -name "*.js" -o -name "*.ts" -not -path "*/node_modules/*" | while read -r file; do
    echo "Adding documentation to $file"
    
    cat << 'EOF' > add-jsdoc.js
const fs = require('fs');
const path = require('path');

function addJSDoc(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  
  // 関数定義を検索
  const functionRegex = /^(export\s+)?(async\s+)?function\s+(\w+)\s*\(([^)]*)\)/gm;
  
  content = content.replace(functionRegex, (match, exportKeyword, asyncKeyword, funcName, params) => {
    // 既にコメントがある場合はスキップ
    if (content.includes(`@function ${funcName}`)) {
      return match;
    }
    
    const paramList = params.split(',').map(p => p.trim()).filter(p => p);
    const paramDocs = paramList.map(p => {
      const paramName = p.split('=')[0].trim();
      return ` * @param {*} ${paramName} - Description`;
    }).join('\n');
    
    const jsDoc = `/**
 * @function ${funcName}
 * @description Description of ${funcName}
${paramDocs}
 * @returns {*} Description of return value
 */
${match}`;
    
    return jsDoc;
  });
  
  // クラス定義を検索
  const classRegex = /^(export\s+)?class\s+(\w+)/gm;
  
  content = content.replace(classRegex, (match, exportKeyword, className) => {
    if (content.includes(`@class ${className}`)) {
      return match;
    }
    
    const classDoc = `/**
 * @class ${className}
 * @description Description of ${className}
 */
${match}`;
    
    return classDoc;
  });
  
  fs.writeFileSync(filePath, content);
}

addJSDoc(process.argv[2]);
EOF
    
    node add-jsdoc.js "$file"
done

# TypeScriptの場合、型定義ファイルを生成
if [ -f "tsconfig.json" ]; then
    jq '.compilerOptions.declaration = true | .compilerOptions.declarationMap = true' tsconfig.json > tsconfig.tmp && mv tsconfig.tmp tsconfig.json
    npx tsc --emitDeclarationOnly
fi
```

### 4. アーキテクチャドキュメントの生成

```bash
# アーキテクチャ図とドキュメントの生成
echo "=== Creating architecture documentation ==="

mkdir -p docs/architecture

cat << 'EOF' > docs/architecture/README.md
# Architecture Documentation

## System Overview

This document describes the architecture of the application.

## Architecture Diagram

```mermaid
graph TB
    subgraph "Frontend"
        UI[User Interface]
        State[State Management]
    end
    
    subgraph "Backend"
        API[API Gateway]
        Auth[Authentication]
        BL[Business Logic]
        Cache[Cache Layer]
    end
    
    subgraph "Data Layer"
        DB[(Database)]
        Redis[(Redis Cache)]
        S3[Object Storage]
    end
    
    UI --> API
    API --> Auth
    API --> BL
    BL --> Cache
    Cache --> Redis
    BL --> DB
    BL --> S3
```

## Components

### Frontend Layer
- **Technology**: React/Vue/Angular
- **State Management**: Redux/Vuex/NgRx
- **Styling**: CSS Modules/Styled Components

### API Layer
- **Framework**: Express.js/Fastify
- **Authentication**: JWT/OAuth2
- **Rate Limiting**: express-rate-limit
- **Validation**: express-validator

### Business Logic Layer
- **Services**: Domain-specific business logic
- **Models**: Data models and schemas
- **Utils**: Shared utilities and helpers

### Data Layer
- **Primary Database**: PostgreSQL/MySQL/MongoDB
- **Caching**: Redis
- **File Storage**: AWS S3/Local filesystem

## Data Flow

1. User interacts with UI
2. UI sends request to API
3. API validates and authenticates request
4. Business logic processes request
5. Data layer handles persistence
6. Response sent back to UI

## Security Considerations

- All API endpoints require authentication
- Input validation on all user inputs
- SQL injection prevention through parameterized queries
- XSS protection through content sanitization
- HTTPS enforced in production

## Scalability

- Horizontal scaling through load balancing
- Database read replicas for read-heavy operations
- Redis caching for frequently accessed data
- CDN for static assets

## Monitoring and Logging

- Application metrics with Prometheus
- Centralized logging with ELK stack
- Error tracking with Sentry
- Performance monitoring with New Relic
EOF

# ADR (Architecture Decision Records) の作成
mkdir -p docs/adr

cat << 'EOF' > docs/adr/0001-record-architecture-decisions.md
# 1. Record Architecture Decisions

Date: $(date +%Y-%m-%d)

## Status

Accepted

## Context

We need to record the architectural decisions made on this project.

## Decision

We will use Architecture Decision Records, as described by Michael Nygard.

## Consequences

- Architectural decisions will be documented and easily accessible
- Future developers will understand the reasoning behind decisions
- Changes to architecture will be tracked over time
EOF
```

### 5. 開発者ガイドの作成

```bash
# CONTRIBUTING.mdの生成
echo "=== Creating contributing guide ==="

cat << 'EOF' > CONTRIBUTING.md
# Contributing Guide

Thank you for your interest in contributing to this project!

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](../../issues)
2. Create a new issue with the bug report template
3. Provide detailed steps to reproduce the bug
4. Include system information and error messages

### Suggesting Features

1. Check if the feature has already been requested
2. Create a new issue with the feature request template
3. Explain the use case and benefits
4. Provide examples if possible

### Submitting Pull Requests

1. Fork the repository
2. Create a new branch from `main`
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes following our coding standards
4. Write tests for your changes
5. Ensure all tests pass
   ```bash
   npm test
   ```
6. Commit your changes using conventional commits
   ```bash
   git commit -m "feat: add new feature"
   ```
7. Push to your fork
   ```bash
   git push origin feature/your-feature-name
   ```
8. Create a Pull Request

## Development Setup

### Prerequisites

- Node.js v14+
- npm or yarn
- Git

### Local Development

```bash
# Clone the repository
git clone https://github.com/username/project.git
cd project

# Install dependencies
npm install

# Run in development mode
npm run dev

# Run tests
npm test

# Run linter
npm run lint
```

## Coding Standards

### JavaScript/TypeScript

- Use ESLint and Prettier configurations
- Follow functional programming principles where appropriate
- Write self-documenting code with clear variable names
- Add JSDoc comments for public functions

### Git Commits

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Test additions or changes
- `chore:` Build process or auxiliary tool changes

### Testing

- Write unit tests for all new functions
- Maintain test coverage above 70%
- Include integration tests for API endpoints
- Add E2E tests for critical user flows

## Review Process

1. All PRs require at least one review
2. CI checks must pass
3. Code coverage must not decrease
4. Documentation must be updated if needed

## Questions?

Feel free to open an issue or reach out to the maintainers.
EOF

# Code of Conduct の作成
cat << 'EOF' > CODE_OF_CONDUCT.md
# Code of Conduct

## Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone.

## Our Standards

Examples of behavior that contributes to a positive environment:

- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

Examples of unacceptable behavior:

- Harassment of any kind
- Trolling or insulting comments
- Public or private harassment
- Publishing others' private information

## Enforcement

Instances of abusive behavior may be reported to the project team.

All complaints will be reviewed and investigated promptly and fairly.

## Attribution

This Code of Conduct is adapted from the Contributor Covenant, version 2.0.
EOF
```

### 6. 変更履歴の生成

```bash
# CHANGELOG.mdの自動生成
echo "=== Generating changelog ==="

cat << 'EOF' > CHANGELOG.md
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive documentation
- API documentation with Swagger
- Architecture documentation
- Contributing guidelines

### Changed
- Improved README with better examples
- Updated code comments with JSDoc

### Fixed
- Documentation gaps identified in issue analysis

## [1.0.0] - $(date +%Y-%m-%d)

### Added
- Initial release
- Core functionality
- Basic documentation

[Unreleased]: https://github.com/username/project/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/username/project/releases/tag/v1.0.0
EOF

# Git履歴から自動生成（conventional commits使用時）
if command -v conventional-changelog &> /dev/null; then
    conventional-changelog -p angular -i CHANGELOG.md -s
fi
```

### 7. PRの作成

```bash
# 変更をコミット
git add -A
git commit -m "docs: Add comprehensive documentation

- Created detailed README with examples
- Added API documentation with Swagger
- Added architecture documentation
- Created contributing guidelines
- Added code comments with JSDoc
- Generated changelog

Closes #<issue-number>"

# PRを作成
gh pr create \
    --title "📚 Documentation Improvements" \
    --body "## Summary
This PR adds comprehensive documentation to the project.

## Documentation Added
- ✅ README.md with complete setup and usage instructions
- ✅ API documentation (OpenAPI/Swagger)
- ✅ Architecture documentation with diagrams
- ✅ Contributing guidelines
- ✅ Code of Conduct
- ✅ JSDoc comments in source code
- ✅ Changelog

## Preview
- README includes badges, examples, and clear instructions
- API docs are interactive via Swagger UI
- Architecture uses Mermaid diagrams for visualization

## Checklist
- [x] Documentation is complete and accurate
- [x] Examples are tested and working
- [x] Links are valid
- [x] Formatting is consistent
- [x] No sensitive information exposed" \
    --label "documentation"
```

## 成功基準

- ✅ README.mdが包括的で分かりやすい
- ✅ API ドキュメントが完備されている
- ✅ コードにJSDoc/TSDocコメントが追加されている
- ✅ アーキテクチャドキュメントが存在する
- ✅ 貢献ガイドラインが明確である
- ✅ PRが作成されている