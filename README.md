# Deploy OJS on Render (Testing Environment)

One-click deploy OJS 3.4 with PostgreSQL for testing.

## Prerequisites

- A [Render](https://render.com) account (free tier works)
- Git installed on your machine

## Option 1: One-Click Deploy (Easiest)

Push these files to a GitHub/GitLab repo, then:

1. Log in to [dashboard.render.com](https://dashboard.render.com)
2. Click **New +** → **Blueprint**
3. Connect your GitHub repo containing `render.yaml`
4. Click **Apply**
5. Wait 5-10 minutes for build & deploy
6. Open `https://ojs-journal.onrender.com` in browser

## Option 2: Manual Deploy

### Step 1: Push to GitHub

```bash
cd V:/Kireet\ Sir/render-deploy
git init
git add .
git commit -m "OJS Render deployment"
# Create a GitHub repo and push:
git remote add origin https://github.com/YOUR_USER/ojs-journal.git
git push -u origin main
```

### Step 2: Deploy on Render

1. Go to [dashboard.render.com](https://dashboard.render.com)
2. Click **New +** → **Web Service**
3. Connect your GitHub repo
4. Set these values:
   - **Name:** `ojs-journal`
   - **Environment:** `Docker`
   - **Plan:** Free or Starter ($7/mo)
   - **Branch:** `main`
5. Click **Advanced** → **Add Environment Variable**:
   - `OJS_BASE_URL` = `https://ojs-journal.onrender.com`
6. Click **Create Web Service**

### Step 3: Create PostgreSQL Database

1. Go to [dashboard.render.com](https://dashboard.render.com)
2. Click **New +** → **PostgreSQL**
3. **Name:** `ojs-postgres`
4. **Database:** `ojs_db`
5. **User:** `ojs_user`
6. **Plan:** Free
7. Click **Create Database**

### Step 4: Link Database to Web Service

1. Go to your Web Service dashboard → **Environment**
2. Add these variables (copy values from your PostgreSQL dashboard):

| Key | Value (from PostgreSQL dashboard) |
|---|---|
| `DATABASE_HOST` | Internal Connection String → Hostname |
| `DATABASE_PORT` | `5432` |
| `DATABASE_NAME` | `ojs_db` |
| `DATABASE_USER` | `ojs_user` |
| `DATABASE_PASSWORD` | Internal Connection String → Password |
| `DATABASE_DRIVER` | `pgsql` |
| `OJS_BASE_URL` | `https://ojs-journal.onrender.com` |

3. Click **Save Changes** → Web Service will auto-redeploy

### Step 5: Complete OJS Web Installer

1. Open `https://ojs-journal.onrender.com` in your browser
2. You should see the OJS Installer page
3. Fill in:
   - **Database driver:** PostgreSQL
   - **Host:** (auto-filled from env vars)
   - **Username:** (auto-filled)
   - **Password:** (auto-filled)
   - **Database name:** (auto-filled)
4. **Journal Settings:**
   - Journal title: (your journal name)
   - Editor-in-Chief: (your name)
   - Contact email: editor@yourjournal.org
5. **Admin Account:**
   - Username: admin
   - Password: (choose a strong one)
6. Click **Install OJS**
7. After completion, delete installer:
   ```bash
   # Render Shell tab → run:
   rm -rf /var/www/ojs/installer
   ```

## Step 6: Custom Domain (Optional)

1. Go to Web Service → **Settings** → **Custom Domain**
2. Add `yourjournal.org`
3. Update DNS: Add CNAME record pointing to `ojs-journal.onrender.com`
4. SSL is handled automatically by Render

## File Structure

```
render-deploy/
├── Dockerfile          # OJS + Nginx + PHP 8.1
├── nginx.conf          # Nginx config for OJS
├── supervisord.conf    # Process manager
├── entrypoint.sh       # Runtime config generator
├── render.yaml         # Blueprint deploy config
└── README.md           # This file
```

## Limitations (Free/Starter Plan)

| Aspect | Limitation | Production Fix |
|---|---|---|
| Storage | Ephemeral disk (files lost on restart) | Use Render Disks ($12/mo) or S3 plugin |
| Sleep | Free plan sleeps after 15 min idle | Upgrade to Starter ($7/mo) |
| RAM | Free: 512MB, Starter: 512MB | Professional ($12/mo): 1GB |
| Database | Free: 256MB RAM, 1GB storage | Starter ($7/mo): 1GB RAM, 10GB |
| File uploads | Max 100MB | Configured in nginx.conf |

## Moving to Production

When ready for production:

1. **Switch to DigitalOcean VPS** ($12/mo, full control)
2. Use the `install_ojs.sh` script from the main guide
3. Set up proper domain, SSL, and email
4. Migrate database:
   ```bash
   pg_dump -h render-host -U ojs_user ojs_db > ojs_backup.sql
   # Import on new server:
   psql -h new-server -U ojs_user ojs_db < ojs_backup.sql
   ```

## Testing Checklist

- [ ] `https://ojs-journal.onrender.com` loads OJS installer
- [ ] Web installer completes successfully
- [ ] Can log in as admin
- [ ] Can create a test submission
- [ ] Database persists data across restarts
- [ ] Email notifications work (after SMTP config)

---

*Part of Scopus Journal Setup Guide — Render Testing Environment*
*Last updated: June 2026*
