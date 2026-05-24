# @hoangyell/gallery

[Astro](https://astro.build/) image gallery component with lightbox, pyramid multi-row layout, and accessible controls.

<p align="center">
  <img
    src="https://raw.githubusercontent.com/HoangYell/hoangyell-gallery/main/packages/astro/docs/gallery-overview.jpg"
    alt="Three @hoangyell/gallery layouts: single image, 2-row pyramid of 4 images, and 3-row layout of 8 images"
    width="640"
  />
</p>

<p align="center">
  <em>Click any image to open the lightbox — keyboard arrows, swipe, ESC to close.</em>
  <br />
  <img
    src="https://raw.githubusercontent.com/HoangYell/hoangyell-gallery/main/packages/astro/docs/gallery-lightbox.jpg"
    alt="Lightbox view with 1/4 page indicator, close button, and next-image arrow"
    width="640"
  />
</p>

## Features

- **Pyramid layout** — distribute images across rows with `rows` prop
- **Lightbox** — click to open, keyboard arrows, swipe, ESC to close
- **Corner rounding** — only the four outer corners of each group are rounded
- **Hover zoom** — image scales inside its cell without changing layout
- **Accessible** — focus management, ARIA labels, safe-area controls, reduced-motion support
- **Zero config** — plain CSS, no Tailwind required in the host project

## Installation

```sh
pnpm add @hoangyell/gallery
```

## Usage

```astro
---
import { Gallery } from "@hoangyell/gallery";

const photos = [
  "/img/one.jpg",
  "/img/two.jpg",
  "/img/three.jpg",
];
---

<Gallery items={photos} rows={2} />
```

### In MDX

```mdx
import { Gallery } from "@hoangyell/gallery";

<Gallery
  items={[
    "https://example.com/a.webp",
    "https://example.com/b.webp",
    { src: "https://example.com/c.webp", alt: "Temple gate", fit: "cover" },
  ]}
  rows={3}
/>
```

## Props

| Prop | Type | Default | Description |
|---|---|---|---|
| `items` | `(string \| { src, alt?, fit? })[]` | `[]` | Image URLs or objects |
| `alts` | `string[]` | — | Alt text paired with string URLs |
| `rows` | `number` | auto (~3 per row) | Number of visual rows |
| `orientation` | `"landscape" \| "portrait"` | `"landscape"` | Item aspect ratio hint |
| `scale` | `number` | `1` | Gallery width scale (0–1) |
| `fit` | `ObjectFit` | `"cover"` | Default CSS object-fit |
| `class` | `string` | — | Extra wrapper class |

## Dark mode

The component auto-themes via three mechanisms (last one wins):

1. `prefers-color-scheme: dark` — OS preference (default).
2. `<html class="dark">` or `<html data-theme="dark">` — Tailwind-style class toggle.
3. `<html class="light">` or `<html data-theme="light">` — explicit light theme override.

This means it Just Works™ with manual theme toggles **and** OS preference.

## Customization

Override CSS custom properties on `.hy-gallery`:

```css
.hy-gallery {
  --hy-gallery-gap: 6px;
  --hy-gallery-radius: 12px;
  --hy-gallery-accent: #e11d48;
}
```

| Variable | Default | Purpose |
|---|---|---|
| `--hy-gallery-gap` | `4px` | Grid gap between cells |
| `--hy-gallery-radius` | `1rem` | Outer corner radius |
| `--hy-gallery-bg` | `#f8fafc` | Item placeholder background |
| `--hy-gallery-overlay-bg` | `rgba(255,255,255,0.7)` | Lightbox backdrop |
| `--hy-gallery-accent` | `#2563eb` | Focus ring and hover accent |

## License

[MIT](../../LICENSE)
