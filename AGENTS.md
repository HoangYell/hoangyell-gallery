# HoangYell Gallery Agent Directives

## Modern Web Guidance Standard
- **Native Platform Primitives**: Strictly enforce native browser standards over legacy JavaScript wrappers:
  - Native `<picture>` and `loading="lazy"` with `decoding="async"`.
  - CSS Anchor Positioning (`anchor-name`, `position-anchor`) for lightbox captions and overlays.
  - `@starting-style` and `transition-behavior: allow-discrete` for zero-JS zoom lightbox transitions.
  - Container Queries (`@container`) for gallery cards across arbitrary host container widths.
  - Zero `role="button"` or `tabindex="0"` on non-semantic `div` or `span` elements.
- **Guidance Retrieval**: Run `DISABLE_TELEMETRY=1 npx -y modern-web-guidance search "<query>"` before writing ad-hoc web UI components.
- **Audit Tooling**: Run `DISABLE_TELEMETRY=1 npx -y modern-web-guidance legacy-scan` to audit components.
