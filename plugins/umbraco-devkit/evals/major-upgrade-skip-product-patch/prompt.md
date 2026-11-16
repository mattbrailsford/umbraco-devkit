---
description: A patch bump of another Umbraco product on the same major should not load major-upgrade.
tags: [major-upgrade, should-not-trigger]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

Umbraco Deploy 18.1.3 is out with a fix for a schema comparison bug. Our Deploy connector
package references `Umbraco.Deploy.Infrastructure` `[18.1.0, 19.0.0)`. Do we need to change
anything to pick it up? One or two sentences.
