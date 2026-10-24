# Working with Codex or Claude

[Running the project](GETTING_STARTED.md) · [Customisation](CUSTOMIZATION.md) · [Release plan](PORTABILITY.md)

**This is an AI-assisted development workflow, not an automated installer.** The app runs on the TV; it does not require Codex or Claude to remain running. The current checkout builds a standalone candidate; fresh-TV runtime and update/recovery validation remain outstanding. An assistant must not describe planned features or a successful JSON validation as a working deployment.

Open a local clone in your coding assistant. Keep credentials, TV addresses and private backup material outside the repository. Replace the bracketed details in the prompts below; do not paste private keys into a prompt.

## 1. Assess my TV and this checkout

```text
Read README.md, RELEASE.md, docs/GETTING_STARTED.md, docs/ARCHITECTURE.md,
docs/CUSTOMIZATION.md and docs/RECOVERY.md. Inspect the actual code as well.
My TV is [model], running [webOS version] and [firmware]. My development
computer is [OS]. My existing access is [none / Developer Mode / rooted].

Start with a read-only compatibility assessment. Do not install software,
root the TV, change permissions, remap buttons or modify boot behavior.
Identify missing build/runtime assets and separate observed facts from
assumptions. Explain what can run from this checkout today and what needs
implementing. Do not treat the development TV's five-second result as a
universal promise. If TV inspection is needed, describe the access required.
```

## 2. Prepare my app and HDMI choices

```text
Read docs/CUSTOMIZATION.md and tools/config.mjs. Create local/config.json
from config/default.json using these choices:
Apps, in order: [names and verified installed IDs].
HDMI tiles, in order: [physical port and label for each].
Clock: [timezone], [12h or 24h].

Do not invent app IDs or change HDMI ports to match display order. Ask for
missing IDs or use an authorised read-only installed-app inventory. Run the
offline validator. The build consumes config/default.json as launcher-config.json;
build with --config local/config.json to include my choices without committing them. Make no TV changes.
```

## 3. Test the setup flow locally

```text
Read preview/README.md, then run the production control/editor tests and the
Node/Python suites. Use the desktop mock to test one app, inputs only,
reordered HDMI, discovery denied, failed saves and nested Back. Keep the
approved artwork and animation source intact. Inspect screenshots for clipping
and focus visibility at a smaller window size. Do not connect to a TV.

Report which production components are exercised and which platform services
are mocked. A static desktop background is not evidence of TV shader or boot
performance. Fix failures and provide a small test receipt.
```

## 4. Prepare a reproducible app-only package

```text
Review the native launcher, manifest, imports and asset references. Establish
and run the pinned build from docs/BUILD.md. Do not invent
a build command or package missing executable/icon/logo assets. Do not bundle
LG proprietary binaries or libraries from a TV dump. Record source/toolchain
versions, package checksums and unresolved dependency/licence issues.

Prepare an app-only installation plan and a matching removal plan, preserving
stock LG Home. Show what the package contains and which service permissions
it needs. Stop before installation so I can review the concrete package and
choose a time when the TV is not being watched. Do not include rooting or
system Home/startup modifications in this step.
```

## 5. Plan optional Home/startup integration

```text
The standalone app has been verified on my TV. Review docs/RECOVERY.md and
docs/ARCHITECTURE.md and inspect the exact target firmware before proposing
Home/startup integration. Do not reuse firmware-specific patches blindly.

Prepare a compatibility report, minimal change list, verified backups,
transaction receipt and independent disable/rollback route. Keep stock Home
available. Separate key mapping, startup, cover readiness and screensaver
behavior. Do not change firmware updates, power/CEC settings or system
permissions as hidden side effects. Present the concrete plan for review
before applying system changes; report unsupported cases rather than forcing
them through. Do not promise that a backup can recover every boot failure.
```

## Keep the handover small

For each completed milestone, record the commit, verified behavior, remaining gaps, commands actually tested and any local-only rollback record locations. Start a fresh focused chat at a milestone boundary with that handover and links to these documents. Keep detailed logs on disk and read relevant sections; avoid pasting the entire project history into every request.
