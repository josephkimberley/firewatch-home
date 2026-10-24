# Artwork, themes and credits

Updated 24 October 2026.

**Firewatch Home is an unofficial, non-commercial fan project.**

I do not own Firewatch, its original artwork, characters, names or logos, or any other third-party artwork or trademarks included or shown here. All rights to those materials belong to their respective owners. Original Firewatch landscape artwork is credited to **Campo Santo and Olly Moss**. This project is not affiliated with, sponsored by or endorsed by Campo Santo or the other rights holders.

Recolouring, seasonal adaptations and AI upscaling do not transfer ownership of the underlying artwork. This fan-project notice does not grant a licence to use or redistribute third-party materials; their existing rights and licence terms still apply.

The included images are part of the current private development snapshot. Redistribution permission remains unresolved. They are not covered by any future licence selected for the original app code.

## Included collection

The exact currently selected TV files are copied byte-for-byte, including the accepted AI-upscaled and recoloured versions:

- Valley: Autumn and Winter, seven times each.
- Lookout: Autumn and Winter, seven times each, in wide and dedicated close-up views.
- 42 wallpaper files, 28 small menu previews, and three Winter night compositing images/masks.
- Dawn, Morning, Noon, Afternoon, Evening, Dusk and Night. Auto selects among these times.

`themes/inventory.json` records the actual source mapping, dimensions, sizes and SHA-256 hashes. There are six scene/season/framing combinations, shown as four scene cards with a separate Lookout Close-up setting. Ember, Classic and the rejected snowstorm experiment are excluded. Intermediate AI masters and unused alternatives are not bundled.

These are flattened backgrounds, not separated terrain layers; do not advertise true parallax. Keep published dimensions distinct from original image resolution: AI upscaling does not establish native detail or new ownership.

## Sources and adaptations

Valley derives from the official Firewatch website parallax artwork, with local framing, recolouring and generated seasonal adaptations:

- https://www.firewatchgame.com/
- https://www.firewatchgame.com/css/firewatchlaunch.css
- Original parallax images: `https://www.firewatchgame.com/images/parallax/parallax0@2x.png` through `parallax8@2x.png`.

Lookout's source composition was obtained through `Cosmosynth/Firewatch-Clock-Trials`, `sunset-bg.jpg`, and remains Firewatch artwork:

- https://github.com/Cosmosynth/Firewatch-Clock-Trials

The local variations include AI-assisted seasonal/lighting edits and Upscayl NCNN Digital Art 4× enhancement. The runtime exports, rather than every intermediate master, are included. The private development workspace retains generation and processing records; those records have not been copied wholesale because they include local paths. A sanitized per-image provenance history is still release work.

## Fonts and other marks

Barlow Condensed by Jeremy Tribby is included with `src/native/fonts/OFL-Barlow.txt`. It is a separate SIL Open Font License component, not the commercial Verlag font. No Mac system fonts are included.

Brand logos are not yet included in this preparation directory. Their source/version/notices need an inventory before a finished package can ship. The current source still references them; this is not yet an installable release.

## Future community themes

The importer is still to be built. It should validate theme IDs, supported times, dimensions, sizes, hashes and paths; reject traversal and symlinks; install atomically and retain the previous theme on failure. User-supplied themes should keep their own credits and licensing metadata.
