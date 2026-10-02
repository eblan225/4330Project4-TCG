# Animal TCG profile server

Run locally:

```sh
npm install
npm start
```

Open `http://localhost:3000` to confirm the server is running. The browser will
show a short JSON status message and the available routes. Account creation uses
`POST /auth/register`, and sign-in uses `POST /auth/login`. Passwords are stored
as salted hashes in `server/data/accounts.json`, not as readable text.

The Flutter app defaults to `http://localhost:3000`. For a deployed server:

```sh
flutter run --dart-define=API_BASE_URL=https://your-server.example.com
```

Android emulators should use `http://10.0.2.2:3000`. Uploaded images are limited
to 5 MB. This sample uses JSON-file storage for class/demo use; production should
use authentication, object storage, and a database.
