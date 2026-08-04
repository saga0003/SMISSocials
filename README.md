# SMIS Socials V3

Standalone social-media planning, approval, account-management and scheduling workspace for St. Mary's.

## V3 additions
- Dedicated standalone repository
- Optional Supabase production mode
- Real email/password authentication
- Shared posts, accounts and destination assignments
- Role-based database policies
- Administrator-only social account management
- Demo-mode fallback for immediate UI testing

## Local test
Open `index.html`, or run:

```bash
python -m http.server 8080
```

## Production setup
1. Create a new Supabase project in `ap-south-1`.
2. Run `supabase.sql` in SQL Editor.
3. In Authentication, create the first user.
4. Change that user's role to `admin` in the `profiles` table.
5. Copy `config.example.js` to `config.js`.
6. Add the Supabase URL and publishable key; set `DEMO_MODE: false`.
7. Deploy the repository to Vercel with framework preset `Other`.

Do not put service-role keys or social OAuth secrets in `config.js`.
