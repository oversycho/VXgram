# VXGram backend (Supabase)

Everything the app needs lives in `supabase/migrations/` and is applied in file-name order.

| File | What it adds |
|---|---|
| `...01_schema.sql` | tables: profiles, posts, post_media, likes, comments, follows, post_shares |
| `...02_triggers.sql` | profile on signup, counters (posts/likes/comments/followers), private -> public auto-approve |
| `...03_rls.sql` | row level security (private accounts, own-data rules, column grants) |
| `...04_rpc.sql` | API functions: feed, profile, search, follow, like, comments, share, inbox |
| `...05_storage_realtime.sql` | buckets `avatars` + `posts`, storage policies |
| `...06_get_post.sql` | `get_post` (open one shared post) |
| `...07_saved_posts.sql` | bookmarks: `saved_posts`, `toggle_save`, `get_saved_posts` |
| `...08_fix_media_trigger.sql` | repair for databases created before the media-trigger fix (harmless on new ones) |
| `...09_thumbnails.sql` | `thumb_url` / `thumb_path`, RPCs return thumbnails, `delete_post` returns thumb files |
| `...10_notifications.sql` | notifications table + triggers (like, comment, follow, request, accepted) + RPCs |

## Apply
**Dashboard:** SQL Editor -> paste each file in order -> Run.
**CLI:** `npm i -g supabase`, then in `vxgram/backend`: `supabase init` (once), `supabase login`, `supabase link --project-ref <ref>`, `supabase db push`.

Authentication -> Providers -> Email: turn **Confirm email** off while developing.

## Rules worth knowing
- Counters (`posts_count`, `likes_count`, ...) are maintained by triggers; clients cannot write them.
- A trigger that runs `BEFORE INSERT` must `return new` (returning `null` silently cancels the insert).
- Never put the `service_role` key in the app. The anon key is public by design; RLS protects the data.
