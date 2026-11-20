# Installing the RocketReach MCP server (instructions for AI agents)

RocketReach runs a hosted remote MCP server at `https://mcp.rocketreach.co/mcp`. This repo has no server code, so don't clone it, build it, install packages, or run anything locally.

1. Add a remote MCP server with these settings:
   - Name: `rocketreach`
   - URL: `https://mcp.rocketreach.co/mcp`
   - Transport: Streamable HTTP

   In Cline, add this entry to the `mcpServers` object in `cline_mcp_settings.json` and keep any servers already there:

   ```json
   {
     "mcpServers": {
       "rocketreach": {
         "type": "streamableHttp",
         "url": "https://mcp.rocketreach.co/mcp",
         "disabled": false,
         "autoApprove": []
       }
     }
   }
   ```

   Write `streamableHttp` exactly as shown, with a capital H. If `type` is missing, Cline falls back to the older SSE transport and the connection fails.

2. Don't ask the user for an API key, and don't add headers or environment variables. The server uses OAuth with dynamic client registration. When Cline shows **Authentication required** for the server, ask the user to click **Authenticate** in the MCP Servers panel, sign in to RocketReach in the browser window that opens, and approve access. They need a RocketReach account, and a free plan works.

3. Check the install by calling the `account` tool. It costs nothing and returns the signed-in user's plan and credit balances.

Notes:

- `person_lookup`, `bulk_person_lookup`, `company_lookup`, `profile_company_lookup`, and `email_verify` spend the user's RocketReach credits. Leave them out of `autoApprove` so Cline asks before each call. That only holds while Cline's **Use MCP servers** auto-approve setting is off. When it's on, Cline approves every MCP tool call, these included, so tell the user. Searches, `list_filter_values`, `check_person_status`, `account`, and `ping` are free.
- A person lookup can come back pending. Call `check_person_status` with the returned profile IDs to get the finished result.
- If **Authentication required** appears again later, the sign-in has expired. Click **Authenticate** again, or delete the server and add it back.
- The server only runs at `https://mcp.rocketreach.co/mcp`. Don't configure a localhost URL.
- Clients that load plugins (Claude Code, Cowork, Cursor, Gemini CLI) can install this repo as a plugin, which adds RocketReach's skills too. See the [README](README.md) for those commands.
