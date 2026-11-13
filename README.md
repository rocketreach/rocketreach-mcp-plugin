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

Other MCP clients (such as Cursor) can register the server directly using the `mcp.json` / `.mcp.json` manifests in this repo.

## Authentication

The RocketReach MCP server (`https://mcp.rocketreach.co/mcp`) uses OAuth — no API keys are stored in this repo. After installing, run `/mcp`, select **RocketReach**, and complete sign-in in your browser.

Lookups that enrich a person or company consume RocketReach credits, as does verifying an email address; your client will ask you to confirm before running them.

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

These skills build on the RocketReach MCP tools above and are invoked as `/rocketreach:<skill-name>`.

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
├── assets/             # Brand assets (logomark)
├── scripts/            # install-hooks.sh (git hook setup), build-openai-zip.sh (ChatGPT package)
├── skills/             # Agent Skills, invoked as /rocketreach:<skill-name>
│   ├── enrich-person/SKILL.md
│   ├── enrich-company/SKILL.md
│   ├── build-list/SKILL.md
│   ├── prospect/SKILL.md
│   └── verify-email/SKILL.md
├── .mcp.json           # Direct HTTP server registration (Claude / Codex)
├── mcp.json            # mcp-remote bridge registration (Cursor)
└── LICENSE
```

## Publishing to ChatGPT

ChatGPT picks up tool changes from the MCP server on its own. Skills and listing text (the `interface` block in `.codex-plugin/plugin.json`) reach ChatGPT only through a package upload:

1. Bump `version` in `.codex-plugin/plugin.json`, or set `VERSION` when you build. OpenAI rejects a version that matches the published one.
2. Run `./scripts/build-openai-zip.sh`. It checks the manifest against OpenAI's listing limits and writes `dist/rocketreach-openai-<version>.zip`.
3. In platform.openai.com, open Plugins → RocketReach, select **Upload plugin to make changes**, and upload the ZIP.

## License

[MIT](LICENSE)
