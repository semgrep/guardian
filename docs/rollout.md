# Rolling out Semgrep Guardian

This page provides starting templates for rolling out Semgrep Guardian to a
managed fleet. Guardian ships as a plugin for both Claude Code and Cursor.
For Claude Code, rolling it out means pushing managed settings that
automatically add the Guardian marketplace and enable the plugin for every
user, so they don't have to run `/plugin` themselves. Cursor has its own
admin-side mechanism (Team Marketplaces) that doesn't involve managed settings
at all.

The Claude Code side is modeled on the
[Claude Code MDM deployment examples](https://github.com/anthropics/claude-code/tree/main/examples/mdm).
The same managed-settings payload is reused across the Claude, Iru, and Jamf
paths below, just delivered differently (git-committed file, MDM mobileconfig,
or MDM plist). Settings deployed via MDM cannot be overridden by users.

The minimal managed-settings payload looks like this:

```json
{
  "enabledPlugins" : {
    "semgrep@semgrep-marketplace" : true
  },
  "extraKnownMarketplaces" : {
    "semgrep-marketplace" : {
      "autoUpdate" : true,
      "source" : {
        "source" : "github",
        "repo" : "semgrep/guardian"
      }
    }
  }
}
```

For the Iru and Jamf paths, the same payload is provided as a ready-to-upload
property list: [`com.anthropic.claudecode.plist`](com.anthropic.claudecode.plist).

## Platforms

> These are community-maintained templates and may be unsupported or incorrect.
> You are responsible for verifying the configuration before deploying it to a fleet.

| Platform | How to roll out |
|----------|-----------------|
| **Claude** | Commit the above file to `.claude/settings.json` in the repo. Team members are prompted to install Guardian automatically when they trust the project folder, no MDM needed. See Require marketplaces for your team. |
| **Cursor** | Admins on Team/Enterprise plans import Guardian as a Team Marketplace from the Cursor Dashboard. See Cursor Team Marketplaces. |
| **Iru** | Deploy a Custom Profile by uploading the `semgrep-marketplace.mobileconfig` configuration profile. Steps below. |
| **Jamf** | Deploy a Custom Settings payload (preference domain `com.anthropic.claudecode`) via a Configuration Profile. Steps below. |

## Tips

- Test the rollout on a single machine before pushing to the whole fleet.
- After deploying, confirm Guardian loaded by running `/plugin` (it should show as
  installed and enabled) and that the Guardian MCP appears.
- Users still need to log in to Semgrep once Guardian is installed — see the
  login steps in the [README](../README.md).
- Enterprise-managed settings cannot be overridden by users, so the plugin stays
  enabled.

## Iru: step by step

1. Go to **Library > Add Library Item > Custom Profile** and upload the [`semgrep-marketplace.mobileconfig`](semgrep-marketplace.mobileconfig) file.
2. Name the profile `Semgrep Guardian - Managed Settings`.
3. Assign it to your blueprint as you see fit.
4. Save.

## Jamf: step by step

Follow Jamf's guide,
[Deploying Custom Computer Configuration Profiles Using the Application and Custom Settings Payload](https://learn.jamf.com/r/en-US/technical-articles/Deploying_Custom_Computer_Configuration_Profiles_Using_the_Application_and_Custom_Settings_Payload),
using the preference domain `com.anthropic.claudecode` and the provided
[`com.anthropic.claudecode.plist`](com.anthropic.claudecode.plist) as the
uploaded property list.
