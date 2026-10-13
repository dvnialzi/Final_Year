/* ─────────────────────────────────────────────────────────────────────────
   Amitabha Foundation Children Home: connection to your Supabase database
   Used by admin.html (the admin website) and by every page of the website
   (visitor statistics + blog posts on the Moments page).

   Paste your own two values from:  Supabase → Project Settings → API
     • Project URL               → url
     • Project API keys → "anon public"  → anonKey

   The "anon public" key is designed to be public: the security rules created
   by supabase-setup.sql decide what it can and cannot do.
   NEVER paste the "service_role" key here.
   ───────────────────────────────────────────────────────────────────────── */
window.CH_SUPABASE = {
  url:     'https://yifptjqthfzaeflmfnoy.supabase.co',
  anonKey: 'sb_publishable_kv07vdW-ZlfHDKPMsTdfJw_2L__I7BP'
};
