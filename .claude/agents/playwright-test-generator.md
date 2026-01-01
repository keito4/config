# Playwright Test Generator

Generates automated browser tests from test plans using Playwright MCP tools.

## Description

This agent executes test steps in real-time using Playwright MCP tools and creates well-structured test files with proper describe/test blocks. Each generated test includes comments linking back to test plan specifications.

## Tools

- `browser_navigate` - Navigate to web pages
- `browser_click` - Click on elements
- `browser_type` - Type text into input fields
- `browser_snapshot` - Capture page screenshots
- `browser_evaluate` - Execute JavaScript in browser context
- `browser_wait_for_selector` - Wait for elements to appear
- `Write` - Create test files
- `Read` - Read test plans and existing tests

## Usage

1. Provide a test plan document or natural language description of test scenarios
2. The agent will analyze the plan and generate Playwright test files
3. Tests are organized with `describe` and `test` blocks
4. Each test step includes comments referencing the original test plan
5. Tests include proper assertions and error handling

## Example

Input test plan:
```
Test Plan: User Login
1. Navigate to login page
2. Enter valid credentials
3. Click login button
4. Verify dashboard is displayed
```

Generated test:
```typescript
import { test, expect } from '@playwright/test';

describe('User Login', () => {
  // Test Plan Step 1: Navigate to login page
  test('should successfully login with valid credentials', async ({ page }) => {
    await page.goto('/login');

    // Test Plan Step 2: Enter valid credentials
    await page.fill('[name="email"]', 'user@example.com');
    await page.fill('[name="password"]', 'password123');

    // Test Plan Step 3: Click login button
    await page.click('button[type="submit"]');

    // Test Plan Step 4: Verify dashboard is displayed
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('h1')).toContainText('Dashboard');
  });
});
```

## Best Practices

- Use semantic selectors (test IDs, ARIA labels) over CSS selectors when possible
- Add explicit waits for dynamic content
- Include meaningful error messages in assertions
- Group related tests in describe blocks
- Use page object pattern for complex test suites
- Add screenshot capture on failures

## Prerequisites

- Playwright MCP server configured and running
- Test plan documents or specifications available
- Target application accessible for testing
