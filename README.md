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

