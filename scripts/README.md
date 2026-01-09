# Deployment Scripts

Helper scripts for deploying Firebase configuration.

## Available Scripts

### `deploy-indexes-dev.sh`
Deploy Firestore indexes to development environment.
```bash
./scripts/deploy-indexes-dev.sh
```

### `deploy-indexes-prod.sh`
Deploy Firestore indexes to production environment (with confirmation).
```bash
./scripts/deploy-indexes-prod.sh
```

### `deploy-rules-dev.sh`
Deploy Firestore and Storage rules to development environment.
```bash
./scripts/deploy-rules-dev.sh
```

### `deploy-rules-prod.sh`
Deploy Firestore and Storage rules to production environment (with confirmation).
```bash
./scripts/deploy-rules-prod.sh
```

## Using from Android Studio

### Terminal
1. Open Terminal tab (Alt+F12 or View → Tool Windows → Terminal)
2. Run the script:
   ```bash
   ./scripts/deploy-indexes-dev.sh
   ```

### External Tools
1. Go to **File → Settings → Tools → External Tools**
2. Click **+** to add new tool
3. Configure:
   - **Name**: Deploy Indexes (Dev)
   - **Program**: `$ProjectFileDir$/scripts/deploy-indexes-dev.sh`
   - **Working directory**: `$ProjectFileDir$`
4. Access via **Tools → External Tools → Deploy Indexes (Dev)**

## Prerequisites

1. **Firebase CLI installed**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Logged in**:
   ```bash
   firebase login
   ```

3. **Project configured**: Create `.firebaserc` from `.firebaserc.example`

## Notes

- Scripts use project IDs: `maypole-dev` and `maypole-prod`
- Update these in the scripts if your project IDs are different
- Production scripts require confirmation before deploying
- Index deployments may take several minutes to build

## Troubleshooting

**"command not found: firebase"**
- Install Firebase CLI: `npm install -g firebase-tools`

**"Permission denied"**
- Make scripts executable: `chmod +x scripts/*.sh`

**"No project active"**
- Create `.firebaserc` from template
- Or use: `firebase use --add`
