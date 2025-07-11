# GitHub Authentication Methods for WSL/Linux Command Line

## Overview
With GitHub's deprecation of password authentication, developers must choose between SSH keys, Personal Access Tokens (PAT), or GitHub CLI for authentication. This guide compares each method's security, ease of use, and long-term convenience.

## Method 1: SSH Keys

### Pros
- **No credentials on each push**: Once configured, authentication is automatic
- **Highly secure**: Uses public/private key cryptography
- **Never expires**: Keys remain valid until manually revoked
- **Works behind most firewalls**: SSH traffic is common in development environments
- **Multiple keys support**: Can have different keys for different machines
- **No risk of accidental exposure**: Private key never leaves your machine

### Cons
- **Initial setup complexity**: Requires understanding of SSH concepts
- **Key management**: Must manage keys across multiple devices
- **Firewall issues**: Some corporate firewalls block SSH (port 22)
- **No granular permissions**: It's all-or-nothing access
- **Requires SSH agent**: For passphrase-protected keys

### Setup Steps
```bash
# 1. Generate SSH key pair
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. Start SSH agent
eval "$(ssh-agent -s)"

# 3. Add SSH key to agent
ssh-add ~/.ssh/id_ed25519

# 4. Copy public key to clipboard
cat ~/.ssh/id_ed25519.pub

# 5. Add to GitHub
# Go to GitHub Settings → SSH and GPG keys → New SSH key
# Paste the public key

# 6. Test connection
ssh -T git@github.com

# 7. Configure Git to use SSH (if needed)
git remote set-url origin git@github.com:username/repository.git
```

### Best For
- Developers who frequently push code
- Terminal-heavy workflows
- Long-term projects
- Multiple repositories

## Method 2: HTTPS with Personal Access Tokens (PAT)

### Pros
- **Easy to understand**: Works like username/password
- **Works everywhere**: HTTPS is rarely blocked
- **Fine-grained permissions**: Can limit token scope
- **Multiple tokens**: Different tokens for different uses
- **Easy revocation**: Can revoke tokens instantly
- **Audit trail**: GitHub tracks token usage

### Cons
- **Token management**: Must store/remember tokens
- **Expiration**: Tokens expire (security feature but inconvenient)
- **Manual entry**: Need to enter token for each operation (without credential manager)
- **Length**: Tokens are long and hard to type
- **Security risk**: Tokens can be accidentally committed

### Setup Steps

#### Option A: Basic Setup (Manual Entry)
```bash
# 1. Generate PAT on GitHub
# Go to Settings → Developer settings → Personal access tokens → Tokens (classic)
# Or use Fine-grained tokens for better security
# Select scopes: repo, workflow (as needed)

# 2. Clone using token
git clone https://github.com/username/repository.git
# Username: your-github-username
# Password: your-personal-access-token

# 3. For existing repos, update remote URL
git remote set-url origin https://your-github-username:your-token@github.com/username/repository.git
```

#### Option B: With Git Credential Manager (Recommended for WSL)
```bash
# 1. Configure Git to use Windows Credential Manager
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"

# 2. First push will prompt for authentication
git push
# Enter username and PAT when prompted
# Token will be stored securely in Windows Credential Manager

# Alternative: Use credential store (less secure)
git config --global credential.helper store
# Tokens stored in plain text at ~/.git-credentials
```

#### Option C: Using Git Credential Cache (Temporary)
```bash
# Cache credentials for 1 hour
git config --global credential.helper 'cache --timeout=3600'

# Cache for 24 hours
git config --global credential.helper 'cache --timeout=86400'
```

### Best For
- Occasional Git users
- Corporate environments with SSH restrictions
- CI/CD pipelines
- Temporary access needs

## Method 3: GitHub CLI (gh)

### Pros
- **Easiest setup**: One command authentication
- **Automatic token management**: Handles PAT creation/storage
- **Additional features**: PR creation, issue management, etc.
- **Browser-based auth**: Can authenticate via web browser
- **Cross-platform**: Same experience on all platforms
- **Secure storage**: Uses system keychain

