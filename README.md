# RocketReach MCP Plugin

Use [RocketReach](https://rocketreach.co) contact and company data from LLM clients that support the Model Context Protocol (MCP). Includes pre-built Agent Skills that teach AI assistants how to find, enrich, and prospect contacts and companies using RocketReach's data and tools.

## What it enables

- Search people by name, title, company, location, and other filters
- Search companies by name, domain, and firmographics
- Enrich a person into verified emails, phone numbers, and social profiles, or up to 100 people in one batch
- Enrich a company with size, industry, location, and other firmographics
- Verify whether an email address is deliverable before you send to it
- Check your account and remaining credits
- Look up the exact filter values a search accepts, so a guessed value doesn't quietly narrow or empty a search
- Report results that look wrong, or send feedback, to the RocketReach team

## Installation

### Cowork

[Install in Cowork](https://claude.ai/desktop/customize/plugins/new?marketplace=rocketreach/rocketreach-mcp-plugin&plugin=rocketreach), then restart Cowork.

### Claude Code

```
/plugin marketplace add rocketreach/rocketreach-mcp-plugin
/plugin install rocketreach@rocketreach-plugin-marketplace
```

Restart Claude Code so the MCP server starts.

### Cursor

RocketReach is in review for the [Cursor Marketplace](https://cursor.com/marketplace). Once it's listed, open **Cursor Settings → Plugins**, search for **RocketReach**, and click **Install**, then complete the RocketReach sign-in prompt. You can also run `/add-plugin rocketreach` in chat.

Until then, or to try a local copy, clone this repo into Cursor's local plugin folder and reload the window (Command Palette → **Developer: Reload Window**):

```
git clone https://github.com/rocketreach/rocketreach-mcp-plugin ~/.cursor/plugins/local/rocketreach
```

### Gemini CLI

```
gemini extensions install https://github.com/rocketreach/rocketreach-mcp-plugin
```

Then start `gemini`, run `/mcp auth rocketreach`, and finish signing in to RocketReach in your browser. Sign-in redirects to localhost, so run it on a machine with a browser, not over SSH. The extension installs the skills below too.

### Cline

In VS Code, open Cline, click the **MCP Servers** icon, and open the **Remote Servers** tab. Add a server named `rocketreach` with the URL `https://mcp.rocketreach.co/mcp` and the **Streamable HTTP** transport. To edit the JSON instead, open **Configure MCP Servers** on the Configure tab and add this to `cline_mcp_settings.json`:

```json
{
  "mcpServers": {
    "rocketreach": {
      "type": "streamableHttp",
      "url": "https://mcp.rocketreach.co/mcp"
    }
  }
}
```

Write `streamableHttp` with a capital H. Without `type`, Cline falls back to the older SSE transport and can't connect. When Cline shows **Authentication required**, click **Authenticate** and sign in to RocketReach in your browser. If you'd rather have Cline set it up, point it at [llms-install.md](llms-install.md).

### Kiro

[![Add to Kiro](https://kiro.dev/images/add-to-kiro.svg)](https://kiro.dev/launch/mcp/add?name=rocketreach&config=%7B%22url%22%3A%22https%3A%2F%2Fmcp.rocketreach.co%2Fmcp%22%7D)

Click **Add to Kiro** to add the RocketReach server to the Kiro IDE. To add it by hand, put this in `~/.kiro/settings/mcp.json` for every workspace, or in `.kiro/settings/mcp.json` for one workspace:

```json
{
  "mcpServers": {
    "rocketreach": {
      "url": "https://mcp.rocketreach.co/mcp"
    }
  }
}
```

If the RocketReach sign-in page doesn't open by itself, open the Command Palette, run **Focus on MCP Servers view**, and click **Authenticate** next to RocketReach.

### Other MCP clients

Any MCP client can connect to `https://mcp.rocketreach.co/mcp` if it supports Streamable HTTP and OAuth sign-in with dynamic client registration.

## Authentication

The RocketReach MCP server (`https://mcp.rocketreach.co/mcp`) uses OAuth, so no API keys are stored in this repo. In Claude Code, run `/mcp` after installing, select **RocketReach**, and complete sign-in in your browser.

Lookups that enrich a person or company consume RocketReach credits, as does verifying an email address. Claude and ChatGPT ask you to confirm before running them. Gemini CLI asks too, unless you started it with `--yolo` or chose an always-allow option for the tool or server. Cline asks before each MCP tool call unless you auto-approve that tool or turn on the **Use MCP servers** auto-approve setting, which approves every MCP tool. Cursor can run them without asking, depending on your auto-run settings.

## Tools

| Tool | What it does | Credits |
| --- | --- | --- |
| `person_search` | Search people by title, employer, seniority, department, skills, education, location, healthcare fields, and buyer signals. Returns profile previews without contact info. | None |
| `company_search` | Search companies by name, domain, industry, size, revenue, funding, location, tech stack, and buyer signals. | None |
| `list_filter_values` | List the exact values a faceted search field accepts (industry, department, management level, country, state, location, and the signal fields). A guessed value can quietly return fewer results or none. | None |
| `person_lookup` | Get a person's verified emails, phone numbers, and profile by profile ID, email, LinkedIn URL, NPI number, or name plus employer. Adds them to My Contacts. | 1 lookup credit, plus 1 `person_export` credit if your plan has them |
| `bulk_person_lookup` | Look up as many as 100 people in one call, using the same identifiers as `person_lookup`. Adds them to My Contacts. | Each person is charged like a `person_lookup` |
| `check_person_status` | Check on person lookups that came back pending, including every profile in a bulk batch. | None |
| `company_lookup` | Get full company details, including description, industry, size, revenue, tech stack, and social links. Adds the company to My Companies. | 1 `company_export` credit |
| `profile_company_lookup` | Look up a person and their current company in one call. | 1 lookup credit and 1 `company_export` credit, plus 1 `person_export` credit if your plan has them |
| `email_verify` | Check whether an email address is deliverable: valid, invalid, catchall, or unknown. | 1 `email_verification` credit, refunded when the result is unknown or the address is malformed |
| `account` | Show your plan, credit balances, and API limits. | None |
| `report_issue` | Report a tool result that looks wrong (empty, incorrect, or stale) to the RocketReach team so it can be fixed. | None |
| `send_feedback` | Send your feedback to the RocketReach team. Only used when you ask. | None |
| `ping` | Check that the server is reachable. | None |

## Skills

Skills are pre-built workflows that teach AI assistants how to complete specific tasks using a product's data and tools. Each skill is a `SKILL.md` file with a `name`, a `description`, and a step-by-step workflow the assistant follows. For more, see Claude's [Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview).

These skills build on the RocketReach MCP tools above and are invoked as `/rocketreach:<skill-name>`. In Gemini CLI, Gemini picks a skill when your request matches the skill's description.

| Skill | Description |
| --- | --- |
| [`enrich-person`](skills/enrich-person/SKILL.md) | Look up a person's profile by name, email, phone, LinkedIn URL, NPI number, or name + employer. Returns their profile and verified contact info (emails, phones). |
| [`enrich-company`](skills/enrich-company/SKILL.md) | Look up a company profile by name, domain, LinkedIn URL, or ticker symbol. Returns a complete company profile including domain, employee size, location, revenue, industry, and other firmographic details. |
| [`build-list`](skills/build-list/SKILL.md) | Build a list of people or companies by filtering on title, seniority, department, industry, company size, location, and more. Returns a structured table you can export. |
| [`prospect`](skills/prospect/SKILL.md) | Describe your ideal customer in plain English and get a ranked table of decision-makers with verified contact data. |
| [`verify-email`](skills/verify-email/SKILL.md) | Check whether an email address you already have is deliverable. Confirms format, checks the domain accepts mail, and probes the mailbox on the receiving mail server. Returns valid, invalid, catchall, or unknown. |

## Project Structure

```txt
├── .claude-plugin/     # Claude plugin + marketplace manifests
├── .codex-plugin/      # Codex and ChatGPT plugin manifest
├── .cursor-plugin/     # Cursor plugin + marketplace manifests
├── .githooks/          # Local secret-scanning pre-commit hook
├── .github/            # Repo config (CODEOWNERS, metadata, PR template, renovate)
├── assets/             # Brand assets (logomark, 400×400 PNG logo for directory listings)
├── scripts/            # install-hooks.sh (git hook setup), build-openai-zip.sh (ChatGPT package)
├── skills/             # Agent Skills, invoked as /rocketreach:<skill-name>
│   ├── enrich-person/SKILL.md
│   ├── enrich-company/SKILL.md
│   ├── build-list/SKILL.md
│   ├── prospect/SKILL.md
│   └── verify-email/SKILL.md
├── .mcp.json           # Direct HTTP server registration (Claude / Codex)
├── mcp.json            # Direct HTTP server registration (Cursor)
├── gemini-extension.json  # Gemini CLI extension manifest and server registration
├── llms-install.md     # Setup steps for AI agents (Cline Marketplace installs)
└── LICENSE
```

## Publishing to Gemini CLI

The [Gemini CLI extensions gallery](https://geminicli.com/extensions/) finds this repo through its `gemini-cli-extension` GitHub topic and crawls it daily. Gemini CLI checks the repo's latest GitHub release for updates. To ship a change:

1. Bump `version` in `gemini-extension.json`.
2. Merge to `main`, then publish a GitHub release tagged `v<version>`. Google's docs ask that the tag match the manifest version.

## Publishing to ChatGPT

ChatGPT picks up tool changes from the MCP server on its own. Skills and listing text (the `interface` block in `.codex-plugin/plugin.json`) reach ChatGPT only through a package upload:

1. Bump `version` in `.codex-plugin/plugin.json`, or set `VERSION` when you build. OpenAI rejects a version that matches the published one.
2. Run `./scripts/build-openai-zip.sh`. It checks the manifest against OpenAI's listing limits and writes `dist/rocketreach-openai-<version>.zip`.
3. In platform.openai.com, open Plugins → RocketReach, select **Upload plugin to make changes**, and upload the ZIP.

## License

[MIT](LICENSE)
