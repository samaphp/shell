# Secure SSH: Replace Root Login with Sudo User (Lockout-Safe)

⚠️ **IMPORTANT**
- Keep your current **root SSH session OPEN** until the very end.
- Do **NOT** reload or restart SSH until validation steps succeed.

---

## 1. Create a new admin user (as root)

```bash
adduser admin
usermod -aG sudo admin
groups admin
```

✅ Expected: output of groups to includes `sudo`

---

## 2. Add your SSH key to the new user

From your local machine:

```bash
ssh-copy-id -p 22 admin@SERVER_IP
```

OR manually (on server):

```bash
mkdir -p /home/admin/.ssh
chmod 700 /home/admin/.ssh
nano /home/admin/.ssh/authorized_keys
chmod 600 /home/admin/.ssh/authorized_keys
chown -R admin:admin /home/admin/.ssh
```

Paste the same public key you used for root.

---

## 3. Validate admin SSH login (DO NOT SKIP)

Open a new terminal (keep root session open):

```bash
ssh -p 22 admin@SERVER_IP
```

✅ Must log in without password

---

## 4. Validate sudo access

```bash
sudo -i
```

✅ Must become root
❌ If this fails → STOP

Exit back:

```bash
exit
```

---

## 5. Disable insecure SSH options

Edit:

```bash
nano /etc/ssh/sshd_config
```

Set exactly:

```conf
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Optional:

```conf
AllowUsers admin
```

---

## 6. Validate config BEFORE reload

```bash
sshd -t
```

✅ No output = valid

---

## 7. Reload SSH safely

```bash
systemctl reload ssh
```

---

## 8. Final verification

Root must FAIL:

```bash
ssh -p 22 root@SERVER_IP
```

Admin must WORK:

```bash
ssh -p 22 admin@SERVER_IP
sudo -i
```

---

## 9. Close old root session

Only after everything passes.

---

## Rollback

```bash
nano /etc/ssh/sshd_config
systemctl reload ssh
```

---

## Confirmation

This output is the ground truth — not the contents of sshd_config:
```
sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication'
```

You should see these values:
```
permitrootlogin no
passwordauthentication no
pubkeyauthentication yes
```

If you see different values, then run this command and see which file are overriding your values:
```
grep -RInH \
  -E '^\s*(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)\b' \
  /etc/ssh/sshd_config.d/
```
