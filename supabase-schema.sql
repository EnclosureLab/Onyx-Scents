-- Lawson's Photography backend setup (Supabase SQL)
-- Run this in Supabase SQL Editor for a new project.
create extension if not exists pgcrypto;
create table if not exists public.booking_requests (
 id uuid primary key default gen_random_uuid(),
 created_at timestamptz not null default now(),
 full_name text not null,
 email text not null,
 session_type text not null,
 requested_date date not null,
 requested_time time not null,
 location text,
 details text,
 status text not null default 'pending' check(status in ('pending','quoted','approved','confirmed','completed','cancelled')),
 quote_amount numeric(10,2),
 deposit_amount numeric(10,2),
 paid_amount numeric(10,2) not null default 0,
 expenses numeric(10,2) not null default 0,
 payment_status text not null default 'unpaid' check(payment_status in ('unpaid','deposit_paid','paid','refunded')),
 quote_notes text,
 admin_notes text,
 portfolio_consent boolean not null default false,
 stripe_checkout_session text,
 stripe_payment_intent text
);
create table if not exists public.expenses (
 id uuid primary key default gen_random_uuid(),
 created_at timestamptz not null default now(),
 booking_id uuid references public.booking_requests(id) on delete set null,
 category text not null,
 description text not null,
 amount numeric(10,2) not null check(amount>=0),
 expense_date date not null default current_date
);
alter table public.booking_requests enable row level security;
alter table public.expenses enable row level security;
-- Public booking insertion is allowed, but customers cannot read or modify requests.
create policy "Public can submit booking requests" on public.booking_requests for insert to anon with check (status='pending' and quote_amount is null and deposit_amount is null and paid_amount=0 and expenses=0 and payment_status='unpaid' and admin_notes is null and quote_notes is null and portfolio_consent in (true,false));
-- Only authenticated admin accounts can read or manage records. Configure admin access using
-- Supabase Auth and a trusted admin role/claim before deploying dashboard access.
-- Do NOT add broad authenticated policies. Restrict admin policies to a verified admin JWT claim.
