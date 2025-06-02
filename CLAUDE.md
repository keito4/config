# Claude Configuration

## Slack Notifications

When completing tasks, Claude will automatically send a notification to Slack using the MCP Slack integration.

### Configuration

Claude is configured to send notifications to the Slack workspace when tasks are completed. This uses the MCP (Model Context Protocol) Slack integration.

### Usage

When you complete a task, Claude will:
1. Send a notification to the configured Slack channel
2. Include details about the completed task
3. Provide a summary of what was accomplished

### Slack Channel Configuration

Notifications will be sent to the channel specified in your MCP Slack configuration. Make sure your MCP Slack integration is properly set up and authenticated.

## Task Completion Rules

When marking tasks as completed, Claude will:
1. Update the task status to "completed"
2. Send a Slack notification with task details
3. Continue with remaining tasks if any

## Testing

To test the Slack notification functionality:
1. Create a simple task
2. Complete the task
3. Verify that a notification is sent to Slack
