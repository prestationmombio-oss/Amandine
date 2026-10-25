-- Boutique Amandine : Supabase > SQL Editor > New query > coller TOUT > Run
create table if not exists profiles(id uuid primary key references auth.users on delete cascade,name text,phone text unique,role text not null default 'client',created_at timestamptz default now());
create table if not exists products(id uuid primary key default gen_random_uuid(),name text not null,category text,price int not null,stock int default 1,image_url text,active boolean default true,created_at timestamptz default now());
create table if not exists zones(commune text primary key,price int not null default 1500);
create table if not exists orders(id uuid primary key default gen_random_uuid(),ref text,user_id uuid default auth.uid() references auth.users,customer_name text,phone text,commune text,address text,note text,items jsonb,subtotal int,delivery_fee int,total int,status text default 'nouvelle',created_at timestamptz default now());
insert into zones(commune,price) values ('Abobo',1500),('Adjamé',1500),('Anyama',2500),('Attécoubé',1500),('Bingerville',2500),('Cocody',1500),('Koumassi',1500),('Marcory',1500),('Plateau',1500),('Port-Bouët',1500),('Songon',3000),('Treichville',1500),('Yopougon',1500) on conflict do nothing;
create or replace function is_admin() returns boolean language sql security definer set search_path=public as $$ select exists(select 1 from profiles where id=auth.uid() and role='admin') $$;
create or replace function handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into profiles(id,name,phone) values(new.id,new.raw_user_meta_data->>'name',coalesce(new.raw_user_meta_data->>'phone',split_part(new.email,'@',1))); return new; end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();
alter table profiles enable row level security;alter table products enable row level security;alter table zones enable row level security;alter table orders enable row level security;
create policy "profil: le sien ou admin" on profiles for select using(id=auth.uid() or is_admin());
create policy "articles: lecture publique" on products for select using(true);
create policy "articles: admin écrit" on products for all using(is_admin()) with check(is_admin());
create policy "livraison: lecture publique" on zones for select using(true);
create policy "livraison: admin écrit" on zones for all using(is_admin()) with check(is_admin());
create policy "commandes: tout le monde peut commander" on orders for insert to anon,authenticated with check(status='nouvelle' and (user_id is null or user_id=auth.uid()));
create policy "commandes: les siennes ou admin" on orders for select to authenticated using(user_id=auth.uid() or is_admin());
create policy "commandes: admin modifie" on orders for update using(is_admin());
create policy "commandes: admin supprime" on orders for delete using(is_admin());
insert into storage.buckets(id,name,public) values('produits','produits',true) on conflict do nothing;
create policy "photos: lecture publique" on storage.objects for select using(bucket_id='produits');
create policy "photos: admin envoie" on storage.objects for insert with check(bucket_id='produits' and is_admin());
create policy "photos: admin modifie" on storage.objects for update using(bucket_id='produits' and is_admin());
create policy "photos: admin supprime" on storage.objects for delete using(bucket_id='produits' and is_admin());
-- ÉTAPE FINALE : après avoir créé le compte d'Amandine sur le site (bouton Se connecter > Créer un compte), exécuter :
-- update profiles set role='admin' where phone='0787027983';
