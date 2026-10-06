-- =============================================================================
-- CheapEats — schema do banco (Supabase / PostgreSQL)
--
-- Como usar: Supabase > SQL Editor > New query > cole este arquivo > Run.
-- Depois rode o supabase/seed.sql para popular os dados simulados.
--
-- As tabelas espelham o arquivo assets/data/cheapeats_mock.json (mesmos nomes
-- de colunas), então o app lê o banco e o JSON local com o mesmo código.
-- =============================================================================

-- Apps de delivery comparados
create table if not exists public.platforms (
  id          text primary key,              -- 'ifood' | '99food' | 'keeta' | 'rappi' | 'aiqfome'
  name        text not null,
  color       text not null,                 -- cor da marca (#RRGGBB)
  on_color    text not null,                 -- cor do texto sobre a marca
  web_url     text not null,                 -- link aberto no "Pedir no app"
  service_fee numeric(10,2) not null default 0,
  sort_order  int not null default 0
);

-- Restaurantes
create table if not exists public.restaurants (
  id           text primary key,
  name         text not null,
  category     text not null,                -- ver FoodCategory no app
  description  text,
  neighborhood text,
  distance_km  numeric(5,2),
  rating       numeric(2,1),
  review_count int,
  price_level  int check (price_level between 1 and 3),
  is_open      boolean not null default true,
  opens_at     text,                         -- ex.: '18:00' quando fechado
  image_url    text,
  brand_color  text,
  latitude     numeric(9,6),                 -- posição no mapa
  longitude    numeric(9,6)
);

-- Condições do restaurante em cada app (frete, tempo, pedido mínimo)
create table if not exists public.restaurant_platforms (
  restaurant_id     text not null references public.restaurants(id) on delete cascade,
  platform_id       text not null references public.platforms(id),
  delivery_fee      numeric(10,2) not null,
  delivery_time_min int not null,
  delivery_time_max int not null,
  min_order         numeric(10,2) not null default 0,
  primary key (restaurant_id, platform_id)
);

-- Pratos do cardápio
create table if not exists public.dishes (
  id            text primary key,
  restaurant_id text not null references public.restaurants(id) on delete cascade,
  name          text not null,
  description   text,
  section       text,
  serves        int not null default 1,
  image_url     text,
  is_popular    boolean not null default false,
  sort_order    int not null default 0
);

-- Preço de cada prato em cada app
create table if not exists public.dish_prices (
  dish_id        text not null references public.dishes(id) on delete cascade,
  platform_id    text not null references public.platforms(id),
  price          numeric(10,2) not null,
  original_price numeric(10,2),               -- preço "de" quando há promoção
  available      boolean not null default true, -- false = esgotado
  primary key (dish_id, platform_id)
);

-- Cupons
create table if not exists public.coupons (
  id               text primary key,
  platform_id      text not null references public.platforms(id),
  restaurant_id    text references public.restaurants(id) on delete cascade, -- null = todos
  code             text not null,
  title            text not null,
  description      text,
  type             text not null check (type in ('percent', 'fixed', 'free_delivery')),
  value            numeric(10,2) not null default 0,
  max_discount     numeric(10,2),
  min_order        numeric(10,2) not null default 0,
  first_order_only boolean not null default false,
  expires_at       date not null
);

create index if not exists dishes_restaurant_idx on public.dishes (restaurant_id);
create index if not exists dish_prices_platform_idx on public.dish_prices (platform_id);

-- -----------------------------------------------------------------------------
-- Segurança (RLS): o app usa a publishable/anon key, então o catálogo é
-- SOMENTE LEITURA para o público. Ninguém altera preços pelo app.
-- -----------------------------------------------------------------------------
alter table public.platforms            enable row level security;
alter table public.restaurants          enable row level security;
alter table public.restaurant_platforms enable row level security;
alter table public.dishes               enable row level security;
alter table public.dish_prices          enable row level security;
alter table public.coupons              enable row level security;

drop policy if exists "leitura publica" on public.platforms;
drop policy if exists "leitura publica" on public.restaurants;
drop policy if exists "leitura publica" on public.restaurant_platforms;
drop policy if exists "leitura publica" on public.dishes;
drop policy if exists "leitura publica" on public.dish_prices;
drop policy if exists "leitura publica" on public.coupons;

create policy "leitura publica" on public.platforms            for select using (true);
create policy "leitura publica" on public.restaurants          for select using (true);
create policy "leitura publica" on public.restaurant_platforms for select using (true);
create policy "leitura publica" on public.dishes               for select using (true);
create policy "leitura publica" on public.dish_prices          for select using (true);
create policy "leitura publica" on public.coupons              for select using (true);

grant usage on schema public to anon, authenticated;
grant select on public.platforms, public.restaurants, public.restaurant_platforms,
                public.dishes, public.dish_prices, public.coupons
  to anon, authenticated;

-- -----------------------------------------------------------------------------
-- TODO(PARTE-3): tabela `orders` (histórico de pedidos) com política de INSERT
-- e SELECT para o app. Ver docs/cp5/TAREFAS.md.
-- -----------------------------------------------------------------------------
create table if not exists public.orders (
  id              uuid primary key default gen_random_uuid(),
  device_id       text not null,
  restaurant_id   text not null references public.restaurants(id),
  restaurant_name text not null,
  platform_id     text not null references public.platforms(id),
  items_summary   text not null,
  total           numeric(10,2) not null,
  savings         numeric(10,2) not null default 0,
  created_at      timestamptz not null default now()
);

alter table public.orders enable row level security;
create policy "app registra pedidos" on public.orders for insert to anon, authenticated with check (true);
create policy "app lê pedidos" on public.orders for select to anon, authenticated using (true);
grant select, insert on public.orders to anon, authenticated;
