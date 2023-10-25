#### How to access MacOS VMs?

MacOS VMs are currently hosted in AWS. SRE should have access to the Production environment via Okta.

### Production

All SRE should have access to the MacOS Production environment through Okta:

- Go to Okta.
- Click `AWS Services Org`.
- Under `AWS Account` pick `saas-mac-runners-b6fd8d28`.

Most of the resources exist in the `N. Virginia` (`us-east-1`) region; if you're looking for more info, go to [resources.md](./resources.md) for information about the used resources.

*NOTE*: if you don't see `AWS Services Org`, then open an individual [Access Request](https://gitlab.com/gitlab-com/team-member-epics/access-requests/-/issues), to get access to the AWS account:  `saas-mac-runners-b6fd8d28`. See past [bulk access request](https://gitlab.com/gitlab-com/team-member-epics/access-requests/-/issues/21531).

### Staging

If you think you have the appropriate access in the sandbox, you can view the Staging environment following these steps:

- Go to the [sandbox](https://gitlabsandbox.cloud/cloud/accounts/5442c67c-1673-4351-b85d-e366c328bfea)
- Choose `eng-dev-verify-runner`.
- Click `View IAM Credentials`.
- Click the `AWS Console URL`.
- Copy the username and password; beaware that sometimes the copy can produce extra spaces before and after the text.

Just like the Production environment, resources are mostly in `N. Virginia` (`us-east-1`) region, for more info go to [resource.md](./resources.md).

You can optionally switch to the Production environment without using Okta:

- Click your username in the upper right corner.
- From the dropdown menu, choose `Switch role`.
- Enter the details in [verify-runner handbook](https://about.gitlab.com/handbook/engineering/development/ops/verify/runner/team-resources/#access-mac-runner-production).
