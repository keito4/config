# Claude Configuration

## Slack Notifications

When completing tasks, Claude will automatically send a notification to Slack using the MCP Slack integration.

### Configuration

Claude is configured to send notifications to the Slack workspace when tasks are completed. This uses the MCP (Model Context Protocol) Slack integration.

### Usage

## Task Completion Rules

When marking tasks as completed, Claude will:
1. Update the task status to "completed"
2. Execute `.devcontainer/bell.sh` to play a notification sound
3. Send a Slack notification with task details (if configured)
4. Continue with remaining tasks if any

### Task Completion Notification

When a task is marked as completed, Claude will execute the bell notification script:
```bash
bash .devcontainer/bell.sh
```

This script will:
- Display a completion message
- Play a terminal bell sound (if supported by your terminal)

Note: The bell sound will only work if your terminal supports bell characters. Task completion is indicated through:
- Task status updates in the todo list
- Bell notification script execution
- Slack notifications (if configured)
- Console output messages

## Testing

To test the Slack notification functionality:
1. Create a simple task
2. Complete the task
3. Verify that a notification is sent to Slack
4. Verify that the completion sound is played
