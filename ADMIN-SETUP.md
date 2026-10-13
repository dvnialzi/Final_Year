# Children Home admin website: setup guide

About 15 minutes, done once. You need: the website files, and an email address for the first admin.

## Files

| File | What it is |
|---|---|
| `admin.html` | The admin website (login, dashboard, blog) |
| `supabase-config.js` | Where you paste your two Supabase details |
| `supabase-setup.sql` | Creates the database (you paste it into Supabase once) |
| `index.html`, `our-care.html`, `success-stories.html`, `moments.html`, `get-involved.html`, `faq.html` | Your website, now recording visits and showing blog posts |

Put **all of them in the same folder** as your `assets` folder.

## Step 1: Create a free Supabase project

1. Go to **supabase.com** → **Start your project** → sign up (a Google account works).
2. Click **New project**.
   - Name: `children-home`
   - Database password: create a strong one and keep it somewhere safe
   - Region: **Southeast Asia (Singapore)** (closest to Johor Bahru, so it's fastest)
3. Wait about 2 minutes while it's created.

## Step 2: Create the database

1. In the left menu, open **SQL Editor** → **New query**.
2. Open `supabase-setup.sql`, copy **everything**, paste it in, and press **Run**.
3. You should see "Success. No rows returned".

## Step 3: Create your admin login

1. Left menu → **Authentication** → **Users** → **Add user** → **Create new user**.
2. Enter your email and a password (at least 8 characters). Tick **Auto Confirm User**. Click **Create user**.
3. Back in **SQL Editor**, run this (with **your** email):

```sql
insert into public.admins (user_id, email)
select id, email from auth.users where email = 'your-email@example.com'
on conflict do nothing;
```

## Step 4: Lock the door (important)

Left menu → **Authentication** → **Sign In / Providers** (may be called **Settings** in some versions):
- Turn **OFF** "Allow new users to sign up".

This means only people you add in Step 3 can ever have a login.

## Step 5: Connect the website

1. Left menu → **Project Settings** → **API** (or **Data API**).
2. Copy the **Project URL** and the **anon public** key.
3. Open `supabase-config.js` in Notepad and replace the two placeholder values:

```js
window.CH_SUPABASE = {
  url:     'https://abcdefghijk.supabase.co',
  anonKey: 'eyJhbGciOi...the long anon key...'
};
```

> Use the **anon public** key only. Never put the **service_role** key in any website file.

## Step 6: Allow password-reset emails to come back to your site

**Authentication** → **URL Configuration**:
- **Site URL**: your website address, e.g. `https://children.amitabhafoundation.my`
- **Redirect URLs**: add `https://children.amitabhafoundation.my/admin.html`

(Use your real website address.)

## Step 7: Upload and log in

1. Upload all the files (Step 0 list) to your website, next to `assets`.
2. Open `your-website/admin.html`, or click **Staff login** at the bottom of any page.
3. Log in with the email and password from Step 3.

---

## Using the admin website

**Dashboard**: page views, visitors, Donate clicks and WhatsApp chats for the last 7, 30 or 90 days. Also shows which pages are popular, phone vs computer, English vs 中文, which sites send visitors (Facebook, Google…), and which buttons people press.

**Write a post**
1. Add a cover photo (it's shrunk automatically, so phone photos are fine).
2. Choose a category and write the English title, summary and story.
3. Click **中文** to add the Chinese version (optional; Chinese readers see English if it's empty).
4. **Save draft** keeps it private. **Publish** puts it on the **Moments** page straight away.

Story formatting: leave an empty line between paragraphs · start a line with `- ` for a bullet point · start with `## ` for a small heading.

**Blog posts**: search, edit, unpublish or delete posts. Published posts have a link you can share; it opens the post directly on the Moments page.

**My account**: change your password, and instructions for adding another admin.

## Good to know

- **Privacy:** visitor statistics are anonymous: no names, emails or IP addresses are stored, and visitors who switch on "Do Not Track" aren't counted.
- **Free plan:** Supabase's free plan is plenty for this site. Free projects are paused after a week with no activity at all; normal website visits keep it active, and a paused project can be restarted with one click in Supabase.
- **Forgot password:** use "Forgot password?" on the login page, or set a new one in Supabase → Authentication → Users.
