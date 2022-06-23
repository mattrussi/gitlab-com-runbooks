# Configuring and Using the Yubikey

The following setup enables us to use the YubiKey with OpenPGP, and the Authentication subkey [as an SSH key](https://developers.yubico.com/PGP/SSH_authentication/).

## Initial configuration

If you find any problems during the setup, take a look at the [troubleshooting](#troubleshooting) section at the end
of this document.

### 1. Requirements

<p>
<details>
<summary>Linux</summary>

* `gpg2`

      ```
      sudo apt-get install gnupg2
      ```

      Lets create an alias so that we can use `gpg` instead of using `gpg2` all the time:

      ```
      echo "alias gpg='gpg2'" >> ~/.bashrc
      ```

* `scdaemon`

      ```
      sudo apt-get install scdaemon
      ```

* For Yubikey 4 **only** -> `yubikey-personalization`

      ```
      sudo apt-get install yubikey-personalization
      ```

      Yubikey 4 does not come with all modules enabled. This setting lets us use the Yubikey as both a SmartCard and an OTP device at the same time.

      ```bash
      ykpersonalize -m86
      ```

      This setting lets us use the Yubikey as both a SmartCard and an OTP device
      at the same time.

* For Yubikey 5 **only** -> ykman. On Linux the pkg name is `yubikey-manager`.

      ```
      sudo apt-get install yubikey-manager
      ```

      `ykman` manual can be found [online](https://support.yubico.com/hc/en-us/articles/360016614940-YubiKey-Manager-CLI-ykman-User-Manual)

</details>
</p>

<p>
<details>
<summary>MacOS</summary>

* `gpg2`

      ```
      brew install gnupg
      ```

* For Yubikey 4 **only** -> `yubikey-personalization`

      ```
      brew install yubikey-personalization
      ```

      Yubikey 4 does not come with all modules enabled. This setting lets us use the Yubikey as both a SmartCard and an OTP device at the same time.

      ```bash
      ykpersonalize -m86
      ```

      This setting lets us use the Yubikey as both a SmartCard and an OTP device
      at the same time.

* For Yubikey 5 **only** -> `ykman`

      ```
      brew install ykman
      ```

      `ykman` manual can be found [online](https://support.yubico.com/hc/en-us/articles/360016614940-YubiKey-Manager-CLI-ykman-User-Manual)

* For graphical pin-entry on MacOS install the brew package `pinentry-mac`

    ```bash
    brew install pinentry-mac
    ```

</details>
</p>

### 2. Change the default PIN entries

The yubikey comes pre-configured with a set of default PINs that we need to change. By default the user PIN is `123456` and the ADMIN PIN is `12345678`.

<p>
<details>
<summary>How to change the default pin entries</summary>

The `unlock pin` is what you will use most of the time for confirming access via the keys stored on the Yubikey.

```bash

> gpg --card-edit

Application ID ...: D2760001240102000006123482780000
Version ..........: 2.1
Manufacturer .....: Yubico
Serial number ....: 12345678
Name of cardholder: [not set]
Language prefs ...: [not set]
Sex ..............: unspecified
URL of public key : [not set]
Login data .......: [not set]
Signature PIN ....: not forced
Key attributes ...: [none]
Max. PIN lengths .: 127 127 127
PIN retry counter : 3 3 3
Signature counter : 2
Signature key ....: [none]
Encryption key....: [none]
Authentication key: [none]
General key info..: [none]

gpg/card> admin
Admin commands are allowed

# Enable Key Derived Format for secure PIN entry
gpg/card> kdf-setup

# Change the PIN and Admin PINs
gpg/card> passwd
gpg: OpenPGP card no. D2760001240102000006123482780000 detected

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? 1
PIN changed.

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? 3
PIN changed.

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? q

# Make sure the PIN is entered before signing
gpg/card> forcesig

gpg/card> quit
```

</details>
</p>

### 3. Create a secure storage for the Master Key

We want to be able to keep a backup of the GPG master key offline, encrypted,
and stored in a super-secret-hiding-place. We do this by creating the `gpg_config` location
on a virtual disk that we mount locally. Using this approach:

* The virtual disk can be copied to a secure location for recovery (such as on
  a USB key).
* The virtual disk has a password and must be mounted locally for access to
  the gpg_config location by gpg.

To do that:

1. Create an encrypted volume

    <p>
    <details>
    <summary>MacOS</summary>

      Create an encrypted sparse bundle using MacOS' `hdiutil`:

      ```bash
      hdiutil create -fs HFS+ -layout GPTSPUD -type SPARSEBUNDLE -encryption AES-256 -volname "GitLab" -size 100m -stdinpass ~/gitlab.sparsebundle
      ```

      Mount it up:

      ```bash
      hdiutil attach -encryption -stdinpass -mountpoint /Volumes/GitLab ~/gitlab.sparsebundle
      ```

    </details>
    </p>

    <p>
    <details>
    <summary>Linux</summary>

      There are many options for Linux and an obvious option is LUKS (Linux Unified Key Setup-on-disk-format), which most Linux distributions already have installed when using full disk encryption. However, if you want the encrypted disk file to be available on other platforms such as MacOS and Windows, a better option is to use [VeraCrypt](https://veracrypt.fr). The below instructions are based on **VeraCrypt** version 1.23.

      The actions below are similar to the activities completed above for MacOS.

      You can either perform the below actions using the **VeraCrypt** UI or by using the CLI:

      Create volume file

      ```bash
      veracrypt --text --create --encryption AES --hash SHA-512 --size 100M --volume-type normal --filesystem FAT --keyfiles "" $HOME/gitlab_secrets

      Enter password:
      Re-enter password:
      Enter PIM:  [Enter]
      Please type at least 320 randomly chosen characters and then press Enter:
      Done: 100.000%  Speed:   31 MB/s  Left: 0 s
      The VeraCrypt volume has been successfully created.
      ```

      **Note:** The default (just hit Enter) for the PIM is probably fine, but if you want some extra security, put in a custom value.  Higher values will take longer to open the vault, lower ones will take less time but be less secure. See <https://www.veracrypt.fr/en/Personal%20Iterations%20Multiplier%20%28PIM%29.html> for further discussion including the default values.

      Mount the volume

      ```bash
      [sudo] mkdir -m 755 /media/GitLab
      veracrypt --text --keyfiles "" --protect-hidden no $HOME/gitlab_secrets /media/GitLab

      Enter password for ...:
      Enter PIM for ...: [Enter]
      ```

    </details>
    </p>

1. Create a `gpg_config` inside our volume

    <p>
    <details>
    <summary>MacOS</summary>

      Set the mountpoint

      ```bash
      export MOUNTPOINT=[According to the OS e.g. /media]/GitLab
      ```

      Create the configuration directory where our GnuPG key rings will live:

      ```bash
      mkdir $MOUNTPOINT/gpg_config
      chmod 700 $MOUNTPOINT/gpg_config
      ```

      Export the configuration directory for GnuPG usage:

      ```bash
      export GNUPGHOME=$MOUNTPOINT/gpg_config
      ```

      Setup the `gpg.conf` before we create things:

      ```bash
      echo default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAMELLIA256 CAMELLIA192 CAMELLIA128 TWOFISH > $MOUNTPOINT/gpg_config/gpg.conf
      echo cert-digest-algo SHA512 >> $MOUNTPOINT/gpg_config/gpg.conf
      echo use-agent >> $MOUNTPOINT/gpg_config/gpg.conf
      ```

    </details>
    </p>

### 4. Create Master Key

For now, will to generate a key without the sign and encrypt capabilities, leaving
only the certify capability.

1. Create a new master key using gpg
    <p>
    <details>
    <summary>How to create a master key using gpg</summary>

    ```bash
    > gpg --expert --full-generate-key
    Please select what kind of key you want:
      (1) RSA and RSA (default)
      (2) DSA and Elgamal
      (3) DSA (sign only)
      (4) RSA (sign only)
      (7) DSA (set your own capabilities)
      (8) RSA (set your own capabilities)
    Your selection? 8

    Possible actions for a RSA key: Sign Certify Encrypt Authenticate
    Current allowed actions: Sign Certify Encrypt

      (S) Toggle the sign capability
      (E) Toggle the encrypt capability
      (A) Toggle the authenticate capability
      (Q) Finished

    Your selection? s
    Your selection? e
    Your selection? q

    RSA keys may be between 1024 and 4096 bits long.
    What keysize do you want? (2048) 4096
    Requested keysize is 4096 bits
    Please specify how long the key should be valid.
            0 = key does not expire
            = key expires in n days
          w = key expires in n weeks
          m = key expires in n months
          y = key expires in n years
    Key is valid for? (0) 4y
    Key expires at Wed 25 Aug 2021 01:45:54 AM CST
    Is this correct? (y/N) y

    GnuPG needs to construct a user ID to identify your key.

    Real name: John Rando
    Email address: rando@gitlab.com
    Comment:
    You selected this USER-ID:
        "John Rando <rando@gitlab.com>"

    Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? o

    public and secret key created and signed.
    pub   4096R/FAEFD83E 2017-08-25 [expires: 2021-08-25]
          Key fingerprint = 856B 1E1C FAD0 1FE4 5C4C  4E97 961F 703D B8EF B59D
    uid                  John Rando <rando@gitlab.com>
    ```

    </details>
    </p>

1. Place a reminder in your calendar in about 3 years 11 months (if you chose 4y lifetime above; adjust as necessary) to extend the expiry of your master key.

### 5. Create Subkeys

We'll use subkeys that are generated on the Yubikey device itself. Keys generated
on the Yubikey cannot be copied off, so loss or destruction of the device will
mean key rotation.

<p>
<details>
<summary>How to create a subkeys using gpg</summary>

  ```bash

  > gpg --edit-key FAEFD83E

  # Let's add the SIGNING subkey
  gpg> addcardkey

  Signature key ....: [none]
  Encryption key....: [none]
  Authentication key: [none]

  Please select the type of key to generate:
    (1) Signature key
    (2) Encryption key
    (3) Authentication key
  Your selection? 1

  Please specify how long the key should be valid.
          0 = key does not expire
          = key expires in n days
        w = key expires in n weeks
        m = key expires in n months
        y = key expires in n years
  Key is valid for? (0) 1y
  Key expires at Sat Aug  25 01:08:14 2018 CST
  Is this correct? (y/N) y
  Really create? (y/N) y

  pub  3072R/FAEFD83E  created: 2017-08-25  expires: 2018-08-25  usage: C
                      trust: ultimate      validity: ultimate
  sub  4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
  [ultimate] (1). John Rando <rando@gitlab.com>

  # Do the same for the ENCRYPTION subkey
  gpg> addcardkey

  Signature key ....: 546D 6A7E EB4B 5B07 B3EA  7373 12E2 68AD 79BF 574F
  Encryption key....: [none]
  Authentication key: [none]

  Please select the type of key to generate:
    (1) Signature key
    (2) Encryption key
    (3) Authentication key
  Your selection? 2

  Please specify how long the key should be valid.
          0 = key does not expire
          = key expires in n days
        w = key expires in n weeks
        m = key expires in n months
        y = key expires in n years
  Key is valid for? (0) 1y
  Key expires at Sat Aug  25 01:10:41 2018 CST
  Is this correct? (y/N) y
  Really create? (y/N) y

  pub  4096R/FAEFD83E  created: 2017-08-25  expires: 2018-08-25  usage: C
                      trust: ultimate      validity: ultimate
  sub  4096R/AE86E89B  created: 2017-08-25  expires: 2018-08-25  usage: E
  sub  4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
  [ultimate] (1). John Rando <rando@gitlab.com>

  # Do the same for the AUTHENTICATION subkey
  gpg> addcardkey

  Signature key ....: 546D 6A7E EB4B 5B07 B3EA  7373 12E2 68AD 79BF 574F
  Encryption key....: [none]
  Authentication key: [none]

  Please select the type of key to generate:
    (1) Signature key
    (2) Encryption key
    (3) Authentication key
  Your selection? 3

  Please specify how long the key should be valid.
          0 = key does not expire
          = key expires in n days
        w = key expires in n weeks
        m = key expires in n months
        y = key expires in n years
  Key is valid for? (0) 1y
  Key expires at Sat Aug  25 01:21:41 2018 CST
  Is this correct? (y/N) y
  Really create? (y/N) y

  pub  4096R/FAEFD83E  created: 2017-08-25  expires: 2018-08-25  usage: C
                      trust: ultimate      validity: ultimate
  sub  4096R/AE86E89B  created: 2017-08-25  expires: 2018-08-25  usage: E
  sub  4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
  sub  4096R/DE86E396  created: 2017-08-25  expires: 2018-08-25  usage: A
  [ultimate] (1). John Rando <rando@gitlab.com>

  # WARNING: Without saving your changes will be lost, all the above would need to be repeated.
  gpg> save

  # Make sure the subkeys were created as expected
  > gpg --list-secret-keys
  /home/rehab/.gnupg/pubring.kbx
------------------------------
sec#  rsa4096 2021-04-09 [C] [expires: 2025-04-08]
      3FCA9E1453C08NO887297DBDE61B3B56057B132D
uid           [ultimate] Rehab Hassanein <rhassanein@gitlab.com>
ssb>  rsa2048 2021-04-09 [S] [expires: 2022-04-09]
ssb>  rsa2048 2021-04-09 [E] [expires: 2022-04-09]
ssb>  rsa2048 2021-04-09 [A] [expires: 2022-04-09]
  ```

</details>
</p>

**Note:** Certain `gpg` operations can cause the usage of GPG SmartCards (i.e. the Yubikey)
to become "pinned" to a particular gpg-agent instance.
This can cause the `addcardkey` command to fail. If you run into this problem, kill any gpg-agent
processes with a different `--homedir` flag value to your current $GNUPGHOME.
Usually, there will be one running with `$HOME/.gnupg` that is the culprit.

### 6. Backup your Public Key

If your gpg version does not output the **master** key id you should use the full fingerprint instead.

```bash
# To obtain your key fingerprint
gpg --list-key
# example output
#pub   rsa4096 2021-04-09 [C] [expires: 2025-04-08]
#     3FCA9E1453C08NO887297DBDE61B3B56057B132D

gpg --armor --export FAEFD83E > $MOUNTPOINT/gpg_config/FAEFD83E.asc

#OR

gpg --armor --export 3FCA9E1453C08NO887297DBDE61B3B56057B132D > $MOUNTPOINT/gpg_config/3FCA9E1453C08NO887297DBDE61B3B56057B132D.asc
```

### 7. Import Public Key to Regular Keychain

Open up the GPG Keychain app and import the public key that you just created
into your regular keychain. Set the Ownertrust to Ultimate on the public key
you've imported.

<p>
<details>
<summary>How to import the public key to a regular keychain</summary>

In a fresh terminal (i.e. with the default GNUPGHOME env var, not the veracrypt mounted one) we can:

  ```bash
  > gpg --import $MOUNTPOINT/gpg_config/FAEFD83E.asc
  gpg: key FAEFD83E: public key imported
  gpg: Total number processed: 1
  gpg:               imported: 1

  > gpg --edit-key FAEFD83E
  Secret subkeys are available.

  pub  4096R/FAEFD83E  created: 2017-08-25  expires: 2018-08-25  usage: C
                      trust: ultimate      validity: ultimate
  sub  4096R/AE86E89B  created: 2017-08-25  expires: 2018-08-25  usage: E
  sub  4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
  sub  4096R/DE86E396  created: 2017-08-25  expires: 2018-08-25  usage: A
  [ultimate] (1). John Rando <rando@gitlab.com>

  gpg> trust
  pub  4096R/FAEFD83E  created: 2017-08-25  expires: 2018-08-25  usage: C
                      trust: ultimate      validity: ultimate
  sub  4096R/AE86E89B  created: 2017-08-25  expires: 2018-08-25  usage: E
  sub  4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
  sub  4096R/DE86E396  created: 2017-08-25  expires: 2018-08-25  usage: A
  [ultimate] (1). John Rando <rando@gitlab.com>

  Please decide how far you trust this user to correctly verify other users' keys
  (by looking at passports, checking fingerprints from different sources, etc.)

    1 = I don't know or won't say
    2 = I do NOT trust
    3 = I trust marginally
    4 = I trust fully
    5 = I trust ultimately
    m = back to the main menu

  Your decision? 5
  Do you really want to set this key to ultimate trust? (y/N) y
  gpg> quit
  ```

</details>
</p>

### 8. Copy the `gpg.conf` settings you need

Earlier in this howto, you edited a gpg.conf file in your mounted encrypted drive. You should copy that file (or it's contents) into the gpg.conf file in your ~/.gnupg directory.

```bash
cp $MOUNTPOINT/gpg_config/gpg.conf ~/.gnupg/
```

### 9. Ensure proper options are set in `gpg-agent.conf`

Ensure proper options are set in `gpg-agent.conf`

<p>
<details>
<summary>Linux</summary>

  ```bash
  cat << EOF > ~/.gnupg/gpg-agent.conf
  default-cache-ttl 600
  max-cache-ttl 7200
  pinentry-program /usr/bin/pinentry
  enable-ssh-support
  EOF
  ```

</details>
</p>

<p>
<details>
<summary>MacOS</summary>

  ```bash
  cat << EOF > ~/.gnupg/gpg-agent.conf
  default-cache-ttl 600
  max-cache-ttl 7200
  pinentry-program /usr/local/bin/pinentry-mac
  enable-ssh-support
  EOF
  ```

</details>
</p>

Ensure proper options are set in `scdaemon.conf`

<p>
<details>
<summary>Linux & MacOS</summary>

```bash
cat << EOF > ~/.gnupg/scdaemon.conf
reader-port Yubico Yubi
disable-ccid
EOF
```

</details>
</p>

Ensure your environment knows how to authenticate SSH

<p>
<details>
<summary>MacOS</summary>

```bash
export SSH_AUTH_SOCK=$HOME/.gnupg/S.gpg-agent.ssh
```

</details>
</p>

<p>
<details>
<summary>Linux</summary>

```bash
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi
```

</details>
</p>

After all the files are changed:

1. Source the `rc`

1. Remove any automation you might have that starts `ssh-agent`.

### 12. Script to Reset gpg-agent and ssh-agent

<p>
<details>
<summary>MacOS</summary>

  This script will reset `gpg-agent` and `ssh-agent` after you make the
  above updates to `gpg-agent.conf`.

  ```bash
  #!/bin/bash

  echo "kill gpg-agent"
  code=0
  while [ 1 -ne $code ]; do
      killall gpg-agent
      code=$?
      sleep 1
  done

  echo "kill ssh"
      killall ssh

  echo "kill ssh muxers"
      for pid in `ps -ef | grep ssh | grep -v grep | awk '{print $2}'`; do
      kill $pid
  done

  echo "restart gpg-agent"
      eval $(gpg-agent --daemon)

  echo
  echo "All done. Now unplug / replug the NEO token."
  echo
  ```

</details>
</p>

<p>
<details>
<summary>Linux</summary>

Reload the `gpg-agent --daemon` with the following: `gpg-connect-agent reloadagent /bye`

</details>
</p>

### 13. Export Your SSH Public Key

This generates a public key that you can paste into GitLab or use as a public key for SSH access to systems via Chef.

<p>
<details>
<summary>How to export the SSH public key</summary>

  ```bash
  > gpg --export-ssh-key FAEFD87E
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... COMMENT
  ```

</details>
</p>

### 14. Testing

Try to sign a message and connect to gitlab to check if everything is working.

<p>
<details>
<summary>How to test if everything is working</summary>

Try encrypting and signing a message, e.g. to yourself:

```
$ echo foo | gpg --encrypt --armor --sign --recipient <keyid from `gpg --list-keys`>
-----BEGIN PGP MESSAGE-----
...
-----END PGP MESSAGE-----
```

Exercise the ssh authentication functionality:

```
$ ssh-add -l
... your public key ...

# Assuming you have added your new public key to your gitlab.com profile
$ ssh git@gitlab.com
PTY allocation request failed on channel 0
Welcome to GitLab, @user!
Connection to gitlab.com closed.
```

</details>
</p>

## Maintenance

### Renew expiring subkeys

Remount your encrypted secrets image using the [veracrypt mount](#linux) or [hidutil attach](#macos) commands
Setup env vars:

```
export MOUNTPOINT=/path/to/mountpoint
export GNUPGHOME=$MOUNTPOINT/gpg_config/
```

Optionally take a backup of the original gpg\_config, inside your encrypted volume (size is tiny, it's a small price to pay)

```bash
cp -r $MOUNTPOINT/gpg_config $MOUNTPOINT/gpg_config.$(date +%Y-%m-%d).bak
```

<p>
<details>
<summary>Renew the sub keys</summary>

Edit the key:

```bash
$ gpg --edit-key <youremail>
# Ensure that after the boilerplate license it reports "Secret key is available",
# and not "Secret subkeys are available".  The former means you correctly have access
# to the master key/secret, the latter means you're using your exported sub-keys
# (you probably still have your gpg pointing at $HOME/.gnupg; check $GNUPGHOME is set
# per above).
# Select the 3 sub keys (signature, authentication, encryption):

gpg> key 1

pub  4096R/FAEFD83E  created: 2017-08-25  expires: 2023-08-25  usage: C
                     trust: ultimate      validity: ultimate
sub* 4096R/AE86E89B  created: 2017-08-25  expires: 2018-08-25  usage: E
sub  4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
sub  4096R/DE86E396  created: 2017-08-25  expires: 2018-08-25  usage: A

gpg> key 2

pub  4096R/FAEFD83E  created: 2017-08-25  expires: 2023-08-25  usage: C
                     trust: ultimate      validity: ultimate
sub* 4096R/AE86E89B  created: 2017-08-25  expires: 2018-08-25  usage: E
sub* 4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
sub  4096R/DE86E396  created: 2017-08-25  expires: 2018-08-25  usage: A

gpg> key 3

pub  4096R/FAEFD83E  created: 2017-08-25  expires: 2023-08-25  usage: C
                     trust: ultimate      validity: ultimate
sub* 4096R/AE86E89B  created: 2017-08-25  expires: 2018-08-25  usage: E
sub* 4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
sub* 4096R/DE86E396  created: 2017-08-25  expires: 2018-08-25  usage: A
# You should see an asterisk appear next to a sub key  after each `key` command,
# and have 3 of them starred at the end.
# Update the expiry key with the (distressingly named) `expire` command:

gpg> expire
Are you sure you want to change the expiration time for multiple subkeys? (y/N) y
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 13m
# Enter how long the keys should be valid for *from now*; typically use 12-13 months (12m or 13m),
# aiming for ~1 year past the previous expiry but taking care to avoid creeping forward or
# backward into common annual holiday periods in your country.
Key expires at Sun Aug  25 01:21:41 2019 CST
Is this correct? (y/N) y
# Verify the expiry date is what you expect, and if so, type 'y'

pub  4096R/FAEFD83E  created: 2017-08-25  expires: 2023-08-25  usage: C
                     trust: ultimate      validity: ultimate
sub* 4096R/AE86E89B  created: 2017-08-25  expires: 2019-08-25  usage: E
sub* 4096R/79BF274F  created: 2017-08-25  expires: 2019-08-25  usage: S
sub* 4096R/DE86E396  created: 2017-08-25  expires: 2019-08-25  usage: A
# save and exit
gpg> save
gpg> quit
```

Export the updated key information:

```
gpg --armor --export FAEFD83E > $MOUNTPOINT/gpg_config/FAEFD83E.asc
```

From a fresh terminal (using your normal ~/.gnupg GPG directory:

```
gpg --import $MOUNTPOINT/gpg_config/FAEFD83E.asc
```

Unmount your encrypted volume, re-copy the image file to your external safe storage (e.g. USB flash drive)

</details>
</p>

## Troubleshooting

### GPG cannot find the Yubikey

This problem can manifest itself in a few ways:

* Pinentry asking you to insert a SmartCard when it is already inserted
* GPG failing to encrypt or sign messages
* SSH failing to authenticate
* No SSH keys visible with `ssh-add -l`

The solution is to "kick" gpg-agent into checking for a SmartCard by running
`gpg --card-status`.

If you run gpg --card-status with the YubiKey plugged in and GPG does not detect the YubiKey, try the steps below:

* Specify the smart card reader GPG uses by adding the line `reader-port Yubico Yubi` to the scdaemon.conf file; create the file if it does not exist. After making this change, reboot your computer to ensure it takes affect.
  * On macOS and Linux it is at: ~/.gnupg/scdaemon.conf
  * On macOS or Linux, you may need to add "reader-port Yubico Yubikey" (with a lowercase K) instead of what is above if you are using a YubiKey 4 Series or NEO

### ssh connections hang

add `disable-ccid` to `~/.gnupg/scdaemon.conf` and use the restart script to restart `gpg-agent` (which manages scdaemon)

### Unable to sign commits with backup YubiKey

If you have configured subkeys on a second, backup YubiKey, you must append a `!` after the `keyid` specified for the `user.signingkey` config attribute in `~/.gitconfig`, before git will use the new signing key. Otherwise git will continue to prompt for the last written YubiKey, regardless of which `keyid` is specified. For additional context, see [this github issue comment](https://github.com/drduh/YubiKey-Guide/issues/19#issuecomment-1143557632).

## Cleanup

* Unmount the encrypted GPG master volume. Linux: `sudo veracrypt -d
  ~/gitlab_secrets`. Macos: `umount /Volume/Gitlab`.
* Ensure that the backing file for the GPG master volume is backed up, e.g. copy
  it to a USB drive.
* If you have anything that starts up the `gpg-agent`, ensure the options reflect
  the work we've accomplished above

## Linux tips

### gpg: selecting openpgp failed: No such device

On recent Ubuntu/Mint releases (18.04+), GPG has a lot of quality-of-life enhancements, which have just bit you in the butt.   When you run gpg with a 'new' GNUPGHOME value, a dir is created in /run/user/<uid>/gnupg/, based in what looks to be a hash of the value of GNUPGHOME, and agents stated (gpg-agent, scdaemon, at least) with sockets in that directory, so there can be multiple running at once.  You've got this message because the scdaemon that you're accessing (via its socket) is not the one that has ownership of the Yubikey right now.  You can release the other one by executing

```bash
gpg-connect-agent "SCD KILLSCD" "SCD BYE" /bye
```

with GNUPGHOME set to the path of the instance that currently owns the card that you want to go away.  A simple 'kill' will not cause scdaemon to exit, and this is nicer than doing a kill -9.  You could also just kill (SIGTERM) the gpg-agent for the undesired GNUPGHOME, which will close all the things down for that config.

**Note** GPG does *not* normalize the value of $GNUPGHOME to a path, so /media/Gitlab/gpg_config is not the same as /media/Gitlab//gpg_config (two slashes) and each will have its own directory and set of agents/sockets.  This is lightly surprising, and can be very confusing.

### Linux Mint (GTK2) + Pinentry

Noted on Mint 19 Mate edition, because it's GTK2 and the default pinentry install was for GNOME3, but may apply elsewhere:

```bash
sudo apt install pinentry-gtk2
sudo update-alternatives --set pinentry /usr/bin/pinentry-gtk-2
```

Otherwise it falls back to curses, and picks whichever terminal/PTY it thinks is right (probably where you last tickled gpg-agent from), which is usually horribly wrong or dead.   It is also possible to explicitly call the binary as pinentry-program in gpg-agent.conf, but update-alternatives is a bit more blessed/proper for the Debian ecosystem.

```gpg-connect-agent updatestartuptty /bye```
can help too, but only temporarily (it'll set the TTY to the terminal where this command is run).  You could do this if you like the TTY/curses pin prompt, perhaps in an alias

## Reference Material

* <https://github.com/drduh/YubiKey-Guide#21-install---linux>
* <https://wiki.archlinux.org/index.php/GnuPG>
