import os
import sys

export_dir = sys.argv[1] if len(sys.argv) > 1 else "."
for root, dirs, files in os.walk(export_dir):
    for file in files:
        if file.endswith(".service.worker.js"):
            sw_path = os.path.join(root, file)
            with open(sw_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            bypass_code = "\n        // BYPASS: Do not intercept external radio streams or cross-origin URLs\n        if (!url.startsWith(self.location.origin) || url.includes('181fm.com')) {\n            return;\n        }\n"
            
            if "181fm.com" not in content:
                target = "const url = event.request.url || '';"
                if target in content:
                    content = content.replace(target, target + bypass_code)
                    with open(sw_path, "w", encoding="utf-8") as f:
                        f.write(content)
                    print(f"Patched service worker: {sw_path}")
