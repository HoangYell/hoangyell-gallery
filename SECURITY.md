# Security Policy

## Supported Versions

The latest minor release of `@hoangyell/gallery` is supported with security
updates.

| Version | Supported |
| ------- | --------- |
| 1.x     | Yes       |
| < 1.0   | No        |

## Reporting a Vulnerability

If you discover a security issue, please **do not** open a public GitHub
issue. Instead, email **hoangyell@gmail.com** with:

- a clear description of the issue,
- steps to reproduce,
- any proof-of-concept code or screenshots,
- your suggested fix (optional).

You can expect an acknowledgement within **5 business days**. We will work
with you to verify the issue, prepare a fix, and coordinate disclosure.

## Scope

In scope:

- The `@hoangyell/gallery` npm package source (`packages/astro/src/**`).
- The published lightbox runtime that ships with the package.

Out of scope:

- Vulnerabilities in user-provided image URLs or third-party CDNs.
- Vulnerabilities in the demo `examples/astro-basic` app, which is for
  documentation only and not published.

## Security Best Practices for Consumers

- Pin the package version in `package.json` and audit upgrades.
- Serve user-controlled image URLs through a trusted CDN.
- The lightbox renders `alt` text verbatim — sanitize untrusted alt text
  upstream before passing it to `<Gallery />`.
