---
name: build-list
description: Build a list of people or companies by filtering on title, seniority, department, industry, company size, location, and more. Returns a structured table you can export
---

# Build List

Build a targeted list of people (or companies) from RocketReach and return it as a structured table.

## Input

The user describes who (or what) they want in natural language.

- Natural-language description of who or what to find.
- Type - auto-detected (people vs companies); ask once if ambiguous.
- Result count - optional (default 25, max 100).

Examples:

- `/rocketreach:build-list Product managers at Tech companies in Boston, 51-200 employees`
- `/rocketreach:build-list VPs of Sales at healthcare companies in the US`
- `/rocketreach:build-list Directors of Engineering at companies using Salesforce`
- `/rocketreach:build-list cardiologists in Boston`
- `/rocketreach:build-list companies in Maine, 200-1000 employees (company list)`

## Workflow

1. **Decide people or companies.** Determine whether the user wants people or companies from cues:
   - "VPs", "managers", "leaders", "decision-makers", "people who…" → people.
   - "Companies using…", "firms with…", "startups that…", "businesses in…" → companies.
   - Ambiguous ("show me everyone in X") → ask once.
2. **Parse the request into search filters.** Each filter is an array in the query object:

   For people (person_search):
   - Titles → current_title
   - Seniority → management_levels
   - Department → department
   - Skills → skills
   - Education → school / degree
   - Location → location
   - Current employer industry → company_industry
   - Current employer size → company_size
   - Healthcare → health_npi, health_specialization, health_license, health_credentials
   - Free-text → keyword

   For companies (company_search):
   - Identity → name, domain
   - Classification → industry, sic_code, naics_code
   - Size → employees, revenue
   - Location → location
   - Tech stack → techstack
   - Competitors (domains) → competitors
   - Other signals → keyword, company_tag

   Use exclude for any "but not X" patterns.
3. **Run the search.** Call person_search OR company_search with parsed filters. Defaults:
   - page_size: 25 (configurable up to 100).
   - order_by: relevance.

   No credits consumed.
4. **Show the list first, then offer to enrich it if it is a person list.** Present the results as a table using the templates below. Do NOT auto-run lookups on everyone - that spends credits. Ask the user which people (or how many) they want verified contact info for, then run person_lookup on just those, confirming credit type if multiple are active.

## Output - Person List

### Filters applied

Show exactly what was searched on so the user can verify:

| Filter | Value |
| --- | --- |
| current_title | Product Manager |
| company_size | 51-200 |
| location | Boston |

### Results (people)

| # | Name | Title | Company | Location |
| --- | --- | --- | --- | --- |
| 1 | | | | |
| 2 | | | | |

Person Search returns preview fields only (name, current_title, current_employer, location, and the RocketReach profile ID). LinkedIn URL is not part of the search preview — it comes back from person_lookup at enrichment.

## Output - Company List

### Filters applied

Show exactly what was searched on so the user can verify:

| Filter | Value |
| --- | --- |
| employees | 51-200 |
| location | California |

### Results (Company)

| # | Name | Domain | Industry | Size |
| --- | --- | --- | --- | --- |
| 1 | | | | |
| 2 | | | | |

Company Search returns preview fields only (name, domain, industry_str, employee_count, and the RocketReach company ID).

## Next step

- Person list: Enrich the top N → enrich-person on selected people (confirm count + credit type).
- Company list: Find people there → prospect or build-list (people) on selected domains.

## Notes

- Keep the search step and the lookup step clearly separate so the user controls credit spend.
- **No credits consumed.** This is the safe entry point for exploration. The list is a preview; enrichment happens elsewhere.
- **Result truncation.** When Total matching is high (>1000), the top 25 are not a random sample — they're sorted by relevance. Refinement suggestions help users narrow toward the subset they actually want.
- **Filter values must resolve.** Industry names, tech-stack names, etc. follow RocketReach's taxonomy. If a user requests a filter that doesn't resolve (e.g., a niche industry name), surface that and suggest the closest matching values.
