-- In-app notifications: likes, comments, follows, follow requests, accepted requests.
-- Rows are created ONLY by triggers (clients cannot insert); a user can read/mark-read/delete their own.
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id  uuid not null references public.profiles(id) on delete cascade,   -- recipient
  actor_id uuid not null references public.profiles(id) on delete cascade,   -- who did it
  type text not null check (type in ('like','comment','follow','follow_request','follow_accepted')),
  post_id uuid references public.posts(id) on delete cascade,
  body text,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  check (user_id <> actor_id)
);
create index on public.notifications (user_id, created_at desc);
create index on public.notifications (user_id) where read_at is null;
-- like/unlike/like again must not spam: one row per (recipient, actor, post) / (recipient, actor, type)
create unique index notif_like_uq   on public.notifications (user_id, actor_id, post_id) where type = 'like';
create unique index notif_follow_uq on public.notifications (user_id, actor_id, type) where type in ('follow','follow_request','follow_accepted');

alter table public.notifications enable row level security;
create policy notif_read   on public.notifications for select using (user_id = auth.uid());
create policy notif_update on public.notifications for update using (user_id = auth.uid());
create policy notif_delete on public.notifications for delete using (user_id = auth.uid());
revoke update on public.notifications from anon, authenticated;
grant  update (read_at) on public.notifications to authenticated;

-- ---- triggers (AFTER, security definer) ----
create or replace function public.trg_notify_like() returns trigger
language plpgsql security definer set search_path = '' as $$
declare owner uuid;
begin
  if tg_op = 'INSERT' then
    select user_id into owner from public.posts where id = new.post_id;
    if owner is not null and owner <> new.user_id then
      insert into public.notifications(user_id, actor_id, type, post_id) values (owner, new.user_id, 'like', new.post_id) on conflict do nothing;
    end if;
  else
    delete from public.notifications where actor_id = old.user_id and post_id = old.post_id and type = 'like';
  end if;
  return null;
end $$;
create trigger notify_like after insert or delete on public.likes for each row execute function public.trg_notify_like();

create or replace function public.trg_notify_comment() returns trigger
language plpgsql security definer set search_path = '' as $$
declare owner uuid;
begin
  select user_id into owner from public.posts where id = new.post_id;
  if owner is not null and owner <> new.user_id then
    insert into public.notifications(user_id, actor_id, type, post_id, body) values (owner, new.user_id, 'comment', new.post_id, left(new.body, 100));
  end if;
  return null;
end $$;
create trigger notify_comment after insert on public.comments for each row execute function public.trg_notify_comment();

create or replace function public.trg_notify_follow() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    insert into public.notifications(user_id, actor_id, type)
    values (new.following_id, new.follower_id, case when new.status = 'accepted' then 'follow' else 'follow_request' end) on conflict do nothing;
  elsif tg_op = 'UPDATE' then
    if old.status = 'pending' and new.status = 'accepted' then
      delete from public.notifications where user_id = new.following_id and actor_id = new.follower_id and type = 'follow_request';
      insert into public.notifications(user_id, actor_id, type) values (new.following_id, new.follower_id, 'follow') on conflict do nothing;
      insert into public.notifications(user_id, actor_id, type) values (new.follower_id, new.following_id, 'follow_accepted') on conflict do nothing;
    end if;
  else
    delete from public.notifications where actor_id = old.follower_id and user_id = old.following_id and type in ('follow','follow_request');
  end if;
  return null;
end $$;
create trigger notify_follow after insert or update or delete on public.follows for each row execute function public.trg_notify_follow();

-- ---- API ----
create or replace function public.get_notifications(p_limit int default 30, p_before timestamptz default null)
returns table (id uuid, type text, actor_id uuid, actor_username citext, actor_avatar text, post_id uuid,
               thumb_url text, body text, is_read boolean, created_at timestamptz)
language sql stable security invoker set search_path = '' as $$
  select n.id, n.type, n.actor_id, a.username, a.avatar_url, n.post_id,
    (select coalesce(m.thumb_url, m.url) from public.post_media m where m.post_id = n.post_id order by m.position limit 1),
    n.body, n.read_at is not null, n.created_at
  from public.notifications n join public.profiles a on a.id = n.actor_id
  where n.user_id = auth.uid() and (p_before is null or n.created_at < p_before)
  order by n.created_at desc
  limit least(p_limit, 100);
$$;

create or replace function public.unread_notification_count() returns int
language sql stable security invoker set search_path = '' as $$
  select count(*)::int from public.notifications where user_id = auth.uid() and read_at is null;
$$;

create or replace function public.mark_notifications_read() returns void
language sql security invoker set search_path = '' as $$
  update public.notifications set read_at = now() where user_id = auth.uid() and read_at is null;
$$;
