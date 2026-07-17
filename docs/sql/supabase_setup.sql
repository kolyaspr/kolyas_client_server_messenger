-- =============================================================
-- Kolyas Messenger: Supabase setup
-- Tables: users, messages, message_reactions
-- Buckets: chat-files, chat-audio
-- Run in Supabase Dashboard -> SQL Editor
-- =============================================================

create extension if not exists "uuid-ossp";

-- --------------------------
-- Tables
-- --------------------------
create table if not exists public.users (
  id uuid primary key,
  email text unique not null,
  created_at timestamp with time zone default now()
);

create table if not exists public.messages (
  id uuid primary key default uuid_generate_v4(),
  sender_id uuid not null references public.users(id) on delete cascade,
  sender_email text not null,
  receiver_id uuid not null references public.users(id) on delete cascade,
  message text,
  chat_room_id text not null,
  message_type text default 'text',
  file_url text,
  file_name text,
  audio_url text,
  audio_duration integer,
  created_at timestamp with time zone default now()
);

create table if not exists public.message_reactions (
  id uuid primary key default uuid_generate_v4(),
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  reaction text not null,
  created_at timestamp with time zone default now(),
  unique(message_id, user_id)
);

-- --------------------------
-- Indexes
-- --------------------------
create index if not exists idx_messages_chat_room on public.messages(chat_room_id);
create index if not exists idx_messages_created_at on public.messages(created_at);
create index if not exists idx_messages_type on public.messages(message_type);
create index if not exists idx_users_email on public.users(email);
create index if not exists idx_message_reactions_message on public.message_reactions(message_id);

-- --------------------------
-- Realtime
-- If Supabase says the table is already in publication, ignore that notice.
-- --------------------------
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.users;
alter publication supabase_realtime add table public.message_reactions;

-- --------------------------
-- RLS
-- --------------------------
alter table public.users enable row level security;
alter table public.messages enable row level security;
alter table public.message_reactions enable row level security;

-- users
create policy "Users can view all users" on public.users
  for select using (true);

create policy "Users can insert their own profile" on public.users
  for insert with check (auth.uid() = id);

create policy "Users can update their own profile" on public.users
  for update using (auth.uid() = id);

-- messages
create policy "Users can view messages in their chats" on public.messages
  for select using (
    auth.uid() = sender_id or auth.uid() = receiver_id
  );

create policy "Users can send messages" on public.messages
  for insert with check (auth.uid() = sender_id);

create policy "Users can delete their own messages" on public.messages
  for delete using (auth.uid() = sender_id);

create policy "Receiver can delete messages" on public.messages
  for delete using (auth.uid() = receiver_id);

-- reactions
create policy "Users can view reactions" on public.message_reactions
  for select using (
    message_id in (
      select id from public.messages
      where sender_id = auth.uid() or receiver_id = auth.uid()
    )
  );

create policy "Users can add reactions" on public.message_reactions
  for insert with check (auth.uid() = user_id);

create policy "Users can update own reactions" on public.message_reactions
  for update using (auth.uid() = user_id);

create policy "Users can delete own reactions" on public.message_reactions
  for delete using (auth.uid() = user_id);

-- --------------------------
-- Storage buckets
-- You can also create them manually in Storage UI:
-- chat-files, chat-audio, Public bucket = ON.
-- --------------------------
insert into storage.buckets (id, name, public)
values ('chat-files', 'chat-files', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('chat-audio', 'chat-audio', true)
on conflict (id) do update set public = true;

-- Storage policies for file bucket
create policy "Users can upload chat files" on storage.objects
  for insert with check (
    bucket_id = 'chat-files' and auth.uid() is not null
  );

create policy "Users can view chat files" on storage.objects
  for select using (bucket_id = 'chat-files');

create policy "Users can delete own chat files" on storage.objects
  for delete using (
    bucket_id = 'chat-files' and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Storage policies for audio bucket
create policy "Users can upload chat audio" on storage.objects
  for insert with check (
    bucket_id = 'chat-audio' and auth.uid() is not null
  );

create policy "Users can view chat audio" on storage.objects
  for select using (bucket_id = 'chat-audio');

create policy "Users can delete own chat audio" on storage.objects
  for delete using (
    bucket_id = 'chat-audio' and auth.uid()::text = (storage.foldername(name))[1]
  );
