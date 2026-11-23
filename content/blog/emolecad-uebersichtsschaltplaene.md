---
title: "Schaltpläne als Text: EMoleCAD zeichnet Übersichtspläne aus YAML"
description: "EMoleCAD ist ein kleines Open-Source-Tool im Browser: Die Anlage wird als YAML oder im grafischen Editor beschrieben, daraus entstehen einpolige und allpolige Übersichtsschaltpläne als SVG und PDF – samt Plausibilitätsprüfung."
date: 2026-11-23
categories: ["Tools", "Open Source", "PV", "Dokumentation"]
author: "Daniel Glaser"
---

Jede Anlage, die wir anfassen, braucht einen Übersichtsschaltplan. Für die Anmeldung beim Netzbetreiber,
für die Dokumentation beim Kunden und nicht zuletzt für uns selbst, wenn wir in zwei Jahren wieder vor
dem Zählerschrank stehen.

Die klassischen CAD-Programme können das natürlich. Aber mal ehrlich: Für einen Zählerschrank mit
ein paar Abgängen klicke ich mich ungern eine Stunde durch Symbolbibliotheken, verschiebe Linien um
zwei Millimeter und pflege die Stromkreistabelle von Hand nach. Und wenn sich dann ein Querschnitt
ändert, geht das Spiel von vorne los.

Also habe ich mir, wie so oft, selbst etwas gebaut.

---

## Die Idee: Die Anlage beschreiben, nicht zeichnen

**EMoleCAD** dreht den Spieß um. Ich beschreibe, *was* verbaut ist und *wie* es zusammenhängt.
Wie das auf dem Blatt aussieht, rechnet das Tool selbst aus.

Die Beschreibung ist eine einfache YAML-Datei. Jede Komponente bekommt ein Kennzeichen, einen Typ und
ihre Quelle, also das Gerät, an dem sie hängt:

```yaml
komponenten:
  - { id: XD1, typ: hausanschluss, params: { sicherung: 63, sicherungstyp: NH00 gG } }
  - { id: WD1, typ: sammelschiene, quelle: XD1 }
  - { id: FC1, typ: sls, quelle: WD1, params: { nennstrom: 50 } }
  - { id: PG1, typ: zaehler, quelle: FC1, params: { art: Zweirichtung } }
  - { id: XD2, typ: hlak, quelle: PG1 }
  - { id: FB1, typ: rcd, quelle: XD2, params: { nennstrom: 40, fehlerstrom: 30, rcdtyp: A } }
  - { id: FC5, typ: ls, quelle: FB1, phase: L1, params: { charakteristik: B, nennstrom: 10 } }
  - { id: EA1, typ: verbraucher, name: Licht EG, quelle: FC5, params: { verwendung: Beleuchtung } }
```

Daraus entsteht der Baum der Anlage, und aus dem Baum der Plan. Wer lieber mit der Maus arbeitet, nimmt
den grafischen Editor im Stil von Node-RED: Bausteine aus der Bibliothek auf die Fläche ziehen,
verbinden, fertig. YAML und Editor sind nur zwei Ansichten auf dieselben Daten, man kann jederzeit
zwischen beiden wechseln.

![Grafischer Editor von EMoleCAD mit geöffneter Detailansicht des Hausanschlusses -XD1](/img/blog/emolecad/emolecad-editor-hak.webp)

So sieht das im Browser aus: Links liegt die Bibliothek mit allen Bausteinen, in der Mitte der Baum
der Anlage vom Hausanschluss über Zähler und HLAK bis zu den FI-Gruppen. Die Planansicht ist hier
eingeklappt, sie steht sonst rechts daneben und baut sich bei jeder Änderung sofort neu auf.
Ein Klick auf einen Baustein öffnet seine Eigenschaften, hier der Hausanschlusskasten `-XD1` mit
Vorsicherung NH00 gG 63 A, Netzbetreiber und der Verbindung zur Potentialausgleichsschiene.
Datenleitungen wie LMN, CLS und Modbus erscheinen violett, der Potentialausgleich grün, und oben
rechts meldet die Prüfung „Keine Probleme“.

## Was hinten rauskommt

- **Einpoliger und allpoliger Übersichtsschaltplan** aus derselben Beschreibung, umschaltbar mit einem Klick
- **Stromkreistabelle** mit Schutzorgan, FI, Anschluss, Kabeltyp, Querschnitt, Länge und Produkt
- **Blattvorlagen** in A3 oder A4 mit Schriftfeld und Planquadraten, auf Wunsch mit eigenem Logo
- **Folgeblätter mit Querverweisen**, wenn eine Verteilung nicht mehr auf ein Blatt passt
- **Datenverbindungen** wie LMN, CLS, Modbus oder 4…20 mA und der **Potentialausgleich** in eigenen Farben
- **Export** als SVG und PDF
- **Kennzeichnung nach DIN EN IEC 81346-2**, Schaltzeichen nach DIN EN 60617

