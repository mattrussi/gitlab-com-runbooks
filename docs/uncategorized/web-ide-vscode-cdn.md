# Web IDE Assets

The Web IDE requires external assets that it would normally fetch from
a third-party controlled domain. In order to prevent our customers from
having to fetch resources from a 3rd party, we self-host those assets.

The assets are currently hosted in Cloudflare R2 storage. They are synced from the [gitlab-web-ide-vscode-fork](https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork) repository with CI.
We serve these files via Cloudflare workers that are defined in and deployed from the [cloudflare directory](https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork/-/tree/main/cloudflare) of the `gitlab-web-ide-vscode-fork`.

The domains that host these assets are as follows.

- `*.cdn.web-ide.gitlab-static.net`
- `*.staging.cdn.web-ide.gitlab-static.net`
