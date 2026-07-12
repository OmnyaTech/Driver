-- Omnya Driver
-- Referral rewards read model for the community panel.
-- Date: 2026-07-11
-- Execute manually in Supabase SQL Editor after 014_driver_referrals.sql.

create or replace function driver.get_referral_rewards()
returns table (
  referral_id uuid,
  referred_user_id uuid,
  referred_display_name text,
  referred_avatar_url text,
  reward_xp integer,
  accepted_at timestamptz
)
language sql
security definer
stable
set search_path = driver, auth, public
as $$
  select
    r.id as referral_id,
    r.referred_user_id,
    coalesce(nullif(p.display_name, ''), nullif(p.full_name, ''), 'Motorista indicado') as referred_display_name,
    p.avatar_url as referred_avatar_url,
    r.reward_xp,
    r.accepted_at
  from driver.driver_referrals r
  left join driver.profiles p on p.id = r.referred_user_id
  where r.referrer_user_id = auth.uid()
  order by r.accepted_at desc
  limit 50;
$$;

grant execute on function driver.get_referral_rewards() to authenticated;
