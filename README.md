# Semgrep Guardian: Claude Code Plugin

Installation instructions:

1. Start a Claude Code instance by running:
    ```
    claude
    ```
1. Add the Semgrep marketplace by running the following command in Claude:
    ```
    /plugin marketplace add semgrep/guardian
    ```
1. Install the plugin from the marketplace:
    ```
    /plugin install semgrep@semgrep-marketplace
    ```
1. Tell claude to load the plugin:
    ```
    /reload-plugins
    ```
1. Ask claude to login to semgrep, using the guardian mcp
    ```
    login to semgrep
    ```

    This should call into the MCP, but if claude is having trouble,
    call `/clear` to restart claude, or exit and reopen claude manually.

## Rolling out Guardian across your team

For specific guidance to roll out Semgrep Guardian via an MDM or via your
agent's built-in enterprise security controls, view this detailed documentation
to help your security team enforce the standardization of Guardian across all
their developers. For more details, this is how you roll it out:
[Rolling out Semgrep Guardian](docs/rollout.md).

