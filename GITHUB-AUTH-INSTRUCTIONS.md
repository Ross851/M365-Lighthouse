# 🔐 GitHub Authentication Instructions

## Option 1: Personal Access Token (Recommended)

1. Go to GitHub Settings: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a name: "PowerReview-Deploy"
4. Select scopes:
   - ✅ repo (all)
   - ✅ workflow (if using GitHub Actions)
5. Click "Generate token"
6. Copy the token immediately (you won't see it again!)

### Using the token:
```bash
# When prompted for username: Ross851
# When prompted for password: paste-your-token-here

# Or set it permanently:
git remote set-url origin https://YOUR_TOKEN@github.com/Ross851/M365-Lighthouse.git
```

## Option 2: GitHub CLI (gh)

```bash
# Install GitHub CLI first
# Then authenticate:
gh auth login

# Then push:
git push -u origin main
```

## Option 3: SSH Key

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Add to GitHub: https://github.com/settings/keys

# Change remote to SSH:
git remote set-url origin git@github.com:Ross851/M365-Lighthouse.git
```

## Quick Push Commands

Once authenticated, run:
```bash
# Initial push
git push -u origin main

# Future pushes
git push
```

## Troubleshooting

If you get errors:
1. Check your token has 'repo' scope
2. Ensure you're using the token as password, not your GitHub password
3. Try: `git config --global credential.helper cache`