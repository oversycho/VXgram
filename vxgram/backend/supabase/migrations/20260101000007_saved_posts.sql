-- Saved posts (bookmarks): private to each user
create table public.saved_posts (
  user_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);
create index on public.saved_posts (user_id, created_at desc);

alter table public.saved_posts enable row level security;
create policy saved_read   on public.saved_posts for select using (user_id = auth.uid());
create policy saved_insert on public.saved_posts for insert with check (user_id = auth.uid() and public.can_view_post(post_id));
create policy saved_delete on public.saved_posts for delete using (user_id = auth.uid());

-- true = now saved, false = removed
create or replace function public.toggle_save(p_post uuid) returns boolean
language plpgsql security invoker set search_path = '' as $$
declare n int;
begin
  delete from public.saved_posts where post_id = p_post and user_id = auth.uid();
  get diagnostics n = row_count;
  if n > 0 then return false; end if;
  insert into public.saved_posts(user_id, post_id) values (auth.uid(), p_post);
  return true;
end $$;

-- Same shape as get_posts; ordered/paged by post date. RLS hides posts that became invisible (e.g. author went private).
create or replace function public.get_saved_posts(p_limit int default 15, p_before timestamptz default null)
returns table (id uuid, user_id uuid, username citext, avatar_url text, caption text, created_at timestamptz,
               likes_count int, comments_count int, liked_by_me boolean, media jsonb)
language sql stable security invoker set search_path = '' as $$
  select p.id, p.user_id, pr.username, pr.avatar_url, p.caption, p.created_at, p.likes_count, p.comments_count,
    exists (select 1 from public.likes l where l.post_id = p.id and l.user_id = auth.uid()),
    coalesce((select jsonb_agg(jsonb_build_object('id', m.id, 'url', m.url, 'type', m.media_type,
                'position', m.position, 'width', m.width, 'height', m.height) order by m.position)
              from public.post_media m where m.post_id = p.id), '[]'::jsonb)
  from public.posts p join public.profiles pr on pr.id = p.user_id
  where exists (select 1 from public.saved_posts s where s.post_id = p.id and s.user_id = auth.uid())
    and (p_before is null or p.created_at < p_before)
  order by p.created_at desc
  limit least(p_limit, 50);
$$;
