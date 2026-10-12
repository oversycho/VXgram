-- Single post (used when opening a shared post from the inbox). Same shape as get_posts; RLS decides visibility.
create or replace function public.get_post(p_post uuid)
returns table (id uuid, user_id uuid, username citext, avatar_url text, caption text, created_at timestamptz,
               likes_count int, comments_count int, liked_by_me boolean, media jsonb)
language sql stable security invoker set search_path = '' as $$
  select p.id, p.user_id, pr.username, pr.avatar_url, p.caption, p.created_at, p.likes_count, p.comments_count,
    exists (select 1 from public.likes l where l.post_id = p.id and l.user_id = auth.uid()),
    coalesce((select jsonb_agg(jsonb_build_object('id', m.id, 'url', m.url, 'type', m.media_type,
                'position', m.position, 'width', m.width, 'height', m.height) order by m.position)
              from public.post_media m where m.post_id = p.id), '[]'::jsonb)
  from public.posts p join public.profiles pr on pr.id = p.user_id
  where p.id = p_post;
$$;