Und weil die Anlage als Daten vorliegt, kann EMoleCAD sie auch **prüfen**: fehlende Quellen, Kreise,
doppelte Kennzeichen, Phasenkonflikte oder eine Schieflast über 4,6 kVA werden gemeldet, bevor das
Blatt beim Netzbetreiber landet.

## Ein Beispiel: das typische Einfamilienhaus

Damit das nicht so abstrakt bleibt, hier ein Zählerschrank, wie er heute in vielen Neubauten und
Sanierungen steht:

- **Hausanschlusskasten**, Überspannungsschutz und **Potentialausgleich**, auch direkt an PV-Generator,
  Wechselrichter und Speicher,
- **ein Zweirichtungszähler** mit **Smart-Meter-Gateway** und **Steuerbox** im ungezählten Bereich,
- der **Energiezähler des Wechselrichters** (Smart Meter, per Modbus angebunden) zwischen Zähler und **HLAK**,
- **PV-Anlage** mit Hybrid-Wechselrichter und **Batteriespeicher**,
- **Wärmepumpe** und **Wallbox**, beide steuerbar nach § 14a EnWG,
- Licht und Steckdosen, aufgeteilt auf **zwei FI-Gruppen** (Erdgeschoss und Obergeschoss), dazu der **Elektroherd**,
- und je ein eigener **FI/LS** für Kühlschrank und Gefriertruhe, damit nicht ein Fehler irgendwo im
  Haus gleich die Tiefkühlpizza auftaut.

![Einpoliger Übersichtsschaltplan eines Einfamilienhauses mit PV, Speicher, Wärmepumpe und Wallbox, erzeugt mit EMoleCAD](/img/blog/emolecad/efh-beispiel-einpolig.svg)

Die komplette Beschreibung dieser Anlage sind rund 80 Zeilen YAML. Die Datei könnt ihr euch
[hier herunterladen](/img/blog/emolecad/efh-beispiel.yaml){download="efh-beispiel.yaml" external}
und direkt in EMoleCAD öffnen.

Aus genau derselben Datei entsteht auch der allpolige Plan, ohne dass ich irgendetwas nachzeichnen muss:

![Allpoliger Stromlaufplan desselben Einfamilienhauses](/img/blog/emolecad/efh-beispiel-allpolig.svg)

Für mich der eigentliche Gewinn: Wenn sich vor Ort herausstellt, dass ein Querschnitt anders ist oder
noch ein Stromkreis dazukommt, ändere ich eine Zeile, und alle Pläne und die Tabelle sind wieder aktuell.
Und weil YAML einfacher Text ist, lässt sich jede Änderung sauber versionieren.

---

## Ausprobieren

EMoleCAD läuft komplett im Browser, es muss nichts installiert werden und es wird nichts hochgeladen.
Gespeichert wird lokal, in Chrome und Edge sogar direkt zurück in die geöffnete Datei.
Das eigene Firmenlogo lässt sich in den Einstellungen hochladen und erscheint dann im Schriftfeld,
wie oben in den Beispielplänen.

👉 **[Hier geht's zum Tool: the78mole.github.io/EMoleCAD](https://the78mole.github.io/EMoleCAD/)**

Wer offline arbeiten will, lädt sich die
[Einzeldatei-Version](https://the78mole.github.io/EMoleCAD/emolecad.html) herunter. Der Quellcode steht
unter MIT-Lizenz auf [GitHub](https://github.com/the78mole/EMoleCAD).

**Funktionswünsche sind ausdrücklich willkommen!** Euch fehlt ein Bauteil, ein Schaltzeichen, eine
Blattvorlage oder eine Prüfung? Dann legt einfach ein
[Issue auf GitHub](https://github.com/the78mole/EMoleCAD/issues) an oder schreibt mir. Fehlerberichte und
Pull Requests freuen mich natürlich genauso. EMoleCAD wächst mit den Anforderungen aus der Praxis, und
je mehr Anlagen damit gezeichnet werden, desto besser wird es.

Ein Hinweis noch, weil es mir wichtig ist: EMoleCAD ist ein Hilfsmittel zum Zeichnen. Die Pläne ersetzen
keine Planung und Prüfung durch eine Elektrofachkraft und keine Abstimmung mit dem Netzbetreiber.

Schaut mal rein und sagt mir gerne, was ihr davon haltet!

![EMoleCAD mit Bibliothek, grafischem Editor und Live-Plan nebeneinander](/img/blog/emolecad/emolecad-gesamtansicht.webp)

*Alles auf einen Blick: Bibliothek, Editor und der Plan, der sich bei jeder Änderung live mitzeichnet –
inklusive eigenem Logo im Schriftfeld.*
