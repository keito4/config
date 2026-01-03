# ESLint Complexity Rules

This directory contains recommended ESLint complexity rules to prevent technical debt accumulation.

## Overview

Code complexity rules help maintain code quality by enforcing limits on:

- Cyclomatic complexity
- Function length
- File length
- Nesting depth
- Function parameters

## Files

- `complexity-rules.mjs`: Exportable complexity rules configuration

## Usage

### Import in ESLint Config (Flat Config)

```javascript
import { complexityRules } from './eslint/complexity-rules.mjs';

export default [
  {
    files: ['**/*.{js,jsx,ts,tsx}'],
    rules: {
      ...complexityRules,
      // Your other rules
    },
  },
];
```

### Copy Rules Directly

Copy the rules object from `complexity-rules.mjs` into your existing ESLint configuration.

## Rules Reference

| Rule                     | Limit | Purpose                     |
| ------------------------ | ----- | --------------------------- |
| `complexity`             | 15    | Cyclomatic complexity limit |
| `max-lines-per-function` | 100   | Function length limit       |
| `max-lines`              | 500   | File length limit           |
| `max-depth`              | 4     | Nesting depth limit         |
| `max-params`             | 5     | Function parameter limit    |

## Implementation Strategy

### Phase 1: Warning Mode (Current)

Set all rules to `"warn"` to detect issues without breaking builds:

```javascript
"complexity": ["warn", { "max": 15 }]
```

This allows you to:

- Identify existing violations
- Prevent new technical debt
- Gradually refactor problematic code

### Phase 2: Error Mode (Future)

Once the codebase is compliant, upgrade to `"error"`:

```javascript
"complexity": ["error", { "max": 15 }]
```

This will:

- Block CI/CD pipeline on violations
- Enforce strict compliance
- Maintain code quality standards

## Test File Exceptions

Consider relaxing rules for test files:

```javascript
{
  files: ['**/*.test.js', '**/*.spec.js', '**/test/**/*.js'],
  rules: {
    'max-lines-per-function': 'off',
    'complexity': 'off',
  },
}
```

## Customization

Adjust limits based on your project needs:

```javascript
export const complexityRules = {
  complexity: ['warn', { max: 10 }], // Stricter
  'max-lines-per-function': [
    'warn',
    {
      max: 150, // More lenient
      skipBlankLines: true,
      skipComments: true,
    },
  ],
};
```

## CI Integration

Add ESLint complexity checks to your CI pipeline:

```yaml
- name: Run ESLint
  run: npm run lint
```

## Source

These rules were discovered from `Elu-co-jp/management_tools` repository and recommended for organization-wide adoption.

## Related Files

- `/eslint.config.mjs`: Main ESLint configuration for this repository
- `.github/workflows/templates/unified-ci.yml`: CI workflow template with linting

## Benefits

- **Prevents technical debt**: Catches complex code early
- **Improves readability**: Enforces consistent code structure
- **Maintains quality**: Automated enforcement in CI/CD
- **Gradual adoption**: Warn-first approach allows incremental improvements
