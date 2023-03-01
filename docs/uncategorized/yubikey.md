# Configuring and Using the Yubikey

The following setup enables us to use the YubiKey with OpenPGP, the Authentication subkey [as an SSH key](https://developers.yubico.com/PGP/SSH_authentication/) and the Encryption subkey to sign Git commits.

## Configuration using yubikey-agent with ssh key signing

[yubikey-agent](https://github.com/FiloSottile/yubikey-agent) greatly simplifies the setup for storing an SSH key on your yubikey.

### Instructions

1. Follow the instructions for [installing yubikey-agent](https://github.com/FiloSottile/yubikey-agent#installation).
1. Optional (but recommended): Follow the workaround below for setting a "cached" touch policy.
2. Add the public key to your [GitLab account](https://gitlab.com/-/profile/keys) for authentication and signing.
3. Copy the public key that was created in (1) to a file (e.g.: `~/.ssh/yubikey.pub`).
4. Follow the instructions to [use your ssh key for signing](https://docs.gitlab.com/ee/user/project/repository/ssh_signed_commits/#configure-git-to-sign-commits-with-your-ssh-key).

### Workaround for setting a ["cached" touch policy](https://docs.yubico.com/yesdk/users-manual/application-piv/pin-touch-policies.html)

When doing a rebase with multiple commits, or using ssh automation like `knife ssh ...` it will be a bit of a pain using the default `yubikey-agent` configuration since a touch is required for every signature or ssh session.
This is a known limitation but it is possible to set a touch policy of "cached" with the following script as a workaround, this will cache touches for 15 seconds:

1. Run through the `yubikey-agent` setup as instructed above in step 1.
1. Ensure that you have `ykman` installed and it works, you may need to re-insert your yubikey, run `ykman info` to confirm.
1. Run the following script, `PIN=<your pin> ./reset-yubikey.sh`, **this will invalidate the previous key and set a new one**:

<details>

```bash
#!/usr/bin/env bash

# Resets yubikey with a cached touch policy, cribbed from
# https://github.com/FiloSottile/yubikey-agent/issues/95#issuecomment-904101391

set -e

PIN=${PIN:-000000}

read -rp "THIS WILL RESET YOUR YUBIKEY WITH PIN=$PIN, type "CTRL+C" to cancel"

# Reset PIV module
ykman piv reset -f

# Using PIN $PIN just for the sake of example, ofc.
ykman piv access change-pin -P 123456 -n $PIN
# Set the same PUK
ykman piv access change-puk -p 12345678 -n $PIN
# Store management key on the device, protect by pin
ykman piv access change-management-key -P $PIN -p

# Generate a key in slot 9a
ykman piv keys generate --pin=$PIN -a ECCP256 --pin-policy=ONCE --touch-policy=CACHED 9a /var/tmp/pkey.pub
# Generate cert
ykman piv certificates generate --subject="CN=SSH Name+O=yubikey-agent+OU=0.1.5" --valid-days=10950  9a /var/tmp/pkey.pub

# Read the public key and use it as you normally would
ssh-add -L
```

</details>
