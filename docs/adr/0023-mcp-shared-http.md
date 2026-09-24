# 0023: MCP servers use HTTP where available

Status: Accepted

Each stdio MCP connection starts a child process. Concurrent Codex and Claude
sessions therefore retain many copies of identical server runtimes.

Context7 uses its official HTTP endpoint. Host-local opt-in sharing of fixed-scope
backends is managed by private-config's `mcp-shared` LaunchAgent. Its authenticated
URLs use `http://127.0.0.1:47932/servers/`; credentials stay in local config files.
Other Macs continue using the shared repository's stdio definitions until opted in.

Config import must not combine HTTP and stdio transport fields. A base HTTP entry
removes stale stdio fields. A base stdio entry normally removes stale HTTP fields,
except an opted-in local mcp-shared URL, which remains HTTP. Non-transport settings
still merge normally. Rollback the local mcp-shared migration to restore stdio.

Session-dependent browser and password-manager backends are excluded from sharing.
