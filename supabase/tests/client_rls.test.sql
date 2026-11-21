begin;

create extension if not exists pgtap with schema extensions;
select plan(20);

insert into auth.users (id, email)
values
    ('10000000-0000-4000-8000-000000000001', 'staff-a@example.test'),
    ('10000000-0000-4000-8000-000000000002', 'staff-b@example.test'),
    ('10000000-0000-4000-8000-000000000003', 'staff-c@example.test');

insert into public.staff_profiles (user_id, role)
values
    ('10000000-0000-4000-8000-000000000001', 'ot'),
    ('10000000-0000-4000-8000-000000000002', 'ota'),
    ('10000000-0000-4000-8000-000000000003', 'otm');

insert into public.clients (
    id,
    full_name,
    age_years,
    cognitive_level,
    diet,
    supplements,
    restraints,
    activity_group
)
values
    (
        '20000000-0000-4000-8000-000000000001',
        'Synthetic Client A',
        80,
        'Level A',
        null,
        null,
        null,
        'Group A'
    ),
    (
        '20000000-0000-4000-8000-000000000002',
        'Synthetic Client B',
        85,
        'Level B',
        null,
        null,
        null,
        'Group B'
    );

insert into public.client_assignments (staff_user_id, client_id, assigned_by)
values
    (
        '10000000-0000-4000-8000-000000000001',
        '20000000-0000-4000-8000-000000000001',
        '10000000-0000-4000-8000-000000000003'
    ),
    (
        '10000000-0000-4000-8000-000000000002',
        '20000000-0000-4000-8000-000000000002',
        '10000000-0000-4000-8000-000000000003'
    ),
    (
        '10000000-0000-4000-8000-000000000003',
        '20000000-0000-4000-8000-000000000001',
        '10000000-0000-4000-8000-000000000003'
    );

set local role authenticated;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';

select results_eq(
    'select count(*) from public.clients',
    array[1::bigint],
    'Staff member A sees only the assigned client'
);
select is_empty(
    $$select id from public.clients
      where id = '20000000-0000-4000-8000-000000000002'$$,
    'Staff member A cannot see staff member B client'
);
select results_eq(
    'select count(*) from public.client_assignments',
    array[1::bigint],
    'Staff member A sees only their own assignment'
);
select throws_ok(
    $$insert into public.clients (full_name) values ('Synthetic Unauthorized Client')$$,
    '42501'
);
select is_empty(
    $$update public.clients
      set diet = 'Unauthorized change'
      where id = '20000000-0000-4000-8000-000000000001'
      returning id$$,
    'OT staff cannot edit assigned clients'
);
select throws_ok(
    $$select public.archive_client('20000000-0000-4000-8000-000000000001')$$,
    '42501'
);

set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000003';

insert into public.clients (full_name)
values ('Synthetic Client C');
select results_eq(
    $$select full_name from public.clients where full_name = 'Synthetic Client C'$$,
    array['Synthetic Client C'],
    'OTM can create and read a client after assignment'
);
select results_eq(
    'select count(*) from public.clients',
    array[2::bigint],
    'New client is assigned to its OTM creator'
);
select results_eq(
    $$update public.clients
      set diet = 'OTM updated diet'
      where id = '20000000-0000-4000-8000-000000000001'
      returning diet$$,
    array['OTM updated diet'],
    'OTM can edit an assigned client'
);
select is_empty(
    $$update public.clients
      set diet = 'Unauthorized change'
      where id = '20000000-0000-4000-8000-000000000002'
      returning id$$,
    'OTM cannot edit an unassigned client'
);

select public.archive_client('20000000-0000-4000-8000-000000000001');
select ok(true, 'OTM can soft-archive an assigned client');
select is_empty(
    $$select id from public.clients
      where id = '20000000-0000-4000-8000-000000000001'$$,
    'Archived client is hidden from normal staff reads'
);
select throws_ok(
    $$select public.archive_client('20000000-0000-4000-8000-000000000002')$$,
    '42501'
);
select results_eq(
    'select count(*) from public.clients',
    array[1::bigint],
    'OTM sees only its remaining active assigned client'
);

reset role;

select results_eq(
    $$select (archived_at is not null and archived_by = '10000000-0000-4000-8000-000000000003')
      from public.clients
      where id = '20000000-0000-4000-8000-000000000001'$$,
    array[true],
    'Archive timestamp and actor are retained'
);

set local role authenticated;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000002';

select results_eq(
    'select count(*) from public.clients',
    array[1::bigint],
    'Staff member B sees only the assigned client'
);
select is_empty(
    $$select id from public.clients
      where id = '20000000-0000-4000-8000-000000000001'$$,
    'Staff member B cannot see staff member A client'
);

reset role;

select ok(
    not has_table_privilege('authenticated', 'public.clients', 'DELETE'),
    'Authenticated staff cannot physically delete client records'
);
select ok(
    not has_table_privilege('authenticated', 'public.client_assignments', 'INSERT'),
    'Authenticated staff cannot assign themselves to clients'
);
select ok(
    not has_table_privilege('anon', 'public.clients', 'SELECT'),
    'Anonymous users do not have permission to query client records'
);

select * from finish();
rollback;
