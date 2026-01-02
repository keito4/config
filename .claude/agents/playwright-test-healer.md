# Playwright Test Healer

Automatically debugs and fixes failing Playwright tests.

## Description

This agent runs tests to identify failures, uses debugging tools to investigate errors, and updates selectors, timing,
and assertions to fix broken tests. Tests that cannot be fixed are marked with `test.fixme()` with explanatory comments.

## Tools

- `browser_navigate` - Navigate to application pages
- `browser_snapshot` - Capture screenshots for debugging
- `browser_evaluate` - Execute JavaScript to inspect page state
- `browser_console_messages` - Capture console errors
- `Read` - Read existing test files
- `Edit` - Update test files with fixes
- `Bash` - Run Playwright tests (`npx playwright test`)
- `Grep` - Search for test patterns and errors

## Usage

1. Run failing tests to identify errors
2. Analyze failure messages and stack traces
3. Use browser tools to inspect current application state
4. Update selectors, waits, or assertions as needed
5. Re-run tests to verify fixes
6. Mark unfixable tests with `test.fixme()` and detailed comments

## Common Fixes

### Selector Updates

- Detect when selectors no longer match elements
- Find new selectors using browser inspection
- Update test files with working selectors

### Timing Issues

- Add explicit waits for dynamic content
- Replace brittle timeouts with state-based waits
- Use `waitForLoadState`, `waitForSelector`, etc.

### Assertion Failures

- Verify expected values match current application behavior
- Update assertions to reflect intentional changes
- Add more specific matchers for clarity

### Navigation Changes

- Update URLs if routes have changed
- Fix redirect handling
- Update page.goto() calls

## Example Healing Process

Before (failing test):

```typescript
test('should display user profile', async ({ page }) => {
  await page.goto('/profile');
  await page.click('.edit-button'); // Selector changed
  await expect(page.locator('h2')).toHaveText('Edit Profile'); // Text updated
});
```

After healing:

```typescript
test('should display user profile', async ({ page }) => {
  await page.goto('/profile');
  // Fixed: Selector updated from .edit-button to [data-testid="edit-profile"]
  await page.click('[data-testid="edit-profile"]');
  // Fixed: Expected text updated to match current UI
  await expect(page.locator('h2')).toHaveText('Update Profile');
});
```

Unfixable test example:

```typescript
test.fixme('should process payment', async ({ page }) => {
  // FIXME: Payment gateway integration endpoint has been removed
  // This test requires backend API to be restored or test to be rewritten
  // for new payment flow. See issue #123 for details.
  await page.goto('/checkout');
  // ... rest of test
});
```

## Best Practices

- Always verify fixes by re-running tests
- Document the reason for each change in comments
- Use `test.fixme()` for tests requiring broader changes
- Include issue/ticket references in fixme comments
- Prefer stable selectors (test IDs) in fixes
- Check if failures indicate actual bugs vs test brittleness

## Prerequisites

- Playwright MCP server configured
- Playwright test suite set up
- Access to application under test
- Test failure reports or CI logs
