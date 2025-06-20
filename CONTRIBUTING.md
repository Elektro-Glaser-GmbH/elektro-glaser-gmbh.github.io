# 💡 Beiträge zur Website der Elektro-Glaser GmbH

Vielen Dank für dein Interesse, an diesem Projekt mitzuwirken!  
Dieses Repository enthält die öffentliche GitHub Pages-Website der **Elektro-Glaser GmbH**.  
Wir freuen uns über Vorschläge, Korrekturen und neue Inhalte.

---

## 🛠️ Wie du beitragen kannst

- Tippfehler oder Formulierungen verbessern
- Neue Inhalte oder Projektseiten hinzufügen
- Verbesserung der Seitenstruktur oder Navigation
- Vorschläge für technische oder gestalterische Änderungen

---

## 🔀 Vorgehen bei Pull Requests

1. Forke dieses Repository.
2. Erstelle einen Branch mit einem beschreibenden Namen (`fix/impressum-link`, `feature/neues-projekt`).
3. Nimm deine Änderungen vor.
4. Erstelle einen Pull Request (PR) gegen den Branch `main`.

---

## 📄 Formatvorgaben

- Nutze **Markdown (`.md`)** für Seiteninhalte.
- Halte Texte möglichst sachlich, barrierearm und verständlich.
- Nutze nur relative Links für interne Verweise.
- Bilder bitte im Ordner `assets/` ablegen und verlinken.

---

## 🧪 Lokales Testen

Du kannst deine Markdown-Dateien z. B. mit VS Code und der Erweiterung `Markdown Preview Enhanced` live ansehen.

Um die Pre-Commit-Checks lokal auszuführen benötigst Du ein paar Tools (die ich evtl. bald in einen devcontainer hier packe):

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 24
node -v # Should print "v24.2.0".
nvm current # Should print "v24.2.0".
npm -v # Should print "11.3.0".
npm install -g markdownlint-cli
npm install -g cspell @cspell/dict-de-de
pipx install pre-commit vale
vale sync
# pre-commit install # (evtl.)
pre-commit run --all-files
```

---

## 🤝 Code of Conduct

Alle Beiträge unterliegen dem [Code of Conduct](CODE_OF_CONDUCT.md), den wir in Kürze ergänzen werden.

---

## ❓ Fragen oder Ideen?

Du kannst gerne eine [Discussion](https://github.com/Elektro-Glaser-GmbH/elektro-glaser-gmbh.github.io/discussions) starten oder ein [Issue](https://github.com/Elektro-Glaser-GmbH/elektro-glaser-gmbh.github.io/issues) eröffnen.

Danke für deinen Beitrag!
