# AI assistant: setup and maintenance

A floating chat window for **logged-in members only**, with two modes:

- **Club help**: merch, joining and roles, events, contact. Answers come only from `netlify/lib/club-knowledge.js`.
- **Robotics help**: a robotics tutor.

It runs on the Gemini API through a Netlify Function (`netlify/functions/chat.js`, reached at `/api/chat`). The browser never sees the API keys.

## Limits

| Rule | Value |
|---|---|
| Questions per member | 30 per session, 6:00 AM to the next 6:00 AM IST |
| Unused questions | Expire at 6:00 AM, then the count resets to 30 |
| Speed | 5 questions per minute |
| Question length | 1000 words |
| Answer length | About 600 words at most |
| Counted when | Gemini actually answered (a failed call is refunded) |

The 30 and 5 are fixed inside the SQL functions (`supabase/migrations/020_ai_assistant_usage.sql`). Change them there if you ever need to.

## One-time setup

1. **Run the SQL.** Supabase -> SQL Editor -> run `supabase/migrations/020_ai_assistant_usage.sql`. It only stores counts and times, never questions or answers.
2. **Get a Gemini key.** Google AI Studio -> Get API key. Never paste it into a file in this repo or into a chat or screenshot.
3. **Add environment variables** in Netlify -> your site -> Site configuration -> Environment variables -> Add a variable. Tick the **Functions** scope, and mark each as secret:
   - `GEMINI_API_KEY`: the key from step 2.
   - `SUPABASE_SERVICE_ROLE_KEY`: Supabase -> Project Settings -> API -> the `service_role` key. **Keep it secret.** It bypasses all row security.
   - Optional: `GEMINI_MODEL` (default `gemini-3.5-flash-lite`). Google retires models over time, so if the assistant answers "busy" for everyone, check the current model name in AI Studio and set this.
   - Optional: `AI_TIMEOUT_MS` (default 8000). Netlify stops functions after 10 seconds by default, so Gemini is given 8.
4. **Deploy from Git.** Netlify Functions only deploy when the site is built from a connected Git repository (or the Netlify CLI). Dragging a folder into Netlify Drop publishes the static files but **not** the function. After adding the variables, trigger a new deploy (Deploys -> Trigger deploy), because variables are read at deploy time.
5. **Check it:** Netlify -> Functions should list `chat`. Then ask a question in the chat window while logged in.

## If it doesn't work

- Netlify -> Logs -> Functions -> `chat` shows the error. "missing GEMINI_API_KEY or SUPABASE_SERVICE_ROLE_KEY" means a variable is missing or the site wasn't redeployed.
- A Gemini 401/403 means the key or key type isn't accepted. A 404 usually means the model name is retired (see `GEMINI_MODEL`).

## Keeping answers right

Edit `netlify/lib/club-knowledge.js` whenever prices, contacts, events or rules change, then deploy. Club help says "I don't have that information" for anything not written there.

## Redirects

`netlify.toml` also keeps the old page addresses (for example `/about.html` -> `/pages/about.html`) working, and sends the old Stage pages to the Study Portal.

## Privacy

On the free Gemini tier, Google may use prompts to improve its products. The chat tells members not to share personal details, and the server only sends the question, the last few messages and the page title. No names, emails, XP or other member data are sent.