### Cons
- **Additional tool**: Requires installing GitHub CLI
- **Limited to GitHub**: Doesn't work with other Git hosts
- **Overhead**: Larger footprint than basic Git
- **Dependency**: Adds another tool to maintain

### Setup Steps
```bash
# 1. Install GitHub CLI
# For Ubuntu/Debian:
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# 2. Authenticate
gh auth login
# Choose: GitHub.com
# Choose: HTTPS
# Choose: Login with web browser (or paste token)

# 3. Configure Git to use gh
gh auth setup-git

# 4. Test
gh auth status
```

### Best For
- GitHub-centric workflows
- Developers who use GitHub features beyond Git
- Beginners
- Quick setups

## Comparison Matrix

| Feature | SSH | PAT (HTTPS) | GitHub CLI |
|---------|-----|-------------|------------|
| **Setup Difficulty** | Medium | Easy-Medium | Easy |
| **Security** | Excellent | Good | Good |
| **Convenience** | Excellent | Good* | Excellent |
| **Maintenance** | Low | Medium | Low |
| **Flexibility** | High | High | Medium |
| **Corporate Friendly** | Sometimes | Yes | Yes |
| **Multi-Host Support** | Yes | Yes | No |
| **Offline Work** | Yes | Yes | Partial |
| **Token Expiration** | No | Yes | Auto-managed |
| **Permission Granularity** | No | Yes | Yes |

*With credential manager

## Recommendations by Use Case

### For Individual Developers
1. **Primary**: SSH keys with passphrase
2. **Secondary**: GitHub CLI for GitHub-specific tasks
3. **Fallback**: PAT with credential manager

### For Corporate/Restricted Environments
1. **Primary**: HTTPS with PAT + credential manager
2. **Secondary**: GitHub CLI if allowed
3. **Note**: Check with IT about SSH availability

### For CI/CD and Automation
1. **Primary**: Fine-grained PATs with minimal permissions
2. **Secondary**: Deploy keys (SSH) for read-only access
3. **Avoid**: GitHub CLI (unnecessary overhead)

### For Beginners
1. **Primary**: GitHub CLI
2. **Secondary**: HTTPS with PAT
3. **Learn Later**: SSH keys

## Security Best Practices

### For SSH Keys
- Always use a strong passphrase
- Use Ed25519 or RSA-4096 keys
- Keep private keys secure
- Use different keys for different machines
- Regularly audit authorized keys on GitHub

### For Personal Access Tokens
- Use fine-grained tokens when possible
- Set expiration dates (90 days recommended)
- Limit scope to minimum required permissions
- Never commit tokens to repositories
- Use different tokens for different purposes
- Revoke unused tokens immediately

### For GitHub CLI
- Keep CLI updated
- Regularly check `gh auth status`
- Use `gh auth logout` on shared machines
- Review connected devices in GitHub settings

## Troubleshooting Tips

### SSH Issues
```bash
# Debug SSH connection
ssh -vT git@github.com

# Check SSH agent
ssh-add -l

# Common fix for "Permission denied"
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### PAT Issues
```bash
# Clear cached credentials
git config --global --unset credential.helper

# Check current helper
git config --global credential.helper

# Test token
curl -H "Authorization: token YOUR_PAT" https://api.github.com/user
```

### GitHub CLI Issues
```bash
# Refresh authentication
gh auth refresh

# Check status
gh auth status

# Re-login
gh auth logout
gh auth login
```

## Conclusion

- **SSH**: Best for developers who want set-and-forget authentication
- **PAT with Credential Manager**: Best balance of security and compatibility
- **GitHub CLI**: Best for beginners and GitHub-heavy workflows

Choose based on your specific needs, but consider setting up multiple methods for flexibility. SSH + GitHub CLI is a powerful combination for most developers.