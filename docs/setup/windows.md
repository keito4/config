# Windows Setup

Windows-specific setup is intentionally kept out of the root README.

## Native Windows

Use PowerShell from the repository root:

```powershell
pwsh -File .\script\import.ps1
```

Windows PowerShell 5.1 is also supported:

```powershell
powershell -ExecutionPolicy Bypass -File .\script\import.ps1
```

## Disable Individual Steps

Use script options when only part of the setup should run. Check the script help before use:

```powershell
pwsh -File .\script\import.ps1 -Help
```

## Notes

- Prefer WSL2 or DevContainer for repositories that use Linux-first tooling.
- Keep machine-specific values outside git-tracked files.
- Use the root README only as an entrypoint; detailed Windows behavior belongs here.
