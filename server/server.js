const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const express = require('express');
const cors = require('cors');
const multer = require('multer');

const app = express();
const port = Number(process.env.PORT || 3000);
const uploadDir = path.join(__dirname, 'uploads');
const dataDir = path.join(__dirname, 'data');
const profileFile = path.join(dataDir, 'profiles.json');
const accountFile = path.join(dataDir, 'accounts.json');
fs.mkdirSync(uploadDir, { recursive: true });
fs.mkdirSync(dataDir, { recursive: true });

const storage = multer.diskStorage({
  destination: uploadDir,
  filename: (_request, file, done) => {
    const extension = path.extname(file.originalname).toLowerCase() || '.jpg';
    done(null, `${crypto.randomUUID()}${extension}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_request, file, done) =>
    done(null, file.mimetype.startsWith('image/')),
});

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(uploadDir));

app.get('/', (_request, response) => {
  response.json({
    message: 'Animal TCG profile server is running',
    health: '/health',
    register: 'POST /auth/register',
    login: 'POST /auth/login',
    createProfile: 'POST /profiles',
    getProfile: 'GET /profiles/:id',
  });
});

const readProfiles = () => {
  if (!fs.existsSync(profileFile)) return [];
  return JSON.parse(fs.readFileSync(profileFile, 'utf8'));
};
const writeProfiles = (profiles) =>
  fs.writeFileSync(profileFile, JSON.stringify(profiles, null, 2));

const readAccounts = () => {
  if (!fs.existsSync(accountFile)) return [];
  return JSON.parse(fs.readFileSync(accountFile, 'utf8'));
};
const writeAccounts = (accounts) =>
  fs.writeFileSync(accountFile, JSON.stringify(accounts, null, 2));
const hashPassword = (password, salt) =>
  new Promise((resolve, reject) => {
    crypto.scrypt(password, salt, 64, (error, key) => {
      if (error) reject(error);
      else resolve(key.toString('hex'));
    });
  });
const publicAccount = (account) => ({
  id: account.id,
  username: account.username,
});

app.post('/auth/register', async (request, response, next) => {
  try {
    const username = String(request.body.username || '').trim();
    const password = String(request.body.password || '');
    if (!/^[a-zA-Z0-9_]{3,20}$/.test(username)) {
      return response.status(400).json({
        error: 'Username must be 3-20 letters, numbers, or underscores.',
      });
    }
    if (password.length < 6 || password.length > 128) {
      return response.status(400).json({
        error: 'Password must be between 6 and 128 characters.',
      });
    }

    const accounts = readAccounts();
    if (accounts.some((item) => item.username.toLowerCase() === username.toLowerCase())) {
      return response.status(409).json({ error: 'That username is already taken.' });
    }

    const salt = crypto.randomBytes(16).toString('hex');
    const account = {
      id: crypto.randomUUID(),
      username,
      salt,
      passwordHash: await hashPassword(password, salt),
      createdAt: new Date().toISOString(),
    };
    accounts.push(account);
    writeAccounts(accounts);
    response.status(201).json({
      message: 'Account created.',
      account: publicAccount(account),
    });
  } catch (error) {
    next(error);
  }
});

app.post('/auth/login', async (request, response, next) => {
  try {
    const username = String(request.body.username || '').trim();
    const password = String(request.body.password || '');
    const account = readAccounts().find(
      (item) => item.username.toLowerCase() === username.toLowerCase(),
    );
    if (!account) {
      return response.status(401).json({ error: 'Invalid username or password.' });
    }

    const suppliedHash = Buffer.from(await hashPassword(password, account.salt), 'hex');
    const savedHash = Buffer.from(account.passwordHash, 'hex');
    const valid =
      suppliedHash.length === savedHash.length &&
      crypto.timingSafeEqual(suppliedHash, savedHash);
    if (!valid) {
      return response.status(401).json({ error: 'Invalid username or password.' });
    }
    response.json({ message: 'Signed in.', account: publicAccount(account) });
  } catch (error) {
    next(error);
  }
});

app.get('/health', (_request, response) => response.json({ status: 'ok' }));

app.get('/profiles/:id', (request, response) => {
  const profile = readProfiles().find((item) => item.id === request.params.id);
  if (!profile) return response.status(404).json({ error: 'Profile not found' });
  response.json(profile);
});

app.post('/profiles', upload.single('avatar'), (request, response) => {
  const displayName = String(request.body.displayName || '').trim();
  const bio = String(request.body.bio || '').trim();
  if (!displayName || displayName.length > 30 || bio.length > 160) {
    return response.status(400).json({ error: 'Invalid profile fields' });
  }
  const id = crypto.randomUUID();
  const origin = `${request.protocol}://${request.get('host')}`;
  const profile = {
    id,
    displayName,
    bio,
    avatarUrl: request.file ? `${origin}/uploads/${request.file.filename}` : null,
    createdAt: new Date().toISOString(),
  };
  const profiles = readProfiles();
  profiles.push(profile);
  writeProfiles(profiles);
  response.status(201).json(profile);
});

app.use((error, _request, response, _next) => {
  const status = error instanceof multer.MulterError ? 400 : 500;
  response.status(status).json({ error: error.message });
});

app.listen(port, () => {
  console.log(`Animal TCG profile server listening on http://localhost:${port}`);
});
