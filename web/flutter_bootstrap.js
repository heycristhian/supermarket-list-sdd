{{flutter_js}}
{{flutter_build_config}}

// Sem `serviceWorkerSettings`: o service worker do Flutter está obsoleto e,
// desde o 3.41, só desregistra workers existentes, o que removeria o nosso
// web/sw.js (research.md R6). O sw.js é registrado em index.html.
_flutter.loader.load();
