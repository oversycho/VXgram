-- Profile auto-creation on signup
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare uname text;
begin
  uname := lower(coalesce(new.raw_user_meta_data->>'username', split_part(new.email,'@',1)));
  uname := left(regexp_replace(uname,'[^a-z0-9._]','','g'), 24);
  if char_length(uname) < 3 or exists (select 1 from public.profiles where username = uname) then
    uname := coalesce(nullif(left(uname,18),''),'user') || substr(replace(new.id::text,'-',''),1,6);
  end if;
  insert into public.profiles(id, username, full_name)
  values (new.id, uname, new.raw_user_meta_data->>'full_name');
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Denormalized counters (clients cannot write them: see column grants in RLS file)
create or replace function public.trg_posts_count() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then update public.profiles set posts_count = posts_count + 1 where id = new.user_id;
  else update public.profiles set posts_count = greatest(posts_count - 1, 0) where id = old.user_id; end if;
  return null;
end $$;
create trigger posts_count after insert or delete on public.posts
  for each row execute function public.trg_posts_count();

create or replace function public.trg_media_count() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    if (select media_count from public.posts where id = new.post_id) >= 10 then
      raise exception 'A post can have at most 10 media items';
    end if;
    update public.posts set media_count = media_count + 1 where id = new.post_id;
    return new; -- BEFORE INSERT: returning NULL would silently cancel the insert
  else
    update public.posts set media_count = greatest(media_count - 1, 0) where id = old.post_id;
    return old;
  end if;
end $$;
create trigger media_count before insert on public.post_media
  for each row execute function public.trg_media_count();
create trigger media_count_del after delete on public.post_media
  for each row execute function public.trg_media_count();

create or replace function public.trg_likes_count() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then update public.posts set likes_count = likes_count + 1 where id = new.post_id;
  else update public.posts set likes_count = greatest(likes_count - 1, 0) where id = old.post_id; end if;
  return null;
end $$;
create trigger likes_count after insert or delete on public.likes
  for each row execute function public.trg_likes_count();

create or replace function public.trg_comments_count() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then update public.posts set comments_count = comments_count + 1 where id = new.post_id;
  else update public.posts set comments_count = greatest(comments_count - 1, 0) where id = old.post_id; end if;
  return null;
end $$;
create trigger comments_count after insert or delete on public.comments
  for each row execute function public.trg_comments_count();

-- Follow counters count ACCEPTED follows only
create or replace function public.trg_follows_count() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if (tg_op = 'INSERT' and new.status = 'accepted')
     or (tg_op = 'UPDATE' and old.status = 'pending' and new.status = 'accepted') then
    update public.profiles set followers_count = followers_count + 1 where id = new.following_id;
    update public.profiles set following_count = following_count + 1 where id = new.follower_id;
  elsif tg_op = 'DELETE' and old.status = 'accepted' then
    update public.profiles set followers_count = greatest(followers_count - 1, 0) where id = old.following_id;
    update public.profiles set following_count = greatest(following_count - 1, 0) where id = old.follower_id;
  end if;
  return null;
end $$;
create trigger follows_count after insert or update or delete on public.follows
  for each row execute function public.trg_follows_count();

-- Private -> public: approve all pending requests
create or replace function public.trg_profile_public() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if old.is_private and not new.is_private then
    update public.follows set status = 'accepted' where following_id = new.id and status = 'pending';
  end if;
  return null;
end $$;
create trigger profile_public after update of is_private on public.profiles
  for each row execute function public.trg_profile_public();
