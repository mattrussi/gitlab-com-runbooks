<!-- Permit linking to GitLab docs and issues -->
<!-- markdownlint-disable MD034 -->
# Duo Enterprise License Access Process for Staging Environment

This runbook provides instructions for obtaining Duo Enterprise license access in the staging environment. It is intended for backend developers, SREs, and other engineers who need to test features within staging environments.

---

**Table of Contents**

[TOC]

---

## Quick Reference

- **Primary Contact:** #g_provision Slack channel
- **Secondary Contact:** #s_fulfillment Slack channel 
- **Required Access:** GitLab.org group membership
- **License Type:** Duo Enterprise (preferred over Duo Pro)

## Prerequisites

- Active GitLab.org account
- Membership in relevant project/group
- Justification for staging environment access

## Process Steps

### 1. Request Access

1. Join the `#g_provision` Slack channel
2. Submit request with following information:
   - Your GitLab username
   - Project/team association
   - Business justification
   - Required license type (Duo Enterprise)

### 2. License Assignment

Once approved:
- An admin will add you to the appropriate gitlab-org namespace
- Verify license assignment in staging environment
- Confirm access to Duo Enterprise features

### 3. Verification

To verify your license:
1. Sign into [staging.gitlab.com](https://staging.gitlab.com)
2. Navigate to any project
3. Open Web IDE
4. Confirm Duo Chat functionality

## Troubleshooting

Common issues and solutions:

| Issue | Solution |
|-------|----------|
| No license showing | Contact #g_provision |
| Wrong license type | Request upgrade to Enterprise |
| Access denied | Verify group membership |

## Additional Notes

- Licenses are managed at the namespace level
- gitlab-org namespace on staging has custom setup
- Automatic seat assignment is planned for future implementation

## Related Resources

- [Duo Access Request Process](link-to-handbook)
- [Staging Environment Documentation](link-to-docs)
- [License Management Guidelines](link-to-guidelines)

## Support

For additional assistance:
- Slack: #g_provision
- Issue tracker: [GitLab.org](gitlab-org-link)