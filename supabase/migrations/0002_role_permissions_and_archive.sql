-- OTM may manage assigned clients; other staff roles retain assigned-client read access.
-- Client deletion is a soft archive and cannot be performed with DELETE.
alter table public.clients
    add column created_by uuid references auth.users (id) on delete set null default auth.uid(),
    add column archived_at timestamptz,
    add column archived_by uuid references auth.users (id) on delete set null;

create table public.staff_profiles (
    user_id uuid primary key references auth.users (id) on delete cascade,
    role text not null check (role in ('otm', 'ot', 'psynurse', 'ota', 'st', 'dt')),
    created_at timestamptz not null default now()
);

comment on table public.staff_profiles is
    'Provisional OT staff role assignment. Writes are reserved for trusted administrative provisioning.';

alter table public.staff_profiles enable row level security;

revoke all on table public.staff_profiles from public, anon, authenticated;
grant select on table public.staff_profiles to authenticated;
grant all on table public.staff_profiles to service_role;

create policy "Staff can view their own profile"
    on public.staff_profiles
    for select
    to authenticated
    using (user_id = (select auth.uid()));

drop policy "Staff can view assigned clients" on public.clients;

create policy "Staff can view active assigned clients"
    on public.clients
    for select
    to authenticated
    using (
        archived_at is null
        and exists (
            select 1
            from public.client_assignments as assignment
            where assignment.client_id = clients.id
              and assignment.staff_user_id = (select auth.uid())
        )
    );

create policy "OTM can create clients"
    on public.clients
    for insert
    to authenticated
    with check (
        created_by = (select auth.uid())
        and exists (
            select 1
            from public.staff_profiles as staff
            where staff.user_id = (select auth.uid())
              and staff.role = 'otm'
        )
    );

create policy "OTM can update assigned clients"
    on public.clients
    for update
    to authenticated
    using (
        archived_at is null
        and exists (
            select 1
            from public.staff_profiles as staff
            where staff.user_id = (select auth.uid())
              and staff.role = 'otm'
        )
        and exists (
            select 1
            from public.client_assignments as assignment
            where assignment.client_id = clients.id
              and assignment.staff_user_id = (select auth.uid())
        )
    )
    with check (
        archived_at is null
        and exists (
            select 1
            from public.staff_profiles as staff
            where staff.user_id = (select auth.uid())
              and staff.role = 'otm'
        )
        and exists (
            select 1
            from public.client_assignments as assignment
            where assignment.client_id = clients.id
              and assignment.staff_user_id = (select auth.uid())
        )
    );

grant insert (full_name, age_years, cognitive_level, diet, supplements, restraints, activity_group)
    on table public.clients to authenticated;
grant update (full_name, age_years, cognitive_level, diet, supplements, restraints, activity_group)
    on table public.clients to authenticated;

create function public.assign_client_creator()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if new.created_by is not null then
        insert into public.client_assignments (staff_user_id, client_id, assigned_by)
        values (new.created_by, new.id, new.created_by)
        on conflict (staff_user_id, client_id) do nothing;
    end if;

    return new;
end;
$$;

revoke all on function public.assign_client_creator() from public, anon, authenticated;

create trigger assign_client_creator_after_insert
    after insert on public.clients
    for each row
    execute function public.assign_client_creator();

create function public.archive_client(p_client_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    actor_id uuid := auth.uid();
begin
    if actor_id is null
       or not exists (
            select 1
            from public.staff_profiles as staff
            where staff.user_id = actor_id
              and staff.role = 'otm'
       )
       or not exists (
            select 1
            from public.client_assignments as assignment
            where assignment.staff_user_id = actor_id
              and assignment.client_id = p_client_id
       ) then
        raise exception 'Not authorized to archive this client'
            using errcode = '42501';
    end if;

    update public.clients
    set archived_at = pg_catalog.now(),
        archived_by = actor_id
    where id = p_client_id
      and archived_at is null;

    if not found then
        raise exception 'Client not found or already archived'
            using errcode = 'P0002';
    end if;
end;
$$;

revoke all on function public.archive_client(uuid) from public, anon, authenticated;
grant execute on function public.archive_client(uuid) to authenticated;
