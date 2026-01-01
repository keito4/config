# Playwright Test Planner

Creates comprehensive test plans from web application exploration.

## Description

This agent navigates and explores web interfaces, designs test scenarios covering happy paths, edge cases, and error conditions, then outputs structured markdown test plans that can be used by the test generator agent.

## Tools

- `browser_navigate` - Navigate through application pages
- `browser_click` - Interact with UI elements
- `browser_type` - Fill forms to explore workflows
- `browser_snapshot` - Capture screenshots for documentation
- `browser_evaluate` - Inspect page structure and state
- `Write` - Create test plan documents
- `Read` - Review existing documentation

## Usage

1. Provide starting URL and exploration goals
2. Agent navigates through the application, exploring features
3. Identifies user workflows, forms, and interactions
4. Documents test scenarios with clear steps
5. Outputs structured markdown test plan

## Test Plan Structure

```markdown
# Test Plan: [Feature Name]

## Overview

Brief description of the feature and testing objectives

## Test Scenarios

### Happy Path: [Scenario Name]

**Objective**: What this test validates
**Preconditions**: Required state before test
**Steps**:

1. Navigate to [URL]
2. Click [element description]
3. Enter [data] into [field]
4. Click [submit button]

**Expected Results**:

- [Assertion 1]
- [Assertion 2]

### Edge Case: [Scenario Name]

**Objective**: Validate handling of [edge condition]
**Steps**:
[...]

### Error Handling: [Scenario Name]

**Objective**: Verify error messages for [invalid input]
**Steps**:
[...]

## Test Data

- Valid user: email@example.com / password123
- Invalid inputs: [list of edge cases]

## Notes

- [Any special considerations]
- [Known limitations]
```

## Exploration Strategy

### 1. Feature Discovery

- Navigate through main navigation
- Identify all interactive elements
- Map user workflows and journeys

### 2. Scenario Identification

- **Happy Paths**: Standard user workflows
- **Edge Cases**: Boundary conditions, unusual inputs
- **Error Conditions**: Invalid data, failed operations
- **Accessibility**: Keyboard navigation, screen readers

### 3. Test Prioritization

- Critical user journeys (P0)
- Core functionality (P1)
- Edge cases and errors (P2)
- Nice-to-have validations (P3)

## Example Output

```markdown
# Test Plan: User Registration

## Overview

Validate user registration flow including form validation, email verification, and account creation.

## Test Scenarios

### Happy Path: Successful Registration

**Objective**: Verify users can create accounts with valid information
**Preconditions**: User is not logged in
**Steps**:

1. Navigate to /register
2. Enter valid email in email field
3. Enter strong password in password field
4. Enter matching password in confirm password field
5. Click "Create Account" button

**Expected Results**:

- Redirect to /verify-email page
- Success message displayed
- Verification email sent to provided address

### Edge Case: Password Strength Validation

**Objective**: Verify password requirements are enforced
**Steps**:

1. Navigate to /register
2. Enter email
3. Enter weak password (e.g., "123")
4. Attempt to submit

**Expected Results**:

- Form submission blocked
- Error message: "Password must be at least 8 characters"
- Password field highlighted in red

### Error Handling: Duplicate Email

**Objective**: Verify handling of already-registered emails
**Steps**:

1. Navigate to /register
2. Enter existing user email
3. Fill other fields with valid data
4. Submit form

**Expected Results**:

- Form submission blocked
- Error message: "Email already registered"
- Link to login page displayed

## Test Data

- Valid email: newuser@example.com
- Existing email: existing@example.com
- Valid password: SecureP@ssw0rd
- Weak passwords: "123", "pass", "12345678"

## Notes

- Email verification flow requires access to test email service
- Consider rate limiting for registration attempts
```

## Best Practices

- Explore all major user workflows
- Cover authentication, CRUD operations, and business logic
- Include both positive and negative test cases
- Document test data requirements
- Note any setup/teardown needs
- Identify areas requiring mocking or test data
- Consider mobile vs desktop differences
- Document accessibility requirements

## Prerequisites

- Playwright MCP server configured
- Target application accessible
- Understanding of application features (or ability to explore)
- Access to application documentation (optional but helpful)
