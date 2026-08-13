self.addEventListener('install', function (event) {
  self.skipWaiting();
});

function isSixAppFlutterCacheName(cacheName) {
  return cacheName === 'flutter-app-cache' ||
    cacheName === 'flutter-temp-cache' ||
    cacheName === 'flutter-app-manifest' ||
    cacheName.indexOf('flutter-app-cache-') === 0 ||
    cacheName.indexOf('flutter-temp-cache-') === 0 ||
    cacheName.indexOf('flutter-app-manifest-') === 0;
}

async function cacheLooksLikeSixAppFlutter(cacheName) {
  try {
    var cache = await caches.open(cacheName);
    var requests = await cache.keys();
    return requests.some(function (request) {
      var url = new URL(request.url);
      return url.origin === self.location.origin &&
        (
          url.pathname === '/main.dart.js' ||
          url.pathname === '/flutter_bootstrap.js' ||
          url.pathname === '/flutter.js' ||
          url.pathname === '/assets/AssetManifest.bin.json'
        );
    });
  } catch (_) {
    return false;
  }
}

self.addEventListener('activate', function (event) {
  event.waitUntil((async function () {
    var cacheNames = await caches.keys();
    var cacheNamesToDelete = [];
    for (var i = 0; i < cacheNames.length; i += 1) {
      var cacheName = cacheNames[i];
      if (isSixAppFlutterCacheName(cacheName) &&
          await cacheLooksLikeSixAppFlutter(cacheName)) {
        cacheNamesToDelete.push(cacheName);
      }
    }
    await Promise.all(cacheNamesToDelete.map(function (cacheName) {
      return caches.delete(cacheName);
    }));
    await self.registration.unregister();
    await self.clients.claim();
  })());
});
