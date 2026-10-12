-- Buckets: avatars/{uid}/..., posts/{uid}/{postId}/{n}.ext
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('avatars', 'avatars', true, 5242880,   array['image/jpeg','image/png','image/webp']),
  ('posts',   'posts',   true, 104857600, array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime','video/webm'])
on conflict (id) do nothing;

create policy "public read media" on storage.objects for select using (bucket_id in ('avatars','posts'));
create policy "upload own media" on storage.objects for insert to authenticated
  with check (bucket_id in ('avatars','posts') and (storage.foldername(name))[1] = auth.uid()::text);
create policy "update own media" on storage.objects for update to authenticated
  using (bucket_id in ('avatars','posts') and (storage.foldername(name))[1] = auth.uid()::text);
create policy "delete own media" on storage.objects for delete to authenticated
  using (bucket_id in ('avatars','posts') and (storage.foldername(name))[1] = auth.uid()::text);

-- Realtime (comments, inbox, follow requests, profile counters)
alter publication supabase_realtime add table public.comments, public.post_shares, public.follows, public.profiles;
