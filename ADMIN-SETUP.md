# Admin dashboard: setup guide

About 10 minutes, done once. After this you manage everything from one login page: visitor statistics, your **campaigns** (add, update progress, end, delete) and your **blog posts** (write, publish, edit, delete).

## Files to upload (all in the same folder as `assets`)

| File | What it is |
|---|---|
| `admin.html` | The admin dashboard (statistics, campaigns, blog posts) |
| `supabase-config.js` | Your two Supabase details. **If you already filled yours in, keep your copy; don't overwrite it with the blank one.** |
| `campaign.js` | **Optional.** Backup numbers, only used if the database can't be reached. The website works without it. |
| `index.html`, `our-care.html`, `success-stories.html`, `moments.html`, `blog.html`, `get-involved.html`, `faq.html` | Your website |

`supabase-setup.sql` and this guide are only for setup: you do not need to upload them.

## Step 1: Create the database tables

1. Open your Supabase project → left menu **SQL Editor** → **New query**.
2. Open `supabase-setup.sql`, copy **everything**, paste it in, press **Run**.
3. You should see "Success. No rows returned". It is safe to run again, and safe on top of the earlier setup files. **Your existing campaign, blog posts and statistics are kept.**
4. To check, run `select name_en, goal, raised, status, featured from public.campaigns;`: it should list your campaign.

## Step 2: Create your admin login (skip if you already did)

1. **Authentication → Users → Add user → Create new user**. Enter your email and a strong password (12+ characters). Tick **Auto Confirm User**.
2. In **SQL Editor**, run this with **your** email:

```sql
insert into public.admins (user_id, email)
select id, email from auth.users where email = 'your-email@example.com'
on conflict do nothing;
```

To add another staff member later, create their user and run the same lines with their email.

## Step 3: Lock the door (skip if you already did)

**Authentication → Sign In / Providers** (or **Settings**): switch **OFF** "Allow new users to sign up". Then only people you add can ever have a login.

## Step 4: Connect the website (skip if you already did)

1. **Project URL:** the green **Connect** button in Supabase, or **Project Settings → Data API**. It looks like `https://abcdefghijk.supabase.co`.
2. **Publishable key:** **Project Settings → API Keys** → copy the key that starts with `sb_publishable_`.
3. Paste both into `supabase-config.js`.

> Use the **Publishable key** only. **Never** put the **Secret key** (`sb_secret_…`) in any website file.

## Step 5: Upload and log in

1. Upload the files above to GitHub (**Add file → Upload files → Commit changes**).
2. Open `your-website/admin.html`, or click the small **Staff login** link at the very bottom of any page.

---

## Using the dashboard

**Dashboard:** page views, visitors, Donate clicks and WhatsApp chats for the last 7, 30 or 90 days; most viewed pages; phone vs computer; English vs 中文; where visitors come from; which buttons they press. At the top you also see the campaign currently shown at the front of your website.

> Visits from a browser where you have logged in to the dashboard are **not counted**, so your own checking doesn't inflate the numbers.

**Blog posts**
- **Write a post** (top right, or the Blog posts page): add a cover photo, pick a category, and write the title, short summary and story in English and 中文. A live preview shows how it will look.
- **Formatting in the story:** leave an empty line between paragraphs, start a line with `- ` for a bullet point, or with `## ` for a small heading.
- **Save draft** keeps it private. **Publish** puts it on the **Blog** page straight away, newest first, under its category. Each post has its own share link.
- Open a post later to **Update** it, **Unpublish** it (back to a draft) or **Delete** it. If you leave a post with unsaved changes, the dashboard asks first.
- Posts you write in the dashboard appear after the campaigns and before the older posts written inside `blog.html`. Those older ones stay as they are.

**Campaigns**
- **New campaign** (top right): add a photo, the name and summary (English and 中文), the goal, an optional last day, and an optional amount already raised. Tick "Show it at the front of the website" to make it the campaign visitors see on the Home and Blog pages.
- **Manage** a campaign:
  - **Update progress:** tap +RM50, +RM100… or type an amount and a note, then **Add to total**. Or set the total directly.
  - **Show at the front:** only one campaign is at the front at a time.
  - **End campaign:** it leaves the front of the website and moves, with the amount raised, into the **Campaign Archive on the Moments page**. Write a thank-you first under "Thank-you / result for the archive". You can **Reopen** it later.
  - **Delete:** removes the campaign completely (it asks twice if money is recorded). To keep a record, use End campaign instead.
- **Activity log:** every change (created, amount, goal, ended, reopened, deleted) is recorded by the database with who and when. It can't be edited, and it stays even after a campaign is deleted.

**What visitors see:**
- The campaign **shown at the front** appears in the big box on the Home page and at the top of the Blog page. If there is none, that box simply disappears.
- **Published blog posts** appear on the **Blog** page too.
- **Every active campaign** also appears on the **Blog** page as its own card (with its photo, progress bar and Donate button), under the "Campaign" filter. The one at the front comes first.
- **Ended** campaigns leave the Blog and move into the Campaign Archive on the Moments page.
- **Delete** removes a campaign from everywhere. If the database can't be reached, the website quietly shows the backup numbers in `campaign.js`.

## If something goes wrong

- **A campaign I added doesn't show on the website:** check that `supabase-config.js` on your website has your real Project URL and key (not the `YOUR-PROJECT-ID` placeholders), then refresh with Ctrl + F5. Only the campaign marked "Shown at the front" appears in the big box; any active campaign appears as a card on the Blog page.
- **"Could not find the function public.campaign_add … in the schema cache", or no campaigns appear:** run `supabase-setup.sql` again (Step 1).
- **The SQL shows a red error:** copy the error text and send it to whoever is helping you. Nothing is harmed, and you can run the file again.
- **"This account doesn't have admin access yet":** run the `insert into public.admins …` lines from Step 2 with that email.
- **"Wrong email or password":** reset it in Supabase under Authentication → Users, or use "Forgot password?".
- **Photos won't upload:** run `supabase-setup.sql` again; it creates the photo storage for campaigns and blog posts.
- **A post I published doesn't show on the Blog page:** check it says "Published" (not "Draft") in the Blog posts list, that `supabase-config.js` on your website has your real details, and refresh with Ctrl + F5.

## Good to know

- **Use real figures** from your bank or receipts. Campaign amounts are public.
- **Change your password** (Authentication → Users) if you have ever typed it anywhere else, such as in a chat.
- Older tables from the earlier versions (blog posts, the single campaign) are harmless; the single campaign is carried over and its old table is removed automatically.
- Supabase's free plan is plenty for this. A free project with no activity for a week may be paused; one click in Supabase restarts it.