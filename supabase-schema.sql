-- Lawson's Photography Supabase setup schema
-- Run this in Supabase SQL Editor. Admin permissions rely on a trusted app_metadata.role='admin'
-- claim. Set this claim only from a trusted server/admin process; never from client-side code.
create extension if not exists pgcrypto;
create table if not exists public.booking_requests (
 id uuid primary key default gen_random_uuid(), created_at timestamptz not null default now(),
 full_name text not null,email text not null,session_type text not null,requested_date date not null,requested_time time not null,location text,details text,
 status text not null default 'pending' check(status in ('pending','quoted','approved','confirmed','completed','cancelled')),
 quote_amount numeric(10,2),deposit_amount numeric(10,2),paid_amount numeric(10,2) not null default 0,expenses numeric(10,2) not null default 0,
 payment_status text not null default 'unpaid' check(payment_status in ('unpaid','deposit_paid','paid','refunded')),quote_notes text,admin_notes text,
 portfolio_consent boolean not null default false,stripe_checkout_session text,stripe_payment_intent text
);
create table if not exists public.expenses (
 id uuid primary key default gen_random_uuid(),created_at timestamptz not null default now(),
 booking_id uuid references public.booking_requests(id) on delete set null,category text not null,description text not null,
 amount numeric(10,2) not null check(amount>=0),expense_date date not null default current_date
);
alter table public.booking_requests enable row level security;
alter table public.expenses enable row level security;
drop policy if exists "Public can submit booking requests" on public.booking_requests;
create policy "Public can submit booking requests" on public.booking_requests for insert to anon with check
(status='pending' and quote_amount is null and deposit_amount is null and paid_amount=0 and expenses=0 and payment_status='unpaid' and admin_notes is null and quote_notes is null);
drop policy if exists "Admin can read bookings" on public.booking_requests;
create policy "Admin can read bookings" on public.booking_requests for select to authenticated using ((auth.jwt()->'app_metadata'->>'role')='admin');
drop policy if exists "Admin can update bookings" on public.booking_requests;
create policy "Admin can update bookings" on public.booking_requests for update to authenticated using ((auth.jwt()->'app_metadata'->>'role')='admin') with check ((auth.jwt()->'app_metadata'->>'role')='admin');
drop policy if exists "Admin can delete bookings" on public.booking_requests;
create policy "Admin can delete bookings" on public.booking_requests for delete to authenticated using ((auth.jwt()->'app_metadata'->>'role')='admin');
drop policy if exists "Admin can read expenses" on public.expenses;
create policy "Admin can read expenses" on public.expenses for select to authenticated using ((auth.jwt()->'app_metadata'->>'role')='admin');
drop policy if exists "Admin can add expenses" on public.expenses;
create policy "Admin can add expenses" on public.expenses for insert to authenticated with check ((auth.jwt()->'app_metadata'->>'role')='admin');
drop policy if exists "Admin can update expenses" on public.expenses;
create policy "Admin can update expenses" on public.expenses for update to authenticated using ((auth.jwt()->'app_metadata'->>'role')='admin') with check ((auth.jwt()->'app_metadata'->>'role')='admin');
drop policy if exists "Admin can delete expenses" on public.expenses;
create policy "Admin can delete expenses" on public.expenses for delete to authenticated using ((auth.jwt()->'app_metadata'->>'role')='admin');
-- Admin claim must be set in Supabase Auth user app_metadata by trusted admin/server only.
-- Stripe secret keys must stay in server-side environment variables, never in HTML or browser storage.
