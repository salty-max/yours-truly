# Yours Truly artwork

Generated with the built-in image_gen tool on 23 October 2026, matching the
family's painted inventory-item style. The exact prompt and consulted style
references are in [logo-prompts.json](logo-prompts.json).

- `logo-master.png`: original generated master, 1254px square.
- `logo-1024.png`: 1024px square for store and project artwork.
- `logo.png`: 512px square for general use.
- `seal.png`, `../addon/YoursTruly/Media/Seal.tga`: the logo's wax seal
  cut round from the master (centre 498, 504 and radius 152 of 1024, a soft
  round edge), 128px, the TGA uncompressed 32-bit with a top-left origin as
  Logo.tga: a sealed letter's seal on its envelope and in the book.
- `../addon/YoursTruly/Media/Logo.tga`: uncompressed 256px RGBA game texture,
  with rounded corners (radius 34), used by the addon listing and `ns.ICON`.

The PNGs keep the opaque navy square. Resize from the master for future
exports. ImageMagick produces the smaller files and the game texture.
The TGA mask is a white `roundrectangle 0,0 255,255 34,34` on black.
Disable the mask's alpha before compositing with CopyOpacity, so its
grayscale values supply the opacity. Verify transparent corners and an
opaque centre after exporting.

The mark is a parchment envelope with red feather-stamped wax and an ivory
quill. The separate open-letter icon still distinguishes letters already read.
