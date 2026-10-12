-- VXGram schema
create extension if not exists pg_trgm;
create extension if not exists citext;

create type public.media_type   as enum ('image','video');
create type public.follow_status as enum ('pending','accepted');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username citext unique not null check (username::text ~ '^[a-z0-9._]{3,30}$'),
  full_name text,
  bio text not null default '' check (char_length(bio) <= 150),
  avatar_url text,
  avatar_path text,
  is_private boolean not null default false,
  posts_count     int not null default 0,
  followers_count int not null default 0,
  following_count int not null default 0,
  created_at timestamptz not null default now()
);

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  caption text not null default '' check (char_length(caption) <= 2200),
  media_count    int not null default 0,
  likes_count    int not null default 0,
  comments_count int not null default 0,
  created_at timestamptz not null default now()
);

create table public.post_media (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null,
  url text not null,
  media_type public.media_type not null,
  position int not null default 0,
  width int, height int, duration_ms int,
  unique (post_id, position)
);

create table public.likes (
  post_id uuid references public.posts(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now()
);

create table public.follows (
  follower_id  uuid references public.profiles(id) on delete cascade,
  following_id uuid references public.profiles(id) on delete cascade,
  status public.follow_status not null default 'accepted',
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

-- "send to other users"
create table public.post_shares (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  sender_id   uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  message text check (char_length(message) <= 300),
  seen boolean not null default false,
  created_at timestamptz not null default now(),
  check (sender_id <> receiver_id)
);

create index on public.posts (user_id, created_at desc);
create index on public.posts (created_at desc);
create index on public.post_media (post_id, position);
create index on public.comments (post_id, created_at desc);
create index on public.follows (following_id, status);
create index on public.post_shares (receiver_id, created_at desc);
create index profiles_username_trgm  on public.profiles using gin ((username::text) gin_trgm_ops);
create index profiles_fullname_trgm  on public.profiles using gin (full_name gin_trgm_ops);
