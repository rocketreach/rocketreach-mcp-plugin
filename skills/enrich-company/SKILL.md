---
name: enrich-company
description: Look up a company profile by name, domain, LinkedIn URL, or ticker symbol, Returns a complete company profile that includes domain, employee size, location, revenue, industry, and other firmographic details.
---

# Enrich Company

Take an identifier for a single company and return its full RocketReach profile.

## Input

The user will provide at least one of these to identify the company:

- Domain (preferred - most reliable match)
- RocketReach company ID
- Stock ticker symbol
- LinkedIn URL
- Company name

Examples:

- `/rocketreach:enrich-company rocketreach.co`
- `/rocketreach:enrich-company RocketReach`
- `/rocketreach:enrich-company www.linkedin.com/company/rocketreach.co`
- `/rocketreach:enrich-company NYSE:CRM`

## Workflow

1. **Confirm Company Export access.** Company lookups require Company Export credits, separate from person credits. If the user's company_export availability hasn't been surfaced in this conversation, call account. If allocated: 0 for company_export:
   - Stop the enrichment flow.
   - Surface: "Your plan doesn't include company_export credits, so company_lookup isn't available. You can search for companies without credit consumption — try /rocketreach:build-list companies [criteria], or contact your account team to enable company exports."
   - Do not call company_lookup
2. **Parse the identifier.** Prefer domain when available, since names can be ambiguous (several companies can share a name). If the user gives only a name and the match is unclear, confirm which company they mean before pulling data. Priority order - RocketReach company ID → domain → ticker → LinkedIn URL → name.
3. **Disambiguate (only if needed).** If the user only enters a company name and nothing else, call company_search with name: [input] and page_size: 5.
   - Single match → mark auto-resolved, proceed.
   - Multiple plausible candidates → present top 3 with name, domain, industry, employee count, HQ. Ask the user to pick. Mark ambiguous.
   - Zero results → mark failed, ask the user for a more specific identifier (like domain).
4. **Call company_lookup** with the resolved identifier.
5. **Display credit cost.** Tell the user whether a Company Export credit was charged. A credit is used when company information is returned; if no match was found, no credit is used.
6. **Format the company profile.** Use the output template below.

## Output

Lead with a header line, then present the returned fields below. Not every field is populated for every company - show what is present.

`[name] ([domain]) - [industry] · [num_employees] employees · [HQ location]`

| Field | Value |
| --- | --- |
| Name | [name] |
| Domain | [domain] |
| Employees | [num_employees] |
| Revenue | [revenue] |
| Industry | [industry] |
| Location | [city], [region], [country] |
| Founded | [year_founded] |
| LinkedIn | [links: linkedin] |
| Tech stack | [techstack] |
| Competitors | [competitors] |
| Departments | [departments] |
| Funding investors | [funding_investors] |
| RocketReach ID | [id] |

Lead with what the user is most likely to care about (size, revenue, industry, location). Tech stack, competitors, departments, and funding are the differentiating fields - surface them when present. SIC/NAICS codes, ticker, full address, and description are also available if the user asks. If fields are unavailable, omit the row.

## Next Steps

- `/rocketreach:build-list` - find people at the company by role.
- `/rocketreach:prospect` - build a prospect list scoped to this company.
- `/rocketreach:enrich-person` - look up a specific named person at the company.

## Notes

- company_export access is gated so some plans may not have access. Make sure to check as part of the initial workflow step above.
- **Disambiguation prefers domain.** When the user provides only a company name, the search step ranks candidates by domain-match strength against the name.
- **Host-level prompts.** The company_lookup tool is marked destructiveHint: true, so the AI client will prompt the user for permission before the lookup call.
