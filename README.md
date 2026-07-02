# RocketReach MCP Plugin

Use [RocketReach](https://rocketreach.co) contact and company data from LLM clients that support the Model Context Protocol (MCP). Includes pre-built Agent Skills that teach AI assistants how to find, enrich, and prospect contacts and companies using RocketReach's data and tools.

## What it enables

- Search people by name, title, company, location, and other filters
- Search companies by name, domain, and firmographics
- Enrich a person into verified emails, phone numbers, and social profiles
- Enrich a company with size, industry, location, and other firmographics
- Check your account and remaining credits

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

Lookups that enrich a person or company consume RocketReach credits; your client will ask you to confirm before running them.

## Skills

Skills are pre-built workflows that teach AI assistants how to complete specific tasks using a product's data and tools. Each skill is a `SKILL.md` file with a `name`, a `description`, and a step-by-step workflow the assistant follows. For more, see Claude's [Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview).

These skills build on the RocketReach MCP tools (`person_search`, `person_lookup`, `company_search`, `company_lookup`, `account`, `check_person_status`) and are invoked as `/rocketreach:<skill-name>`.

| Skill | Description |
| --- | --- |
| [`enrich-person`](skills/enrich-person/SKILL.md) | Look up a person's profile by name, email, phone, LinkedIn URL, NPI number, or name + employer. Returns their profile and verified contact info (emails, phones). |
| [`enrich-company`](skills/enrich-company/SKILL.md) | Look up a company profile by name, domain, LinkedIn URL, or ticker symbol. Returns a complete company profile including domain, employee size, location, revenue, industry, and other firmographic details. |
| [`build-list`](skills/build-list/SKILL.md) | Build a list of people or companies by filtering on title, seniority, department, industry, company size, location, and more. Returns a structured table you can export. |
| [`prospect`](skills/prospect/SKILL.md) | Describe your ideal customer in plain English and get a ranked table of decision-makers with verified contact data. |

## Project Structure

```txt
├── .claude-plugin/     # Claude plugin + marketplace manifests
├── .codex-plugin/      # Codex plugin manifest
├── .cursor-plugin/     # Cursor plugin + marketplace manifests
├── .githooks/          # Local secret-scanning pre-commit hook
├── .github/            # Repo config (CODEOWNERS, metadata, PR template, renovate)
├── assets/             # Brand assets (logomark)
├── scripts/            # install-hooks.sh (git hook setup)
├── skills/             # Agent Skills, invoked as /rocketreach:<skill-name>
│   ├── enrich-person/SKILL.md
│   ├── enrich-company/SKILL.md
│   ├── build-list/SKILL.md
│   └── prospect/SKILL.md
├── .mcp.json           # Direct HTTP server registration (Claude / Codex)
├── mcp.json            # mcp-remote bridge registration (Cursor)
└── LICENSE
```

## License

[MIT](LICENSE)
