---
name: verify-email
description: Check whether an email address you already have is deliverable. Confirms format, checks the domain accepts mail, and probes the mailbox on the receiving mail server. Returns valid, invalid, catchall, or unknown
---

# Verify Email

Take an email address the user already has and confirm whether mail sent to it will land.

## Input

The user provides the address (or addresses) to check.

- A single email address.
- A list of addresses - pasted, or from a CRM export, spreadsheet column, or earlier result table.

Examples:

- `/rocketreach:verify-email jamie@rocketreach.co`
- `/rocketreach:verify-email` followed by a pasted column of addresses
- `/rocketreach:verify-email check the emails in the attached CSV before I import them`

## Workflow

1. **Confirm this is the right skill.** verify-email tests an address the user already has; it does not find one. If the user wants an address for a person, use enrich-person instead - it returns graded emails directly. Verification earns its credit on addresses from outside RocketReach (CRM records, event lists, hand-typed addresses) and on addresses that have been sitting for a while. An email that person_lookup just returned already carries a grade and an SMTP state.
2. **Confirm verification credits.** email_verification is its own credit pool - separate from lookup, person_export, and company_export credits, so having those does not mean having these. If the balance has not been surfaced in this conversation, call account and read the email_verification entry in credit_usage. If the balance is 0:
   - Stop before calling email_verify.
   - Surface: "Your account has no Email Verification credits. You can purchase more at https://rocketreach.co/verify/purchase_credits."
   - Do not call email_verify. The call would fail with insufficient_credits.
3. **Price the batch before spending.** Each call verifies one address and charges 1 credit. A single address needs no confirmation - just run it. For more than one, state the count and the cost and pause for a go:
   - Verifying these [N] addresses will use up to [N] Email Verification credits (credits are refunded for any that come back unknown). Your current balance: [N] credits.
   - Do not start the batch before the user responds.
4. **Call email_verify once per address.** There is no batch mode - a list of 40 addresses is 40 calls. Keep concurrency modest so a long list does not trip the rate limit; if it does, pause briefly and resume where it stopped.
5. **Read the status first, checks second.** status is the verdict; checks explain it. See the status table below for what each one means and what the user should do about it.
6. **Handle unknown without burning credits twice.** unknown means the receiving server gave no usable answer, so the result is inconclusive rather than negative. The credit is refunded and credits_charged comes back 0. An immediate retry will not resolve it - at most one retry, later, is worth attempting.
7. **Format the result.** Use the output template below.

## Status meanings

| status | What it means | What to do |
| --- | --- | --- |
| `valid` | The mailbox exists and accepts mail. | Safe to send. |
| `invalid` | The mailbox does not exist, or the domain rejects mail. | Do not send - remove it from the list. |
| `catchall` | The domain accepts mail for any address, so this specific mailbox cannot be confirmed either way. | Inconclusive. Mail will be accepted by the server but may not reach a real person. This is the same state person_lookup reports as `accept-all` in an email's `smtp_valid`. |
| `unknown` | The receiving server gave no usable answer. | Inconclusive, and no credit charged. Retry once later if it matters. |

`checks` reports the signals behind the status. Each is `true`, `false`, or `null` when it could not be determined - `null` is a gap in the evidence, not a failure. The checks explain the status; they do not override it. In particular `checks.catchall: true` does not imply `status: catchall`: SMTP alone cannot single out one mailbox on a catch-all domain, so a `valid` status there means RocketReach confirmed the address by a non-SMTP method. Read `status` for the verdict.

| check | Meaning |
| --- | --- |
| `format_valid` | The address is syntactically well-formed. |
| `domain_valid` | The domain exists and accepts mail. |
| `disposable` | The address belongs to a throwaway or temporary email provider. |
| `catchall` | The domain accepts mail for any address. |

## Output - single address

Lead with a header line, then the detail table.

`[email] - [status] · [mx_record, or "no MX record"]`

| Field | Value |
| --- | --- |
| Status | [status] |
| Credits charged | [credits_charged] |
| Format valid | [checks.format_valid] |
| Domain valid | [checks.domain_valid] |
| Disposable | [checks.disposable] |
| Catch-all | [checks.catchall] |
| MX record | [mx_record] |

Close with a one-line recommendation drawn from the status table - whether to send, drop, or treat the address as unconfirmed.

## Output - list

| # | Email | Status | Disposable | Catch-all | Credits |
| --- | --- | --- | --- | --- | --- |
| 1 | | | | | |
| 2 | | | | | |

Summary: [N] verified - [N] valid, [N] invalid, [N] catch-all, [N] unknown. [N] credits charged.

Call out the invalid addresses explicitly so the user can remove them, and flag any `disposable: true` results even when the status is valid - the mailbox works, but it is a throwaway.

## Next Steps

- `/rocketreach:enrich-person` - when an address comes back invalid, find the person's current verified email.
- `/rocketreach:build-list` - find more people at the same company.
- `/rocketreach:prospect` - build a ranked prospect list with verified contact data included.

## Notes

- **Credit pool is separate.** Verification uses email_verification credits. A user with plenty of lookup credits can still have none of these; the account tool is the way to tell.
- **Refunds apply to unknown only.** valid, invalid, and catchall all charge 1 credit. Trust `credits_charged` in the response rather than assuming.
- **One address per call.** Cost scales linearly with list size, which is why step 3 confirms before a batch.
- **catchall is not a pass.** A `catchall` *status* means the address could not be confirmed by any method, because the domain accepts everything - including addresses that reach nobody. Treat it as unconfirmed, not as valid. The `checks.catchall` flag is a different thing: it describes the domain rather than the address, and it is `true` whenever the domain is catch-all. The two disagree when a non-SMTP method confirms the mailbox on a catch-all domain; the status is then `valid` and can be trusted as such.
- **Host-level prompts.** Verification consumes a credit, so the user's AI client may prompt for permission before each call. That is the per-call safety net - narrate it cleanly rather than trying to work around it.
