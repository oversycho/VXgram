-- ===== Reads (security invoker => RLS enforced) =====

-- scope: 'feed' (me + accepted followings) | 'profile' (p_author) | 'explore' (public accounts, not me)
create or replace function public.get_posts(
  p_scope text, p_author uuid default null, p_limit int default 20, p_before timestamptz default null)
returns table (id uuid, user_id uuid, username citext, avatar_url text, caption text, created_at timestamptz,
               likes_count int, comments_count int, liked_by_me boolean, media jsonb)
language sql stable security invoker set search_path = '' as $$
  select p.id, p.user_id, pr.username, pr.avatar_url, p.caption, p.created_at, p.likes_count, p.comments_count,
    exists (select 1 from public.likes l where l.post_id = p.id and l.user_id = auth.uid()),
    coalesce((select jsonb_agg(jsonb_build_object('id', m.id, 'url', m.url, 'type', m.media_type,
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

create or replace function public.get_profile(p_user uuid)
returns table (id uuid, username citext, full_name text, bio text, avatar_url text, is_private boolean,
               posts_count int, followers_count int, following_count int,
               is_me boolean, follow_status text, follows_me boolean, can_view boolean)
language sql stable security invoker set search_path = '' as $$
  select p.id, p.username, p.full_name, p.bio, p.avatar_url, p.is_private,
         p.posts_count, p.followers_count, p.following_count,
         p.id = auth.uid(),
         (select f.status::text from public.follows f where f.follower_id = auth.uid() and f.following_id = p.id),
         exists (select 1 from public.follows f where f.follower_id = p.id and f.following_id = auth.uid() and f.status = 'accepted'),
         public.can_view_user(p.id)
  from public.profiles p where p.id = p_user;
$$;

create or replace function public.search_users(q text, p_limit int default 20)
returns table (id uuid, username citext, full_name text, avatar_url text, is_private boolean)
language sql stable security invoker set search_path = '' as $$
  select p.id, p.username, p.full_name, p.avatar_url, p.is_private
  from public.profiles p
  where length(trim(q)) > 0
    and (p.username::text ilike '%' || trim(q) || '%' or p.full_name ilike '%' || trim(q) || '%')
  order by (p.username::text ilike trim(q) || '%') desc, p.followers_count desc
  limit least(p_limit, 50);
$$;

create or replace function public.list_followers(p_user uuid, p_limit int default 50, p_offset int default 0)
returns table (id uuid, username citext, full_name text, avatar_url text, i_follow text)
language sql stable security invoker set search_path = '' as $$
  select p.id, p.username, p.full_name, p.avatar_url,
    (select f2.status::text from public.follows f2 where f2.follower_id = auth.uid() and f2.following_id = p.id)
  from public.follows f join public.profiles p on p.id = f.follower_id
  where f.following_id = p_user and f.status = 'accepted' and public.can_view_user(p_user)
  order by f.created_at desc limit least(p_limit, 100) offset p_offset;
$$;

create or replace function public.list_following(p_user uuid, p_limit int default 50, p_offset int default 0)
returns table (id uuid, username citext, full_name text, avatar_url text, i_follow text)
language sql stable security invoker set search_path = '' as $$
  select p.id, p.username, p.full_name, p.avatar_url,
    (select f2.status::text from public.follows f2 where f2.follower_id = auth.uid() and f2.following_id = p.id)
  from public.follows f join public.profiles p on p.id = f.following_id
  where f.follower_id = p_user and f.status = 'accepted' and public.can_view_user(p_user)
  order by f.created_at desc limit least(p_limit, 100) offset p_offset;
$$;

create or replace function public.follow_requests()
returns table (id uuid, username citext, full_name text, avatar_url text, requested_at timestamptz)
language sql stable security invoker set search_path = '' as $$
  select p.id, p.username, p.full_name, p.avatar_url, f.created_at
  from public.follows f join public.profiles p on p.id = f.follower_id
  where f.following_id = auth.uid() and f.status = 'pending' order by f.created_at desc;
$$;

create or replace function public.get_comments(p_post uuid, p_limit int default 30, p_before timestamptz default null)
returns table (id uuid, user_id uuid, username citext, avatar_url text, body text, created_at timestamptz)
language sql stable security invoker set search_path = '' as $$
  select c.id, c.user_id, p.username, p.avatar_url, c.body, c.created_at
  from public.comments c join public.profiles p on p.id = c.user_id
  where c.post_id = p_post and (p_before is null or c.created_at < p_before)
  order by c.created_at desc limit least(p_limit, 100);
$$;

create or replace function public.get_inbox(p_limit int default 30)
returns table (id uuid, post_id uuid, sender_id uuid, sender_username citext, sender_avatar text,
               message text, seen boolean, created_at timestamptz, thumb_url text)
language sql stable security invoker set search_path = '' as $$
  select s.id, s.post_id, s.sender_id, p.username, p.avatar_url, s.message, s.seen, s.created_at,
    (select m.url from public.post_media m where m.post_id = s.post_id order by m.position limit 1)
  from public.post_shares s join public.profiles p on p.id = s.sender_id
  where s.receiver_id = auth.uid() order by s.created_at desc limit least(p_limit, 100);
$$;

-- ===== Writes =====

create or replace function public.toggle_like(p_post uuid) returns boolean
language plpgsql security invoker set search_path = '' as $$
declare n int;
begin
  delete from public.likes where post_id = p_post and user_id = auth.uid();
  get diagnostics n = row_count;
  if n > 0 then return false; end if;
  insert into public.likes(post_id, user_id) values (p_post, auth.uid());
  return true;
end $$;

-- returns storage paths so the client can remove the files from the bucket
create or replace function public.delete_post(p_post uuid) returns text[]
language plpgsql security invoker set search_path = '' as $$
declare paths text[];
begin
  select array_agg(storage_path) into paths from public.post_media where post_id = p_post and user_id = auth.uid();
  delete from public.posts where id = p_post and user_id = auth.uid();
  return coalesce(paths, '{}');
end $$;

create or replace function public.share_post(p_post uuid, p_receivers uuid[], p_message text default null) returns int
language plpgsql security invoker set search_path = '' as $$
declare n int;
begin
  insert into public.post_shares(post_id, sender_id, receiver_id, message)
  select p_post, auth.uid(), r, p_message from unnest(p_receivers) r where r <> auth.uid();
  get diagnostics n = row_count;
  return n;
end $$;

-- follow: private account => 'pending', else 'accepted'
create or replace function public.follow_user(target uuid) returns text
language plpgsql security definer set search_path = '' as $$
declare priv boolean; st public.follow_status;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if target = auth.uid() then raise exception 'You cannot follow yourself'; end if;
  select is_private into priv from public.profiles where id = target;
  if not found then raise exception 'User not found'; end if;
  st := (case when priv then 'pending' else 'accepted' end)::public.follow_status;
  insert into public.follows(follower_id, following_id, status) values (auth.uid(), target, st)
    on conflict do nothing;
  return (select status::text from public.follows where follower_id = auth.uid() and following_id = target);
end $$;

create or replace function public.unfollow_user(target uuid) returns void
language sql security invoker set search_path = '' as $$
  delete from public.follows where follower_id = auth.uid() and following_id = target;
$$;

create or replace function public.respond_follow_request(p_follower uuid, p_accept boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if p_accept then
    update public.follows set status = 'accepted'
      where follower_id = p_follower and following_id = auth.uid() and status = 'pending';
  else
    delete from public.follows where follower_id = p_follower and following_id = auth.uid() and status = 'pending';
  end if;
end $$;

-- Remove one of my followers
create or replace function public.remove_follower(p_follower uuid) returns void
language sql security invoker set search_path = '' as $$
  delete from public.follows where follower_id = p_follower and following_id = auth.uid();
$$;

-- Account deletion (client must delete its storage files first)
create or replace function public.delete_account() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  delete from auth.users where id = auth.uid();
end $$;

revoke execute on function public.follow_user(uuid), public.respond_follow_request(uuid, boolean), public.delete_account() from public, anon;
grant  execute on function public.follow_user(uuid), public.respond_follow_request(uuid, boolean), public.delete_account() to authenticated;
