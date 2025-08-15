# n8n MCP Setup

Configure n8n MCP integration for workflow automation.

## Instructions

1. **Get n8n API Configuration**:
   - First, I'll ask you for your n8n instance URL (default: http://localhost:5678)
   - Then I'll ask for your n8n API key
   - You can find your API key in n8n: Settings → n8n API → Create New API Key

2. **Install and Configure MCP**:
   - I'll run the MCP add command with your provided credentials
   - The configuration will be saved securely

3. **Update CLAUDE.md**:
   - I'll add the n8n workflow automation prompt to your CLAUDE.md file
   - This will enable n8n-specific capabilities in Claude

## Process

```bash
# Step 1: Get user inputs
read -p "Enter your n8n API URL (default: http://localhost:5678): " N8N_URL
read -sp "Enter your n8n API key: " N8N_KEY

# Step 2: Add MCP with configuration
claude mcp add n8n-mcp -- npx n8n-mcp \
  -e MCP_MODE=stdio \
  -e LOG_LEVEL=error \
  -e DISABLE_CONSOLE_OUTPUT=true \
  -e N8N_API_URL="${N8N_URL:-http://localhost:5678}" \
  -e N8N_API_KEY="$N8N_KEY"

# Step 3: Update CLAUDE.md with n8n workflow prompt
```

## Security Notes

- API keys are never stored in plaintext
- Credentials are passed securely via environment variables
- Always use HTTPS for production n8n instances
