self.addEventListener('install', e => {
  e.waitUntil(
    caches.open('sensei-timer-v1').then(c => c.addAll(['/display.html', '/manifest-display.json']))
  );
});

self.addEventListener('fetch', e => {
  e.respondWith(
    caches.match(e.request).then(r => r || fetch(e.request))
  );
});
