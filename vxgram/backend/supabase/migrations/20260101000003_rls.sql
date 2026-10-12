-- Visibility helpers (security definer => no RLS recursion)
create or replace function public.can_view_user(target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select auth.uid() = target
      or exists (select 1 from public.profiles p where p.id = target and not p.is_private)
      or exists (select 1 from public.follows f
                 where f.follower_id = auth.uid() and f.following_id = target and f.status = 'accepted');
$$;
create or replace function public.can_view_post(pid uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select public.can_view_user((select user_id from public.posts where id = pid));
$$;

alter table public.profiles    enable row level security;
alter table public.posts       enable row level security;
alter table public.post_media  enable row level security;
alter table public.likes       enable row level security;
alter table public.comments    enable row level security;
alter table public.follows     enable row level security;
alter table public.post_shares enable row level security;

-- Column-level grants: counters can never be set by clients
revoke insert, update, delete on public.profiles from anon, authenticated;
grant  update (username, full_name, bio, avatar_url, avatar_path, is_private) on public.profiles to authenticated;
revoke update on public.posts from anon, authenticated;
grant  update (caption) on public.posts to authenticated;
revoke update on public.post_shares from anon, authenticated;
grant  update (seen) on public.post_shares to authenticated;

create policy profiles_read   on public.profiles for select using (true);
create policy profiles_update on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

create policy posts_read   on public.posts for select using (public.can_view_user(user_id));
create policy posts_insert on public.posts for insert with check (user_id = auth.uid());
create policy posts_update on public.posts for update using (user_id = auth.uid());
create policy posts_delete on public.posts for delete using (user_id = auth.uid());

create policy media_read   on public.post_media for select using (public.can_view_user(user_id));
create policy media_insert on public.post_media for insert with check (
  user_id = auth.uid() and exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid()));
create policy media_delete on public.post_media for delete using (user_id = auth.uid());

create policy likes_read   on public.likes for select using (public.can_view_post(post_id));
create policy likes_insert on public.likes for insert with check (user_id = auth.uid() and public.can_view_post(post_id));
create policy likes_delete on public.likes for delete using (user_id = auth.uid());

create policy comments_read   on public.comments for select using (public.can_view_post(post_id));
create policy comments_insert on public.comments for insert with check (user_id = auth.uid() and public.can_view_post(post_id));
create policy comments_delete on public.comments for delete using (
  user_id = auth.uid() or exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid()));

-- follows: writes only through RPCs (security definer); unfollow/cancel allowed directly
create policy follows_read on public.follows for select using (
  follower_id = auth.uid() or following_id = auth.uid() or (status = 'accepted' and public.can_view_user(following_id)));
create policy follows_delete on public.follows for delete using (follower_id = auth.uid() or following_id = auth.uid());

create policy shares_read   on public.post_shares for select using (sender_id = auth.uid() or receiver_id = auth.uid());
create policy shares_insert on public.post_shares for insert with check (sender_id = auth.uid() and public.can_view_post(post_id));
create policy shares_update on public.post_shares for update using (receiver_id = auth.uid());
create policy shares_delete on public.post_shares for delete using (sender_id = auth.uid() or receiver_id = auth.uid());
