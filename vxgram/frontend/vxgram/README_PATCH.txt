Part 5 patch: real thumbnails in the Explore / Profile / Saved grids (images and videos), poster while a video loads.
ORDER MATTERS:
1) Supabase SQL editor: run supabase_migrations/20260101000009_thumbnails.sql ONCE (adds thumb columns, updates the RPCs).
   Also make sure 20260101000008_fix_media_trigger.sql was run (pictures did not show before it).
2) Unzip into the project root and overwrite (includes pubspec.yaml and lib/core/env.dart).
3) NEW PACKAGES: flutter pub get   (image, video_thumbnail), then stop the app completely and flutter run (native plugin).
4) Create a NEW post to get thumbnails. Posts made before this patch: images load shrunk, videos show a placeholder.
