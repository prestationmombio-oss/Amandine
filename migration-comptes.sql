-- À exécuter UNIQUEMENT si une ancienne version de schema.sql a déjà été lancée
create table if not exists profiles(id uuid primary key references auth.users on delete cascade,name text,phone text unique,role text not null default 'client',created_at timestamptz default now());
insert into profiles(id,name,phone) select id,raw_user_meta_data->>'name',coalesce(raw_user_meta_data->>'phone',split_part(email,'@',1)) from auth.users on conflict do nothing;
alter table orders add column if not exists user_id uuid default auth.uid() references auth.users;
alter table orders add column if not exists ref text;
drop policy if exists "gerante gère articles" on products;drop policy if exists "gerante gère zones" on zones;drop policy if exists "client crée commande" on orders;drop policy if exists "tout le monde peut commander" on orders;drop policy if exists "gerante lit commandes" on orders;drop policy if exists "gerante ou cliente lit commandes" on orders;drop policy if exists "gerante met a jour commandes" on orders;drop policy if exists "gerante envoie photos" on storage.objects;
-- puis exécuter la partie « create or replace function ... » et « create policy ... » de schema.sql, ensuite :
update profiles set role='admin' where phone='0787027983';
