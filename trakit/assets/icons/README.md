# Icons

Place adaptive launcher and notification icons here.

Recommended workflow once you're ready to brand:

1. Generate with [icon.kitchen](https://icon.kitchen) or Figma at 1024×1024.
2. Use `flutter_launcher_icons` to render platform variants:
   ```yaml
   flutter_launcher_icons:
     android: true
     ios: true
     image_path: assets/icons/app_icon.png
     adaptive_icon_background: "#0B0613"
     adaptive_icon_foreground: assets/icons/app_icon_foreground.png
   ```
3. `dart run flutter_launcher_icons`

For now the splash screen renders a vector "₹" glyph as the brand mark so the
app is presentable without any binary assets.
