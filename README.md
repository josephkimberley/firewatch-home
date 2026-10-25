# Firewatch Home for webOS

**A quieter home screen for your LG TV.**

[![Valley at Evening — Firewatch Home running on an LG TV](docs/images/valley-evening.jpg)](docs/images/valley-evening.jpg)

*Valley · Evening — captured on the TV.*

Golden valleys, snow-covered forests and a lookout above the trees. Firewatch Home puts your favourite apps and HDMI inputs in front of a landscape that changes with the time of day, with birds, moving stars and subtle tree motion.

**42 wallpapers · Seven times of day · Autumn & winter · Remote-friendly controls**

**[Explore the artwork →](docs/GALLERY.md)** &nbsp; · &nbsp; **[Try the desktop preview](#try-it)** &nbsp; · &nbsp; **[Help test on webOS](docs/COMMUNITY_TESTING.md)**

An unofficial, non-commercial fan project. Original Firewatch artwork belongs to its respective owners; [credits and licence details](#licences-and-fan-project-notice).

## Find your favourite view

| Valley · Morning | Snowy Valley · Dusk |
| --- | --- |
| [![Valley Morning with clock and launcher controls](docs/images/valley-morning.jpg)](docs/images/valley-morning.jpg) | [![Snowy Valley Dusk with clock and launcher controls](docs/images/snowy-valley-dusk.jpg)](docs/images/snowy-valley-dusk.jpg) |
| **Lookout · Afternoon** | **Lookout Close-up · Noon** |
| [![Lookout Afternoon with clock and launcher controls](docs/images/lookout-afternoon.jpg)](docs/images/lookout-afternoon.jpg) | [![Lookout Close-up Noon with clock and launcher controls](docs/images/lookout-close-noon.jpg)](docs/images/lookout-close-noon.jpg) |

Click any image for the full **1920 × 1080** TV capture. These show the personal development installation; the community preview is described below.

Pick a wide valley or a closer view of the lookout. Add snow, choose your favourite light, or let Auto follow the clock. Motion has its own toggle. Your apps and inputs stay within reach without covering the view.

## From dawn to night

One landscape, seven different moods. Each image below stitches together slices from the TV captures, from the first light of dawn to night. Select a favourite time or use Auto; these panoramas show the available looks, not a continuous animated transition.

**Left → right: Dawn · Morning · Noon · Afternoon · Evening · Dusk · Night**

**Valley**

[![Valley panorama progressing from Dawn at the left to Night at the right](docs/images/valley-day-to-night.png)](docs/images/valley-day-to-night.png)

**Snowy Valley**

[![Snowy Valley panorama progressing from Dawn at the left to Night at the right](docs/images/snowy-valley-day-to-night.png)](docs/images/snowy-valley-day-to-night.png)

**Lookout**

[![Lookout panorama progressing from Dawn at the left to Night at the right](docs/images/lookout-day-to-night.png)](docs/images/lookout-day-to-night.png)

**Snowy Lookout**

[![Snowy Lookout panorama progressing from Dawn at the left to Night at the right](docs/images/snowy-lookout-day-to-night.png)](docs/images/snowy-lookout-day-to-night.png)

**Lookout Close-up**

[![Lookout Close-up panorama progressing from Dawn at the left to Night at the right](docs/images/lookout-close-day-to-night.png)](docs/images/lookout-close-day-to-night.png)

## Try it

> **Experimental community preview · 3.1.0.** The community package is locally tested but not yet validated on a fresh TV. It installs as a standalone app. Automatic Home replacement, startup optimisation and screensaver integration are not included.

**Curious? Start on your computer.** The desktop preview runs the real setup controls in a normal window, using simulated apps and a static wallpaper. It never connects to a TV. Use arrows, Enter and Escape to try it like a remote.

**[Launch the desktop preview →](preview/README.md)**

**Have a rooted test TV?** Follow the build and app-only installation guide, then share what works on your model. There is no ready-made release download yet. The installer refuses to overwrite an existing Firewatch/Minimal Home installation.

**[Build & installation guide](docs/GETTING_STARTED.md)** · **[Testing checklist](docs/COMMUNITY_TESTING.md)** · **[Report your results](https://github.com/josephkimberley/firewatch-home/issues/new?template=preview-report.yml)**

## Make it yours

Choose apps from the installed-app list, put your favourites first, rename HDMI inputs and hide the ones you do not use. Save from the remote. No source edits or AI subscription are needed to use the setup panel.

[![Apps and Inputs editor in the desktop mock](docs/images/community-setup.png)](docs/images/community-setup.png)

*The actual setup controls in the desktop mock. App discovery and saves are simulated here; this is not a TV performance demonstration.*

- **Your shortcuts:** up to five apps and four HDMI inputs, in your preferred order.
- **Your clock:** 12- or 24-hour display, with system, UTC or London time; Auto lighting follows the same clock.
- **Your scenery:** Valley, Snowy Valley, Lookout and Snowy Lookout, with close-up options for both Lookout seasons.
- **Simple controls:** Back closes panels. Red or the on-screen LG Home action opens stock Home while the app is active.
- **Bundled artwork:** all 42 wallpapers are included in the built package; no computer needs to serve them to the TV.

[Apps, inputs and clock guide →](docs/CUSTOMIZATION.md)

## Help it reach more TVs

The most useful contribution right now is a clear test result: your model and firmware, the checks you tried, and what worked or failed. Desktop feedback is welcome too. You do not need to use your daily TV to help.

Developers can help with native LG compatibility, reliable updates and recovery, and eventually portable Home/startup integration. The [test record](docs/TESTING.md) separates what has been simulated from what still needs hardware validation.

**[Send a test report](https://github.com/josephkimberley/firewatch-home/issues/new?template=preview-report.yml)** · **[See remaining work](RELEASE.md)** · **[Portability notes](docs/PORTABILITY.md)**

## Hardware and speed

The development TV is an LG OLED48C24LA, webOS 24 / 9.2.2-61, firmware 23.25.55. The owner reported approximately five seconds from Power to forest with Quick Start+ off after the startup fixes. **That result is from the personal installation, not this standalone community package.** The startup fixes are not included here, and no community cold-boot speed is claimed. Native LG modules and any future rooted integration require explicit compatibility handling.

<details>
<summary><strong>For developers: source layout, build and local checks</strong></summary>

### Source layout

- `src/native/`: current QML, shaders, fonts and approved theme files.
- `src/launcher.c`: native entry point; `tools/build.mjs` builds and packages it.
- `config/default.json`, `tools/config.mjs`, `tests/`: runtime configuration contract and offline tests.
- `themes/inventory.json`: exact image paths, dimensions, sizes, hashes and rights status.
- `SOURCE-MANIFEST.json`: community source/font hashes.
- `preview/`: desktop setup mock and navigation tests.
- `tools/install_app.py`: dry-run/read-only/app-only candidate installation.
- `docs/`: architecture, customization, artwork and recovery requirements.

### Local checks

Node.js 20 or newer, no external dependencies:

```sh
node --test tests/*.test.mjs
node tools/config.mjs config/default.json
```

These commands do not contact or modify a TV. Optional app-only installation is documented in [Getting started](docs/GETTING_STARTED.md); fresh-TV compatibility, upgrades and complete uninstall remain unverified. See the [testing checklist](docs/COMMUNITY_TESTING.md) before volunteering.

[Build details](docs/BUILD.md) · [Recovery](docs/RECOVERY.md) · [Optional Codex / Claude prompts](docs/AI_ASSISTED_SETUP.md) · [Upstream ideas and credits](docs/UPSTREAM_IDEAS.md)

</details>

## Licences and fan-project notice

**Firewatch Home is an unofficial, non-commercial fan project.**

I do not own Firewatch, its original artwork, characters, names or logos, or any other third-party artwork or trademarks included or shown here. All rights to those materials belong to their respective owners. Original Firewatch landscape artwork is credited to **Campo Santo and Olly Moss**. This project is not affiliated with, sponsored by or endorsed by Campo Santo or the other rights holders.

Recolouring, seasonal adaptations and AI upscaling do not transfer ownership of the underlying artwork. This fan-project notice does not grant a licence to use or redistribute third-party materials; their existing rights and licence terms still apply.

Credits, sources and adaptations are documented in [ARTWORK.md](docs/ARTWORK.md). Artwork redistribution permission remains unresolved. No project-wide licence has yet been selected for the original app code; any future code licence will exclude third-party artwork and trademarks. Bundled third-party components, including the Barlow font, retain their own licence notices.
