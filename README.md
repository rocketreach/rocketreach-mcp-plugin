# RocketReach MCP Plugin

Use [RocketReach](https://rocketreach.co) contact and company data from LLM clients that support the Model Context Protocol (MCP).

## What it enables

- Search people by name, title, company, location, and other filters
- Search companies by name, domain, and firmographics
- Enrich a person into verified emails, phone numbers, and social profiles
- Enrich a company with size, industry, location, and other firmographics
- Check your account and remaining credits

## Installation

### Cowork

[Install in Cowork](TODO: confirm final Cowork install URL), then restart Cowork.

### Claude Code

```
/plugin marketplace add rocketreach/rocketreach-mcp-plugin
/plugin install rocketreach@rocketreach-plugin-marketplace
```

Restart Claude Code so the MCP server starts.

Other MCP clients (such as Cursor) can register the server directly using the `mcp.json` / `.mcp.json` manifests in this repo.

## Authentication

The RocketReach MCP server (`https://mcp.rocketreach.co/mcp`) uses OAuth — no API keys are stored in this repo. After installing, run `/mcp`, select **RocketReach**, and complete sign-in in your browser.

Lookups that enrich a person or company consume RocketReach credits; your client will ask you to confirm before running them.

## License

[MIT](LICENSE)
