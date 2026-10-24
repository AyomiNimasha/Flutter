{{flutter_js}}
{{flutter_build_config}}

// Keep the development preview independent of external renderer CDNs and old
// service-worker caches. All assets are served by the local Docker container.
_flutter.loader.load({
  config: {canvasKitBaseUrl: 'canvaskit/'},
  onEntrypointLoaded: async function (engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    } catch (error) {
      window.pawshotsStartupError(error);
    }
  },
}).catch(window.pawshotsStartupError);
