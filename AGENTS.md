# WebView2.au3 project instructions

## AutoIt3 global rules

When working on AutoIt source files, read and apply `AGENTS_AutoIt3_rules.md` in addition to the applicable `AGENTS.md`. The main `AGENTS.md` defines the permitted scope and takes precedence if instructions conflict.

This section is reserved for the [GitHub project](https://github.com/mlipok/AutoIt3-AGENTS.md) that maintains the shared rule set. Do not modify it in projects that use these rules. If a project needs its own AutoIt requirements, add them under a separate `## AutoIt3 specific rules` section in that project's `AGENTS.md`.

## Scope

These instructions apply to this directory and all of its subdirectories.

This repository contains a native Microsoft Edge WebView2 UDF for AutoIt. Preserve the public API unless a task explicitly requests a breaking change.

## Project layout

- `WebView2.au3` is the public include entry point.
- The implementation and interface `.au3` files live beside the public `WebView2.au3` entry point in the project root.
- `examples/` contains numbered usage examples.
- `bin/x86/` and `bin/x64/` contain architecture-specific `WebView2Loader.dll` files.
- `tools/Validate-Project.ps1` performs the repository's static validation.
- `VERSION`, `CHANGELOG.md`, and `RELEASE_NOTES.md` describe releases.

## Project language

- English is the working language of this project. Write and maintain project-owned documentation, code comments and function headers, example code, sample HTML/JavaScript/CSS, user-facing text, and release notes in English.
- Preserve public API names, protocol identifiers, paths, upstream names, third-party sources and licenses, and deliberate non-English Unicode test data. Explain such test data in English.
- When editing a project resource, review its project-owned text for consistency with this rule. Keep test semantics unchanged; update expected text together with a user-facing label when needed.

## Creating and maintaining examples

- Give each runnable example a three-digit number. Preserve the existing number and filename of an established example; choose the next suitable unused number for a new one. Keep original examples below 200 separate from the attributed 200–221 adaptations.
- Make an example a self-contained mini project: keep its AutoIt entry point, sample page and other local assets together. Include this project's public `WebView2.au3` entry point and standard AutoIt UDFs directly. Do not introduce a shared, monolithic example-support module.
- Use deterministic public sample data. Do not include private program names, production integration paths, credentials or persistent changes to external services. Keep third-party notices, source links, author and modifier credits with adapted examples; distinguish copied behavior from later local changes.
- Open a main interactive example window maximized inside the Windows work area, with its title bar, minimize control and taskbar visible. Preserve the purpose and appropriate size of modal dialogs. Position controls and WebView2 from the actual client size at startup and on resize, maximize and restore; do not rely only on an event that may have fired before the message loop started.
- Where an interaction needs several steps or observable native events, show the AutoIt operation log beside WebView2 and a yellow guide below it. Append time-stamped log entries in chronological order and scroll to the newest entry. State the exact controls to use, expected results, and how the demonstrated WebView2 feature works. Keep the guide and WebView2 content visible without overlap at supported window sizes. Simpler focused examples may retain their existing layout when three panels would obscure the feature.
- Keep example-specific WebView2 profiles separate from one another and away from the portable AutoIt executable directory. For local web assets, prefer the UDF's virtual HTTPS host mapping and the established `https://udf-virtual-host.example/` host with a separate profile for each example. State explicitly when a test requires Internet access.
- Preserve existing `--smoke` modes and make new ones deterministic, bounded and noninteractive. Validate each changed AutoIt file with the required Tidy and Au3Check procedure, then run focused smoke or manual tests only for behavior changed by the task. Record static, x86, x64 and visible GUI results separately; do not present compilation or syntax checks as proof of WebView2 behavior.
- Update `docs/EXAMPLES.md` when adding an example or changing its usage, assets, status or verified behavior. Update `CHANGELOG.md` for user-visible example changes, `STATIC_VALIDATION.txt` with actual check results, and `CONTRIBUTING.md` when contributor guidance changes. Keep `#WIP - Work in Progress` and an honest limitation note until the example's key behavior is confirmed in a running WebView2 session.

## Implementation rules

- Keep compatibility with AutoIt 3.3.18.0 or newer.
- Preserve existing public function names, parameter order, default values, return values, and `@error`/`@extended` behavior unless the task says otherwise.
- Select the native loader architecture from `@AutoItX64`: x64 AutoIt must use the x64 loader and x86 AutoIt must use the x86 loader.
- Loader discovery must support an explicit DLL path, an explicit directory, the calling script directory, and paths relative to the UDF/include location and repository layout.
- Loader errors must identify the selected architecture and list every path that was checked.
- Do not silently load a DLL for the wrong architecture.
- Keep internal helpers prefixed with `__WebView2_` and public functions prefixed with `_WebView2_`.
- Follow the existing AutoIt formatting and function-header style in the file being edited.
- In this project, refer to standard AutoIt UDFs as needed. Mention other UDFs only as sources of inspiration or in documentation explicitly dedicated to API comparison or mapping. Do not present this UDF as subordinate to another UDF.
- Do not replace or download bundled third-party binaries unless the task explicitly requires it.

## Public repository content

- Keep this repository self-contained for public distribution. Do not include private application names, integration call chains, machine-specific paths, or local editor indexes.

## Documentation and releases

- Update relevant documentation when user-visible behavior changes.
- Keep version declarations in `WebView2.au3`, source headers, and `VERSION` consistent when preparing a release.
- Record release changes in `CHANGELOG.md` and `RELEASE_NOTES.md` when a new version is requested.
- A release ZIP must use a GitHub-style top-level directory named `WebView2.au3-<version>` and exclude local metadata, temporary files, and previous archives.

## Validation

- Run `tools/Validate-Project.ps1` after source or packaging changes.
- Perform static checks for both x86 and x64 loader paths.
- When AutoIt or Au3Check is available, run the relevant syntax check and smoke tests.
- If a required tool is unavailable, report that limitation and still run all remaining checks.
- Do not report runtime x86/x64 behavior as verified unless it was actually executed under both AutoIt architectures.

## Working-copy safety

- Preserve unrelated user changes.
- Inspect working-copy status before editing when an SVN client is available.
- Do not revert, delete, or overwrite unrelated files.
