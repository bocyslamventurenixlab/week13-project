-- Provisional OT client fields derived from the project brief.
-- Validate names, types, history, and permissions against an anonymized workbook before real import.
create table public.clients (
    id uuid primary key default gen_random_uuid(),
    full_name text not null check (char_length(btrim(full_name)) > 0),
    age_years integer check (age_years is null or age_years >= 0),
    cognitive_level text,
    diet text,
    supplements text,
    restraints text,
    activity_group text,
    created_at timestamptz not null default now()
);

comment on table public.clients is
    'Provisional OT client record. Validate fields and history against source workbooks before production import.';

create table public.client_assignments (
    staff_user_id uuid not null references auth.users (id) on delete cascade,
    client_id uuid not null references public.clients (id) on delete cascade,
    assigned_by uuid references auth.users (id) on delete set null,
    assigned_at timestamptz not null default now(),
    primary key (staff_user_id, client_id)
);

comment on table public.client_assignments is
    'Provisional access boundary: authenticated staff can read only clients explicitly assigned to them.';

create index client_assignments_client_id_idx
    on public.client_assignments (client_id);

alter table public.clients enable row level security;
alter table public.client_assignments enable row level security;

revoke all on table public.clients, public.client_assignments
    from public, anon, authenticated;

grant select on table public.clients, public.client_assignments to authenticated;
grant all on table public.clients, public.client_assignments to service_role;

create policy "Staff can view assigned clients"
    on public.clients
    for select
    to authenticated
    using (
        exists (
            select 1
            from public.client_assignments as assignment
            where assignment.client_id = clients.id
              and assignment.staff_user_id = (select auth.uid())
        )
    );

create policy "Staff can view their own assignments"
    on public.client_assignments
    for select
    to authenticated
    using (staff_user_id = (select auth.uid()));
