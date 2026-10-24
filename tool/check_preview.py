"""Verify the served Flutter bundle and SQLite worker assets."""
import urllib.request


def check_preview(base="http://127.0.0.1:8080"):
    for resource in ("/", "/flutter_bootstrap.js", "/main.dart.js",
                     "/canvaskit/canvaskit.js", "/canvaskit/canvaskit.wasm",
                     "/canvaskit/chromium/canvaskit.js", "/canvaskit/chromium/canvaskit.wasm",
                     "/assets/assets/fonts/Roboto.ttf",
                     "/drift_worker.dart.js", "/sqlite3.wasm"):
        with urllib.request.urlopen(base + resource, timeout=15) as response:
            content = response.read()
            assert response.status == 200, resource
            assert response.headers["Cross-Origin-Opener-Policy"] == "same-origin"
            assert response.headers["Cross-Origin-Embedder-Policy"] == "credentialless"
            if resource.endswith(".wasm"):
                assert response.headers.get_content_type() == "application/wasm"
                assert content.startswith(b"\x00asm"), "Invalid WebAssembly module"
            if resource == "/flutter_bootstrap.js":
                assert b"{{flutter_" not in content, "Unexpanded bootstrap template"
                assert b"canvasKitBaseUrl: 'canvaskit/'" in content
            assert content, resource
            print(f"OK {resource}: {len(content)} bytes", flush=True)


if __name__ == "__main__":
    check_preview()
