<!-- Permit linking to GitLab docs and issues -->
<!-- markdownlint-disable MD034 -->
# Duo Enterprise License Access Process for Staging Environment

This guide explains how to self-service Duo Enterprise license access in the staging environment for backend developers, SREs, and other engineers who need to test AI features.

---

## Prerequisites

- Active staging.gitlab.com account
- Existing Ultimate/Premium license on staging 
- Access to Okta for Zuora SSO
- GitLab.org group membership

## Self-Service Process 

### Access License Management

1. Log in to [customers.staging.gitlab.com](https://customers.staging.gitlab.com) using your staging.gitlab.com credentials
2. Locate and copy your Zuora subscription ID (format: A-ABC123...)

### Add Duo License Through Zuora

1. Access Zuora through Okta SSO
2. Select the Central Sandbox ("Staging") environment 
3. Use search bar (or CMD+K) to locate your subscription using the Zuora ID
4. Click "Create order"
5. Select "Add product" 
6. Choose Duo Enterprise version
   - Click the arrow next to the product
   - Select desired renewal rate
   - Check the box to confirm selection
7. Click "Add product"
8. Click "Activate"

### Verify License Access

1. Sign into [staging.gitlab.com](https://staging.gitlab.com)
2. Navigate to any project
3. Open Web IDE or Code Suggestions feature
4. Confirm Duo functionality is active

## Troubleshooting

If you encounter issues, check the following:

| Symptom | Verification Steps | Resolution |
|---------|-------------------|------------|
| Features not available | Check subscription status in customers.staging.gitlab.com | Follow self-service steps above |
| Need upgrade from Duo Pro | Check current license type in subscription details | Create new order for Duo Enterprise |
| Authorization errors | Verify Okta access and permissions | Contact #g_provision |

The GitLab AI Features Health Check will surface specific errors if there are issues with:
- License validation
- Feature availability 
- Access permissions

## Additional Information

- Licenses are managed at the namespace level
- The gitlab-org namespace on staging has a custom setup
- Most developers should use staging environment rather than local setup
- Duo Enterprise is preferred over Duo Pro for complete feature testing

## Related Documentation

- [AI Features Documentation](https://docs.gitlab.com/development/ai_features/)
- [Code Suggestions Setup Guide](https://docs.gitlab.com/development/code_suggestions/)
- [Staging Environment Documentation](link-to-docs)
- [License Management Guidelines](link-to-guidelines)

## Support Channels

For issues with self-service process:

- Primary Support: #g_provision Slack channel
- Secondary Support: #s_fulfillment Slack channel
- Documentation Issues: [GitLab AI Documentation](gitlab-org-link)

## Notes

- Keep subscription ID handy for future reference
- Automatic seat assignment is planned for future implementation
- Regular validation of license status is recommended
