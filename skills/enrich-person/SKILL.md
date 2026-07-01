---
name: enrich-person
description: Look up a person's profile by name, email, phone, LinkedIn URL, NPI number, or name + employer. Returns their profile and verified contact info (emails, phones)
---

# Enrich Person

Take an identifier for a single person and return their RocketReach profile with contact info.

## Input

The user will provide at least one of these to identify the person:

- LinkedIn URL
- Name + current employer (both required together)
- Email address
- Phone number (resolved to a profile via person_search first — see step 2)
- NPI number (US healthcare professionals)
- RocketReach Profile ID

Examples:

- `/rocketreach:enrich-person www.linkedin.com/in/jamesgullbrand`
- `/rocketreach:enrich-person jamie@rocketreach.co`
- `/rocketreach:enrich-person +12076717456`
- `/rocketreach:enrich-person Jamie Gullbrand at RocketReach`
- `/rocketreach:enrich-person Jamie Gullbrand at www.rocketreach.co`

## Workflow

1. **Identify the person.** Pick the strongest identifier the user gave. A RocketReach profile ID, NPI, email, or LinkedIn URL resolves a single person directly; name + current employer usually does too. A **phone number is not a person_lookup identifier** — resolve it to a profile via person_search first (step 2). If they only gave a name, ask for the employer too, since name alone is ambiguous.
2. **Disambiguate / resolve to a profile (only if needed).** If the input is a phone number, a vague role, or a name without a deterministic identifier, call person_search with the parsed cues (phone, current_employer, name, current_title) and page_size: 5.

   Resolution rules:
   - Single result → mark auto-resolved, proceed to enrichment.
   - Top result high confidence (matches all input cues) → present the candidate to the user and proceed.
   - Multiple plausible candidates → present top 3 with name, title, current employer, location. Ask the user to pick. Mark ambiguous until picked.
   - Zero results → mark failed, ask the user for a more specific identifier.
3. **Pick the lookup type and confirm they have enough credits.** Depending on the user's plan, they will have one of the following types of credits. If the user has multiple active credit types, then we should confirm with the user which type should be used before continuing. The enrichment will consume 1 lookup credit (plus 1 person_export credit if issued on the user's plan; silently skipped if not issued).
   - Premium Credit - A or A- grade email or phone
   - Standard Credit - A or A- grade email only
   - Phone Credit - When a phone is returned
   - Enrich Credit - When the contact exists in our database
4. **Call person_lookup** with the resolved identifier and the lookup type. Preferred identifier order: RocketReach profile ID → NPI → email → LinkedIn URL → name + employer. A phone-based lookup uses the profile ID resolved in step 2.
5. **Handle pending lookups.** The lookup is asynchronous. If it returns `status: pending`, the contact is still resolving — tell the user results are still verifying and that final verified emails/phones will follow. Poll via check_person_status with the returned profile_id, respecting the response's retry_after_seconds hint (~3s between polls). check_person_status does not consume credits.
6. **Display Credit Cost.** Display if a credit was charged for the lookup. If the criteria below wasn't met, then we can say that no credit was used.
   - Premium Credit - A or A- grade email or phone
   - Standard Credit - A or A- grade email only
   - Phone Credit - When a phone is returned
   - Enrich Credit - When the contact exists in our database
7. **Format the contact card.** Use the output template below.

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
