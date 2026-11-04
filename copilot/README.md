# Semgrep Guardian: GitHub Copilot Plugin

Pre Release: Not Public

This is an [Agent Plugins 1.0](https://github.com/agentplugins/agent-plugins-spec/blob/main/spec/1.0.0.md)
plugin for GitHub Copilot CLI.

    plugin.json                           manifest
    mcp.json                              the guardian MCP server
    com.github.copilot/hooks/hooks.json   Copilot's hooks, with bash and powershell commands
    scripts/                              the hook launchers and binaries

Other Agent Plugins clients ignore `com.github.copilot/`, so only Copilot runs the hooks.

## Install

    copilot plugin marketplace add semgrep/guardian
    copilot plugin install guardian-copilot@semgrep-marketplace

For Semgrep's internal canary, add `semgrep/guardian-canary` as the marketplace instead.

Then start a new `copilot` session. `copilot plugin list` shows `guardian-copilot`.

## Update

    copilot plugin marketplace update semgrep-marketplace
    copilot plugin update guardian-copilot@semgrep-marketplace

## Trying a development build

From the repository root, after `make`:

    copilot --plugin-dir build/guardian-copilot        # this session only; nothing is installed
    copilot plugin install ./build/guardian-copilot    # installs it for every session

Copilot warns that direct installs from a local path, repository or URL are deprecated, and that
only `plugin@marketplace` installs will be supported in a future release.
