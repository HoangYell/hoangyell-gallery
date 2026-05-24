# @hoangyell/gallery

Astro image gallery with lightbox, pyramid multi-row layout, and accessible controls.

Published as [`@hoangyell/gallery`](https://www.npmjs.com/package/@hoangyell/gallery) on npm.

## Quick start

```sh
pnpm add @hoangyell/gallery
```

```astro
---
import { Gallery } from "@hoangyell/gallery";
---

<Gallery items={["/a.jpg", "/b.jpg", "/c.jpg"]} rows={2} />
```

## Development

```sh
pnpm install
pnpm dev          # demo app at http://localhost:4325
pnpm typecheck
pnpm pack:check
```

## Release

```sh
pnpm run release 1.0.0
```

Requires `NPM_TOKEN` in GitHub Actions secrets for automated publish on tag push.

## License

MIT © [Hoang Yell](https://hoangyell.com)
