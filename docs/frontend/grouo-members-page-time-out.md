# Group Members Page Time Out

**Table of Contents**

[TOC]

## Overview

It could happen that the Members page times out, fails  to render and returns a `500`. An [investigation](https://gitlab.com/gitlab-org/gitlab/-/issues/459041) revealed that could be linked to the `Is using seat` badge.

## Mitigation

Enable the `avoid_exposing_member_is_using_seat` at the root Namespace level to mitigate the problem.
