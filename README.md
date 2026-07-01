# RocketReach MCP Plugin

Agent Skills for the [RocketReach MCP server](https://github.com/rocketreach) — pre-built workflows that teach AI assistants how to find, enrich, and prospect contacts and companies using RocketReach's data and tools.

## What are Skills?

Skills are pre-built workflows that teach AI assistants how to complete specific tasks using a product's data and tools. Each skill is a `SKILL.md` file with a `name`, a `description`, and a step-by-step workflow the assistant follows. For more, see Claude's [Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview).

These skills build on the RocketReach MCP tools (`person_search`, `person_lookup`, `company_search`, `company_lookup`, `account`, `check_person_status`) and are invoked as `/rocketreach:<skill-name>`.

## Skills

| Skill | Description |
| --- | --- |
| [`enrich-person`](skills/enrich-person/SKILL.md) | Look up a person's profile by name, email, phone, LinkedIn URL, NPI number, or name + employer. Returns their profile and verified contact info (emails, phones). |
| [`enrich-company`](skills/enrich-company/SKILL.md) | Look up a company profile by name, domain, LinkedIn URL, or ticker symbol. Returns a complete company profile including domain, employee size, location, revenue, industry, and other firmographic details. |
| [`build-list`](skills/build-list/SKILL.md) | Build a list of people or companies by filtering on title, seniority, department, industry, company size, location, and more. Returns a structured table you can export. |
| [`prospect`](skills/prospect/SKILL.md) | Describe your ideal customer in plain English and get a ranked table of decision-makers with verified contact data. |

## Project Structure

```txt
├── skills/
│   ├── enrich-person/SKILL.md
│   ├── enrich-company/SKILL.md
│   ├── build-list/SKILL.md
│   └── prospect/SKILL.md
└── .github/
    ├── workflows/              # CI/CD pipelines
    └── actions/                # Reusable composite actions
```
