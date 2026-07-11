-- Omnya Driver
-- Referral tracking and invite rewards.
-- Date: 2026-07-10
-- Execute manually in Supabase SQL Editor.

create table if not exists driver.driver_referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_user_id uuid not null references auth.users(id) on delete cascade,
  referred_user_id uuid not null references auth.users(id) on delete cascade,
  referrer_slug text not null,
  reward_xp integer not null default 25,
  accepted_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  unique (referred_user_id)
);

create index if not exists idx_driver_referrals_referrer_created_at
  on driver.driver_referrals (referrer_user_id, created_at desc);

alter table driver.driver_referrals enable row level security;

grant select on driver.driver_referrals to authenticated;

drop policy if exists "driver_referrals_own_select" on driver.driver_referrals;
create policy "driver_referrals_own_select"
  on driver.driver_referrals
  for select
  to authenticated
  using (
    auth.uid() = referrer_user_id
    or auth.uid() = referred_user_id
  );

create or replace function driver.accept_public_referral(p_referrer_slug text)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_referred_user_id uuid := auth.uid();
  v_referrer_user_id uuid;
  v_referrer_slug text := lower(trim(coalesce(p_referrer_slug, '')));
  v_referral_id uuid;
  v_medal_key text;
begin
  if v_referred_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  if v_referrer_slug = '' then
    return jsonb_build_object('accepted', false, 'reason', 'empty_slug');
  end if;

  select p.id
  into v_referrer_user_id
  from driver.profiles p
  where lower(p.public_slug) = v_referrer_slug
    and p.public_profile_enabled = true
  limit 1;

  if v_referrer_user_id is null then
    return jsonb_build_object('accepted', false, 'reason', 'referrer_not_found');
  end if;

  if v_referrer_user_id = v_referred_user_id then
    return jsonb_build_object('accepted', false, 'reason', 'self_referral');
  end if;

  insert into driver.driver_referrals (
    referrer_user_id,
    referred_user_id,
    referrer_slug
  )
  values (
    v_referrer_user_id,
    v_referred_user_id,
    v_referrer_slug
  )
  on conflict (referred_user_id) do nothing
  returning id into v_referral_id;

  if v_referral_id is null then
    return jsonb_build_object('accepted', false, 'reason', 'already_referred');
  end if;

  v_medal_key := 'referral_' || left(replace(v_referred_user_id::text, '-', ''), 12);

  insert into driver.driver_medal_unlocks (
    user_id,
    medal_key,
    medal_name,
    description,
    metadata
  )
  values (
    v_referrer_user_id,
    v_medal_key,
    'Convite aceito',
    'Um motorista entrou pelo seu convite.',
    jsonb_build_object(
      'referred_user_id', v_referred_user_id,
      'referral_id', v_referral_id,
      'reward_xp', 25
    )
  )
  on conflict (user_id, medal_key) do nothing;

  insert into driver.driver_notifications (
    user_id,
    notification_key,
    kind,
    title,
    body,
    action_type,
    action_payload,
    delivered_at
  )
  values (
    v_referrer_user_id,
    'referral-' || v_referral_id::text,
    'gamification',
    'Seu convite deu certo',
    'Um motorista entrou pelo seu link. Voce ganhou uma medalha e pontos no progresso.',
    'gamification',
    jsonb_build_object('referral_id', v_referral_id),
    timezone('utc', now())
  )
  on conflict (user_id, notification_key) do nothing;

  return jsonb_build_object(
    'accepted', true,
    'referrer_user_id', v_referrer_user_id,
    'referral_id', v_referral_id,
    'reward_xp', 25
  );
end;
$$;

grant execute on function driver.accept_public_referral(text) to authenticated;
