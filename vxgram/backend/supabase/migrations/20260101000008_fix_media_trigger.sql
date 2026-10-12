-- BUG FIX: trg_media_count ran BEFORE INSERT and returned NULL, which silently cancelled every post_media insert
-- (files were uploaded but no media rows existed, so posts showed no pictures).
create or replace function public.trg_media_count() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    if (select media_count from public.posts where id = new.post_id) >= 10 then
      raise exception 'A post can have at most 10 media items';
    end if;
    update public.posts set media_count = media_count + 1 where id = new.post_id;
    return new;
  else
    update public.posts set media_count = greatest(media_count - 1, 0) where id = old.post_id;
    return old;
  end if;
end $$;

-- Clean up the broken posts created while the bug existed (posts that have no media rows).
-- Their uploaded files stay in the 'posts' bucket; delete them in Dashboard -> Storage -> posts if you like.
delete from public.posts p
where not exists (select 1 from public.post_media m where m.post_id = p.id);
