---
name: enrich-person
description: Look up a person's profile by name, email, phone, LinkedIn URL, NPI number, or name + employer. Returns their profile and verified contact info (emails, phones)
---

# Enrich Person

Take an identifier for a single person and return their RocketReach profile with contact info.

## Endpoint

Use the People Lookup API (GET /person/lookup). This consumes export credits.

## Input

The user will provide at least one of these to identify the person:

- LinkedIn URL
- Name + current employer (both required together)
- Email address
- Phone number
- NPI number (US healthcare professionals)

Examples:

- `/rocketreach:enrich-person www.linkedin.com/in/jamesgullbrand`
- `/rocketreach:enrich-person jamie@rocketreach.co`
- `/rocketreach:enrich-person +12076717456`
- `/rocketreach:enrich-person Jamie Gullbrand at RocketReach`
- `/rocketreach:enrich-person Jamie Gullbrand at www.rocketreach.co`

## Workflow

1. **Identify the person.** Pick the strongest identifier the user gave. LinkedIn URL OR NPI match a single person cleanly. If they only gave a name, ask for the employer too, since name alone is ambiguous.
2. **Pick the lookup type and confirm they have enough credits.** Depending on the user's plan, they will have one of the following types of credits. If the user has multiple active credit types, then we should confirm with the user which type should be used before continuing. The enrichment will consume 1 lookup credit (plus 1 person_export credit if issued on the user's plan; silently skipped if not issued).
   - Premium Credit - A or A- grade email or phone
   - Standard Credit - A or A- grade email only
   - Phone Credit - when a phone is returned
   - Enrich Credit - When the contact exists in our database
3. **Call /person/lookup** with the identifier and the lookup type.
4. **Handle in-progress lookups.** A lookup may return status: progress while emails finish verifying. If so, tell the user results are still verifying and that final verified emails will follow (via the check-status endpoint or a webhook).
5. **Display Credit Cost.** Display if a credit was charged for the lookup. If the criteria below wasn't met, then we can say that no credit was used.
   - Premium Credit - A or A- grade email or phone
   - Standard Credit - A or A- grade email only
   - Phone Credit - when a phone is returned
   - Enrich Credit - When the contact exists in our database

## Output

Lead with a header line, then present the returned fields below. Not every field is populated for every profile - show what is present. Only include contact data that is available based on the credit type used - Standard (contact data is limited to email only), Premium (emails + phones), Phone (emails + phones), Enrich (no contact data),

`[Name] -  [current_title] at [current_employer] · [location]`

| Field | Value |
| --- | --- |
| Name | [name] |
| Title | [current_title] |
| Employer | [current_employer] ([current_employer_domain]) |
| Location | [city], [region], [country] |
| LinkedIn | [linkedin_url] |
| Best Work Email | [recommended_professional_email] (grade) |
| Best Personal Email | [recommended_personal_email] (grade) |
| Best Phone | [the phone in phones[] marked recommended] (type) |
| Other Work Emails | [remaining professional emails from emails[], with grades] |
| Other Personal Emails | [remaining personal emails from emails[], with grades] |
| Other Phones | [remaining phones from phones[], with types] |
| Experience | [job_history[]: company, title, dates] |
| Education | [education[]: school, degree] |
| RocketReach ID | [id] |

Pick the "best" of each directly from the dedicated fields: Best Work Email = recommended_professional_email, Best Personal Email = recommended_personal_email, Best Phone = the entry in phones[] flagged recommended. List every other entry from emails[] (split by type: professional vs personal) and phones[] in the matching "Other" row. Each email in emails[] carries a type (professional / personal) and a grade - always show the email grade (A / A- / B).

## Next Steps

- `/rocketreach:enrich-company`: look up the contact's employer for firmographic detail.
- `/rocketreach:build-list`: find more people at the same company or in the same role.
- `/rocketreach:prospect`: build a ranked list of similar prospects.

## Notes

- **Asynchronous lookups.** Some lookups resolve immediately; others return pending and require polling via check_person_status. Typical resolution is a few seconds. The workflow handles both.
- **Credit asymmetry.** person_export is silently skipped if not issued on the user's plan — the lookup still succeeds, but the reported cost should reflect what was actually charged (1 lookup credit only in that case).
- **Healthcare data presence varies.** NPI, specialization, and credentials are populated only when the resolved person is in RocketReach's US healthcare data set. Their absence is not an error.
- **Host-level prompts.** The person_lookup tool is marked destructiveHint: true, so the AI client will prompt the user for permission before the lookup call. This is the per-call safety net; the skill should narrate it cleanly rather than try to suppress it.
