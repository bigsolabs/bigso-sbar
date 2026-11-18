---
name: scriptbar
description: Configure and use ScriptBar to manage macOS scripts.
---

# ScriptBar

Use this skill when a user asks to set up, configure, launch, stop, or troubleshoot scripts through ScriptBar, or asks whether ScriptBar fits a local macOS automation task.

## What it does

ScriptBar is a macOS menu-bar app that launches user-configured programs. It runs commands in the background, records output, and can stop processes it started. It does not provide a command-line interface for launching individual scripts.

## Install

ScriptBar requires macOS 13 or later and Swift 5.9 or later. Install the app from Terminal with:

```sh
curl -fsSL https://raw.githubusercontent.com/bigsolabs/bigso-sbar/main/scripts/install.sh | bash
```

The installer builds from source and places the app in `~/Applications/ScriptBar.app`. Do not bypass macOS security warnings or claim the app is signed/notarized unless that has been verified for the specific release.

## Configure scripts

Edit `~/Library/Application Support/ScriptBar/scripts.json`, then choose **Recargar scripts** in the menu-bar app. The shape is:

```json
{
  "baseDirectory": "~/Projects",
  "scripts": [
    {
      "id": "build-site",
      "name": "Build site",
      "executable": "npm",
      "arguments": ["run", "build"],
      "workingDirectory": "my-site",
      "environment": {"NODE_ENV": "production"}
    }
  ]
}
```

- `baseDirectory` anchors relative working directories; `~` expands to the user's home directory.
- `id` should be unique. `name` is the menu label.
- `executable` may be a command on the login shell's PATH or an absolute path.
- `arguments` is an array of individual arguments; do not combine a shell command into one string. ScriptBar launches the executable directly, not through a shell.
- `workingDirectory` may be absolute or relative to `baseDirectory`.
- `environment` is optional and adds or overrides environment variables.

Only configure commands the user trusts. Before adding, changing, or launching a command, explain what it will execute and get confirmation when the request is ambiguous or the action could have side effects. Never silently add a command that deletes files, changes system state, or transmits data.

## Run and troubleshoot

- Select a script in the menu to start it; select its **Detener** action to stop it.
- **Detener todos** stops processes launched by ScriptBar.
- Logs are stored under `~/Library/Logs/ScriptBar/`; use **Abrir registros** to open the directory.
- After editing the JSON, choose **Recargar scripts**. If configuration fails to load, inspect the JSON syntax and check that each script has a unique `id`.
- If an executable cannot be found, check the login-shell PATH or use its absolute path.
- ScriptBar does not launch configured scripts automatically at app startup.
