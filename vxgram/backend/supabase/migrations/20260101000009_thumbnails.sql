-- Thumbnails: every media item can have a small JPEG (grids load it instead of the full file / video).
alter table public.post_media add column if not exists thumb_url  text;
alter table public.post_media add column if not exists thumb_path text;

-- get_posts / get_post / get_saved_posts now also return thumb_url inside each media object
create or replace function public.get_posts(
  p_scope text, p_author uuid default null, p_limit int default 20, p_before timestamptz default null)
returns table (id uuid, user_id uuid, username citext, avatar_url text, caption text, created_at timestamptz,
               likes_count int, comments_count int, liked_by_me boolean, media jsonb)
language sql stable security invoker set search_path = '' as $$
  select p.id, p.user_id, pr.username, pr.avatar_url, p.caption, p.created_at, p.likes_count, p.comments_count,
    exists (select 1 from public.likes l where l.post_id = p.id and l.user_id = auth.uid()),
    coalesce((select jsonb_agg(jsonb_build_object('id', m.id, 'url', m.url, 'thumb_url', m.thumb_url, 'type', m.media_type,
                'position', m.position, 'width', m.width, 'height', m.height) order by m.position)
              from public.post_media m where m.post_id = p.id), '[]'::jsonb)
  from public.posts p join public.profiles pr on pr.id = p.user_id
  where (p_before is null or p.created_at < p_before)
    and case p_scope
      when 'feed' then p.user_id = auth.uid() or exists (
        select 1 from public.follows f where f.follower_id = auth.uid() and f.following_id = p.user_id and f.status = 'accepted')
      when 'profile' then p.user_id = p_author
      when 'explore' then not pr.is_private and p.user_id <> auth.uid()
      else false end
  order by p.created_at desc
  limit least(p_limit, 50);
$$;

create or replace function public.get_post(p_post uuid)
returns table (id uuid, user_id uuid, username citext, avatar_url text, caption text, created_at timestamptz,
               likes_count int, comments_count int, liked_by_me boolean, media jsonb)
language sql stable security invoker set search_path = '' as $$
  select p.id, p.user_id, pr.username, pr.avatar_url, p.caption, p.created_at, p.likes_count, p.comments_count,
    exists (select 1 from public.likes l where l.post_id = p.id and l.user_id = auth.uid()),
    coalesce((select jsonb_agg(jsonb_build_object('id', m.id, 'url', m.url, 'thumb_url', m.thumb_url, 'type', m.media_type,
                'position', m.position, 'width', m.width, 'height', m.height) order by m.position)
              from public.post_media m where m.post_id = p.id), '[]'::jsonb)
  from public.posts p join public.profiles pr on pr.id = p.user_id
  where p.id = p_post;
$$;

create or replace function public.get_saved_posts(p_limit int default 15, p_before timestamptz default null)
returns table (id uuid, user_id uuid, username citext, avatar_url text, caption text, created_at timestamptz,
               likes_count int, comments_count int, liked_by_me boolean, media jsonb)
language sql stable security invoker set search_path = '' as $$
  select p.id, p.user_id, pr.username, pr.avatar_url, p.caption, p.created_at, p.likes_count, p.comments_count,
    exists (select 1 from public.likes l where l.post_id = p.id and l.user_id = auth.uid()),
    coalesce((select jsonb_agg(jsonb_build_object('id', m.id, 'url', m.url, 'thumb_url', m.thumb_url, 'type', m.media_type,
                'position', m.position, 'width', m.width, 'height', m.height) order by m.position)
              from public.post_media m where m.post_id = p.id), '[]'::jsonb)
  from public.posts p join public.profiles pr on pr.id = p.user_id
  where exists (select 1 from public.saved_posts s where s.post_id = p.id and s.user_id = auth.uid())
    and (p_before is null or p.created_at < p_before)
  order by p.created_at desc
  limit least(p_limit, 50);
$$;

-- inbox preview: use the thumbnail when there is one (a video url cannot be shown as an image)
create or replace function public.get_inbox(p_limit int default 30)
returns table (id uuid, post_id uuid, sender_id uuid, sender_username citext, sender_avatar text,
               message text, seen boolean, created_at timestamptz, thumb_url text)
language sql stable security invoker set search_path = '' as $$
  select s.id, s.post_id, s.sender_id, p.username, p.avatar_url, s.message, s.seen, s.created_at,
    (select coalesce(m.thumb_url, m.url) from public.post_media m where m.post_id = s.post_id order by m.position limit 1)
  from public.post_shares s join public.profiles p on p.id = s.sender_id
  where s.receiver_id = auth.uid() order by s.created_at desc limit least(p_limit, 100);
$$;

-- deleting a post must also return the thumbnail files so the app can remove them from storage
create or replace function public.delete_post(p_post uuid) returns text[]
language plpgsql security invoker set search_path = '' as $$
declare paths text[];
begin
  select array_agg(x) into paths from (
    select storage_path as x from public.post_media where post_id = p_post and user_id = auth.uid()
    union all
    select thumb_path from public.post_media where post_id = p_post and user_id = auth.uid() and thumb_path is not null
  ) t;
  delete from public.posts where id = p_post and user_id = auth.uid();
  return coalesce(paths, '{}');
end $$;
