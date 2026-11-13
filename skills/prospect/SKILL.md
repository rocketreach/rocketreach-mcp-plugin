---
name: prospect
description: Describe your ideal customer in plain English and get a ranked table of decision-makers with verified contact data
---

# Prospect

Turn a plain-English description of an ideal customer into a ranked list of decision-makers with verified contact info, in one flow.

This runs the full pipeline: search for the right people, rank them, then enrich the best ones. Use build-list instead if the user only wants to browse matches without spending credits.

## Input

The user describes their ideal customer in plain English.

- Title / management level / department - required (must include at least one)
- Industry - optional
- Company Size - optional
- Location - optional

If the description is too vague to search well, ask 1-2 quick questions to clarify further.

## Examples

- `/rocketreach:prospect VPs of Sales at Series B SaaS companies in the US`
- `/rocketreach:prospect Heads of Marketing at EU e-commerce companies with 100-500 employees`
- `/rocketreach:prospect CTOs at fintech startups in NYC`
- `/rocketreach:prospect Procurement directors at large manufacturers using SAP`
- `/rocketreach:prospect SDR leaders at companies using Salesforce and Outreach`

## Workflow

1. **Parse the ICP into search filters.** Use person_search to map to the fields outlined below
   - Job title → current_title
   - Management level → management_levels
   - Department → department
   - Location → location
   - Company Industry → company_industry
   - Company Size → company_size

   The management_levels, department, and company_industry fields match exact stored values only. For each one you use, call list_filter_values with the field and one or two key words from the ICP, then pass the returned `value` exactly. A guessed value silently narrows the search or empties it, so if nothing matches, tell the user and offer the closest returned values before searching. No credits consumed. Pass `location` as free text (a city, state, country, or zip code) without a lookup.
2. **Check Credits available.** Call account once. Capture the user's lookup credit balance, person_export issuance, and daily API call limit. Compute the batch cost projection:
   - Default: 10 candidates enriched = 10 lookup credits (+ 10 person_export credits if issued).
   - If the projected cost would consume more than the user's available lookup credits, OR if the user is on a free plan, flag this and pause for explicit confirmation before proceeding.
3. **Discover Candidates.** Call person_search with the parsed filters. Defaults:
   - page_size: 25 (search broadly; enrich the top 10).
   - order_by: relevance.
4. **Preview Candidates.** Present the top 25 candidates as a preview table with name, title, company, location. Restate the credit cost:
   - Enriching the top 10 candidates will consume 10 lookup credits (+ 10 person_export credits if issued). Your current balance: [N] lookup credits available.
   - Reply with "go" to proceed, "show me more" to expand to 25, or specify a number to enrich (1–25).
   - Pause for confirmation. Do not consume credits before the user responds.
5. **Batch enrichment.** On confirmation, call bulk_person_lookup once with one query per confirmed candidate, using each candidate's profile ID from the search (up to 100 per call):
   - Each query is charged like a single person_lookup. If any query is invalid, the whole call is rejected with no credits charged.
   - The batch returns `status: pending` with an `rr_request_id`. Poll check_person_status with that `rr_request_id` every 3–5 seconds (respect `retry_after_seconds`) until no record is still pending or 60 seconds pass. Surface any remaining unresolved at the end.
6. **Rank by ICP fit.** Score each result against the matched criteria:

   Matched Criteria to check:
   - Job title
   - Management level
   - Department
   - Location
   - Company Industry
   - Company Size

   Ranking:
   - Strong - if more than 75% of the input criteria matches
   - Good - if more than 50% of the input criteria matches
   - Partial - if more than 25% of the input criteria matches
7. **Format the output.** Use the output template below.

## Output

Leads matching: [ICP summary]

| # | Name | Title | Company | Best Work Email (grade) | Best Personal Email (Grade) | Best Phone | ICP Fit |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | | | | | | | Strong |
| 2 | | | | | | | Good |

Best Email = recommended_professional_email (or recommended_personal_email if no work email), Best Phone = the phones[] entry flagged recommended.

Summary: Found X matches, enriched top Y. Z credits used ([type]).

## Next actions

- `/rocketreach:enrich-person` - drill into one of the resulting leads.
- `/rocketreach:enrich-company` - look up one of the employer companies in detail.
- `/rocketreach:build-list` -  for a search-only pass before committing to enrichment credits.

## Notes

- **Host-level prompts during batch.** bulk_person_lookup is destructiveHint: true, so the user's AI client may ask for permission before the call. One bulk call means one prompt for the whole batch, where separate person_lookup calls would prompt once per person.
- **person_export asymmetry.** Plans without person_export credits issued will see the lookup succeed but the export credit silently skipped. The reported cost should reflect what was actually charged.
- **Pending lookups.** Some lookups take longer than a few seconds to resolve. The batched polling pattern handles this; if any remain unresolved after 60 seconds, surface them as pending in the summary so the user knows to check back.
- **Search-result quality varies by ICP specificity.** Very broad ICPs ("any executive") will produce many low-fit candidates; very narrow ICPs may return < 10 candidates. Iteration Options should propose concrete refinements based on the actual result distribution.
