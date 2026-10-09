# Sentfix

Sentfix is for when you already know what you want to say. If you are writing in English as a second language, a sentence can run too long, or a typo and a grammar slip can get in the way. This app only cleans that up. It does not write the document for you, and the idea is still yours.

- **Fix English** fixes grammar, spelling, and punctuation.
- **Concise** makes the same point shorter for the reader.
- **Teach me** adds a short note about what changed.

Results are cleaned up after 2 minutes, so you do not have to clear a long list the way you do with other chat tools.

## How it works

You paste a sentence or a short paragraph. Sentfix sends it to [Ollama](https://ollama.com) on your own machine at `http://localhost:11434`, and puts the cleaned wording back on the screen. Your tokens stay for your main work.

## Required

You need to download and run [Ollama](https://ollama.com/download) yourself, then pull a model. The app does not install it for you. Ollama has to be running before you start Sentfix.

Note: `ollama pull llama3.2:3b` is probably enough.

You also need Flutter to run the app (for now).

## Run

```bash
flutter run -d macos
```
