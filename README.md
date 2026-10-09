# Sentfix

<img width="799" height="902" alt="Screenshot 2026-10-09 at 12 15 34 AM" src="https://github.com/user-attachments/assets/e92e69cb-9216-4c02-92e5-7f08ad759beb" />

Sentfix is for editing sentences that are too long, or contain typos and grammar mistakes, especially if you write in English as a second language. It helps you refine your ideas without writing the entire document for you.

- **Fix English** fixes grammar, spelling, and punctuation.
- **Concise** makes the same point shorter for the reader.
- **Teach me** adds a short note about what changed.

Results are cleaned up after 2 minutes, so you do not have to clear a long list the way you do with other chat tools.

## How it works

You paste a sentence or a short paragraph. Sentfix sends it to [Ollama](https://ollama.com) on your own machine at `http://localhost:11434`, and puts the cleaned wording back on the screen. Your tokens stay for your main work.

## Required

You need to download and run [Ollama](https://ollama.com/download) yourself, then pull a model. The app does not install it for you. Ollama has to be running before you start Sentfix.

Note: `llama3.2:3b` is probably enough.

You also need Flutter to run the app (for now).

## Run

```bash
flutter run -d macos
```
