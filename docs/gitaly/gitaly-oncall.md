# On Call Rotation
Gitaly on-call should only be paged by the following people:

SRE on-call or IMOC during production incidents only.
Support Engineers or Support Managers during customer emergencies.

Use /incident escalate on Slack for these cases, then select the Gitaly EOC under On-call teams.
For all other cases please file an issue under Customer issues.
Please do not page on-call outside of these cases. If you're working on a
customer emergency but not part of Support, please contact Support instead!

# Rotation
The incident.io schedule is the
source of truth for who is on-call.
The rotation is staffed during working hours of team members (no weekends). This still covers 24h of workdays, given the distribution of team members, but without guarantees.

Weekends are explicitly out of scope (not staffed), and escalation must fall back to the current EOC rotation.
Given that responsibilities are only during working hours, there's no additional compensation unless explicitly specified otherwise.
You can choose to take time in lieu via Workday, selecting the On-Call Time in Lieu option after a shift.


# Expectations during on-call shift

Provide technical assistance for ONLY the cases described above

15 minutes response time to a incident.io page while
on-call. This does not apply to pings to the @gitaly-oncall Slack handle,
which should be used to inform the Gitaly on-call of relevant happenings, but
should not be used for emergencies.

The on-call is expected to be available and reachable (but not necessarily actively working, as long as you can start the investigation within this SLO.)
If paged less than 15 minutes before the end of a shift, you still must respond and explicitly hand off the incident.


Serve as point of contact for questions in the #g_gitaly channel as well as new Request For Help issues.

Acknowledge inquiries in the #g_gitaly channel on a best-effort basis.
Triage new Request for Help issues: establish urgency and work with EM/PM to assign a milestone.


Ongoing production incidents and customer escalations are explicitly handed off by the outgoing on-call to the next Gitaly on-call using the incident channel on Slack.
Team members are responsible for finding coverage for PTO and Holidays. Install incident.io mobile application, navigate to Schedules then click on the person icon with arrows to request for cover