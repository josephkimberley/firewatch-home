# Setup ideas studied

Reviewed 24 October 2026. These are design influences; this change does not incorporate either project's executable source or rooting payload.

## CleanYourTV for webOS

[Project](https://github.com/lasharor/cleanyourtv-WebOS) · [Installer](https://github.com/lasharor/cleanyourtv-WebOS/blob/main/install.sh) · [Licence](https://github.com/lasharor/cleanyourtv-WebOS/blob/main/LICENSE)

Its manager separates installing an app from enabling Home replacement, and presents setup/update/removal on the TV. Its installer checks downloads and verifies registration. Those are useful patterns for Firewatch Home: a small setup editor, explicit prerequisites, checksummed packaging and a separate integration step.

The community implementation is original and currently app-only. It does not import CleanYourTV's takeover, debloat, voice or live-TV features. The reviewed upstream licence is MIT; any future source reuse needs the associated notice and provenance recorded.

## Slopbro

[Project and testing modes](https://github.com/throwaway96/slopbro) · [Licence](https://github.com/throwaway96/slopbro/blob/main/COPYING)

Slopbro is primarily a rooting tool, not a replacement home screen. Its low-dependency command-line packaging and test modes that avoid TV interaction informed our approach: Python standard-library packaging/install checks, explicit dry runs, local fixtures and a mock UI.

No exploit, autoroot script or source from Slopbro is bundled. Its AGPL licence is recorded here to avoid treating an upstream source file as freely interchangeable with our independent implementation.

## Boundaries

Neither project proves that Firewatch Home's native renderer, permissions or startup hooks will work on another TV. The mock tests exercise our code paths; hardware compatibility remains a separate test gate. These references are evidence about upstream designs, not installation instructions for this app.
