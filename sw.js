/* ═══════════════════════════════════════════════════════════════
   Service Worker — Конструктор Гарипова
   Стратегия: network-first (как в NeuroCatch).
   ВАЖНО: версию кэша бампать ТОЛЬКО при явном коммите/выкладке —
   не менять автоматически, не менять "на всякий случай".
   ═══════════════════════════════════════════════════════════════ */
const CACHE_VERSION = 'garipov-v1';
const PRECACHE_URLS = [
  './',
  './index.html',
  './manifest.json'
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_VERSION).then(cache => cache.addAll(PRECACHE_URLS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_VERSION).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Network-first: свежая сеть в приоритете, кэш — только офлайн-фолбэк.
self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    fetch(e.request)
      .then(resp => {
        const copy = resp.clone();
        caches.open(CACHE_VERSION).then(cache => cache.put(e.request, copy));
        return resp;
      })
      .catch(() => caches.match(e.request).then(m => m || caches.match('./index.html')))
  );
});
