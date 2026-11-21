---
description: "Use when implementing authentication flows, route guards, OAuth sign-in/sign-out, or protected routes with async profile data. Covers race condition prevention and state transition testing."
applyTo: "**/contexts/Auth*,**/hooks/useAuth*,**/App.tsx,**/ProtectedRoute*,**/RoleRoute*,**/Login*,**/Onboarding*,**/pages/*Page*"
---
# Auth Flow — Race Conditions & Route Guard Patterns

## The Core Problem

Auth systems with session + profile have TWO async phases:

```
Phase 1: Session resolve  (sync from localStorage, ~0ms)
Phase 2: Profile fetch    (async HTTP round-trip, ~200ms)
```

If you track only one `loading` flag, there's a gap where `session` is truthy but `profile` is null.
Route guards that check `!profile` during this gap misinterpret "still loading" as "needs setup".

## Rules

### Rule 1: One loading flag per async data source

```
session  → loading         (resolves from cache, fast)
profile  → profileLoading  (HTTP fetch, slow)
combined → isReady = !loading && !profileLoading
```

Never collapse independent async operations into a single loading flag.

### Rule 2: Route guards must wait for `isReady`

```tsx
if (!isReady) return <Spinner />                  // wait for ALL async data
if (!session) return <Navigate to={LOGIN} />
if (!profile) return <Navigate to={SETUP} />
return children
```

NEVER redirect based on null data that is still being fetched.

### Rule 3: Post-login page must check profile completeness before redirecting

```tsx
// WRONG — sends incomplete users to home
if (session && !loading) navigate(HOME)

// RIGHT — wait for full state, then route
if (loading || profileLoading) return
if (session && profile) navigate(getHomeRoute(profile.role))
if (session && !profile) navigate(SETUP)
```

The login/callback landing page must wait for BOTH session AND profile to resolve before deciding where to send the user.

### Rule 4: Sign-out must revoke server-side sessions

```tsx
// WRONG — only clears local token, server session persists
await auth.signOut()

// RIGHT — revokes on both client and server
await auth.signOut({ scope: 'global' })  // Supabase
await auth.signOut({ callbackUrl: '/' }) // NextAuth
// Consult your auth provider's docs for server-side revocation
```

Clearing only the local token lets the old server session remain valid — a security hole that also causes stale-session bugs on re-login.

### Rule 5: OAuth must allow account switching

```tsx
// WRONG — provider auto-selects the cached account
await auth.signInWithOAuth({ provider: 'google' })

// RIGHT — forces account picker
await auth.signInWithOAuth({
  provider: 'google',
  options: { queryParams: { prompt: 'select_account' } },
})
```

Without `prompt: 'select_account'` (or equivalent for your provider), users who sign out cannot switch to a different account — the provider silently re-authenticates the previous one.

### Rule 6: Test state transitions, not static snapshots

Unit tests that mock auth state as a single static object miss race conditions entirely.

```tsx
// WRONG — passes but misses the real bug
mockAuth({ session: X, profile: null, loading: false })

// RIGHT — test the transition sequence
const { rerender } = render(<ProtectedRoute>...)
// Step 1: loading=true                      → expect spinner
// Step 2: rerender with profileLoading=true → still spinner
// Step 3: rerender with isReady, profile=data → expect children
// Step 4: rerender with isReady, profile=null → expect setup redirect
```

### Rule 7: Setup/onboarding pages must redirect already-completed users

Any page that shows a setup or onboarding form MUST check for existing profile on mount and redirect if the user already completed setup.

```tsx
// WRONG — always shows the form regardless of profile state
export function SetupPage() {
  return <form>...</form>
}

// RIGHT — redirect if profile already exists
if (!isReady) return <Spinner />
if (!session) return <Navigate to={LOGIN} replace />
if (profile) return <Navigate to={getHomeRoute(profile.role)} replace />
return <form>...</form>
```

This guards against: returning users hitting the setup page via bookmark, back button, or stale OAuth redirect.

### Rule 8: Role-based routing — different roles get different home routes

Define a single `getHomeRoute(role)` utility and use it everywhere a default redirect is needed. NEVER hardcode a single destination for all roles.

```tsx
// WRONG — all roles go to the same place
navigate('/dashboard')

// RIGHT — centralized role-to-route mapping
function getHomeRoute(role?: string): string {
  const routeMap: Record<string, string> = {
    admin: '/admin',
    manager: '/manager/dashboard',
    // ... add project-specific roles
  }
  return routeMap[role ?? ''] ?? '/home'  // fallback for unknown roles
}
navigate(getHomeRoute(profile.role))
```

Role-restricted pages MUST be wrapped in a role guard that checks `profile.role` after `isReady`:

```tsx
function RoleRoute({ children, roles }: { children: React.ReactNode; roles: string[] }) {
  const { session, profile, isReady } = useAuth()
  if (!isReady) return <Spinner />
  if (!session) return <Navigate to={LOGIN} replace />
  if (!profile) return <Navigate to={SETUP} replace />
  if (!roles.includes(profile.role)) return <Navigate to={getHomeRoute(profile.role)} replace />
  return <>{children}</>
}
```

### Rule 9: OAuth callback `redirectTo` must point to app root

After OAuth callback, always redirect to the root origin. Let the app's existing routing logic decide the final destination based on role and profile state.

```tsx
// WRONG — bypasses app routing logic, can cause setup loops
redirectTo: `${origin}/setup`
redirectTo: `${origin}/dashboard`

// RIGHT — lets the router decide
redirectTo: window.location.origin
```

NEVER hardcode a deep link as the OAuth callback target. The post-login page (Rule 3) already handles routing — let it do its job.

## Checklist

- [ ] Session and profile have INDEPENDENT loading flags
- [ ] Route guards show spinner until ALL async is done
- [ ] `isReady` is a single derived boolean (one source of truth for "safe to route")
- [ ] Post-login page checks profile before redirecting
- [ ] Sign-out revokes server-side session (not just local token)
- [ ] OAuth includes account-switching prompt
- [ ] Tests cover state transitions, not just static snapshots
- [ ] Setup/onboarding page redirects away if profile already exists
- [ ] `getHomeRoute(role)` utility used for all default redirects (no hardcoded paths)
- [ ] Role-restricted pages wrapped in a role guard component
- [ ] OAuth `redirectTo` points to root `/` (not a specific page)