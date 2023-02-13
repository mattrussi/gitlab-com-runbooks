# Configuring and Using the Yubikey

The following setup enables us to use the YubiKey with OpenPGP, the Authentication subkey [as an SSH key](https://developers.yubico.com/PGP/SSH_authentication/) and the Encryption subkey to sign Git commits.

## Configuration using yubikey-agent with ssh key signing

[yubikey-agent](https://github.com/FiloSottile/yubikey-agent) greatly simplifies the setup for storing an SSH key on your yubikey.

### Instructions

1. Follow the instructions for [installing yubikey-agent](https://github.com/FiloSottile/yubikey-agent#installation).
2. Add the public key to your [GitLab account](https://gitlab.com/-/profile/keys) for authentication and signing.
3. Copy the public key that was created in (1) to a file (e.g.: `~/.ssh/yubikey.pub`).
4. Follow the instructions to [use your ssh key for signing](https://docs.gitlab.com/ee/user/project/repository/ssh_signed_commits/#configure-git-to-sign-commits-with-your-ssh-key).

### Notes

- One disadvantage of storing the key used for commit signing on the the yubikey is that you will need to touch the yubikey multiple times for a git rebase.
