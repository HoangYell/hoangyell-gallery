import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  site: "https://gallery.hoangyell.com",
  output: "static",
  trailingSlash: "ignore",
  build: {
    // Inline CSS into HTML for a render-blocking-free first paint.
    inlineStylesheets: "always",
  },
  vite: {
    plugins: [tailwindcss()],
  },
});
