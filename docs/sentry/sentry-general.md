# Sentry general tasks

**Table of Contents**

[TOC]

**It is assumed that you have _Owner_, _Manager_ or _Admin_ access in Sentry. If you don't, ask someone who does have that access to grant it to you.**

## How to send dummy events to Sentry

This is helpful to verify that events are actually getting received and processed by Sentry.

1. You will need the [`sentry-cli`](https://docs.sentry.io/product/cli/installation/) installed.
    * On MacOS you can install it via Homebrew: `brew install getsentry/tools/sentry-cli`
1. If needed, create a test project so that your dummy event doesn't pollute an actual project.
1. Get the DSN of the project you want to send events to:
    1. Go to **Project Settings** (cog button in the upper right of the project screen)
    1. Under **SDK Setup**, click on **Client Keys (DSN)**
    1. Copy the DSN, which should be of the format `https://<long hash string>@new-sentry.gitlab.net/<project number>`
1. Run the following command, substituting the DSN: ``SENTRY_DSN='<your DSN here>' sentry-cli send-event -m "This is a test event from sentry-cli"`
    * Write whatever you want in the message, but make it distinct from the other things in the project so you can find it easily.
