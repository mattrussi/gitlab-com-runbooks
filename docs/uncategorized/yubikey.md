# Configuring and Using the Yubikey

The following setup enables us to use the YubiKey with OpenPGP, the Authentication subkey [as an SSH key](https://developers.yubico.com/PGP/SSH_authentication/) and the Encryption subkey to sign Git commits.

:warning:

**Consider setting up 2 Yubikeys.  Keys will fail, so having a backup reduces the pain and grief when failures occur.**

## The Tooling

You'll be using the following tooling:

* [`yubikey-agent`](https://github.com/FiloSottile/yubikey-agent)
* [`ykman`](https://docs.yubico.com/software/yubikey/tools/ykman/)

### Setup Instructions

**WARNING**: When setting a pin, make sure it is between 6 and 8 ASCII characters, longer pins may be silently truncated.

1. Follow the instructions for [installing `yubikey-agent`](https://github.com/FiloSottile/yubikey-agent#installation). **But do not run the `setup` command for your yubikey. This is handled as part of the yubikey-reset.sh script below.**
1. Follow the instructions for [installing `ykman`](https://docs.yubico.com/software/yubikey/tools/ykman/)
1. Follow the instructions below for setting a "cached" touch policy. These steps, and the script run, will create keys and certificates using ykman.
1. Follow the instructions to [use your ssh key for signing](https://docs.gitlab.com/ee/user/project/repository/ssh_signed_commits/#configure-git-to-sign-commits-with-your-ssh-key).
   * [.com](https://gitlab.com/-/profile/keys)
   * [ops](https://ops.gitlab.net/-/profile/keys)
   * [dev](https://dev.gitlab.org/-/profile/keys)

* Add the Yubikey to your favorite 2FA services:
  * GitLab
  * Okta
  * AWS
  * etc

### Setting a ["cached" touch policy](https://docs.yubico.com/yesdk/users-manual/application-piv/pin-touch-policies.html)

**When following the below instructions, your Yubikey will be reset**

When doing a rebase with multiple commits, or using ssh automation like `knife ssh ...` it will be painful using the default `yubikey-agent` configuration since a touch is required for every signature or ssh session.
This is default configuration but we set a touch policy of "cached" with the following script, this will cache touches for 15 seconds:

1. Validate `ykman` has access to the key, you may need to re-insert your yubikey, run `ykman info` to confirm.
1. Run the [`scripts/yubikey-reset.sh` script](https://gitlab.com/gitlab-com/runbooks/-/blob/master/scripts/reset-yubikey.sh), `PIN=<your pin> scripts/reset-yubikey.sh`, **this will invalidate the previous key and set a new one**:

### Workaround if your yubikey is not responding

If you discover that your Yubikey is not responding, a restart of the `yubikey-agent` may be needed. Usually `ssh-add -l` will throw an error.

Run the following brew command on your local machine.

```
brew services restart yubikey-agent
```

We suspect that this is impacting only Macbook / macOS users.
