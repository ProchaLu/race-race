# Game Design Document – F1 Team Manager (Arbeitstitel)

> Status: **Entwurf v0.2** – Planungsphase. Entscheidungen sind markiert mit ✅ (entschieden) oder ❓ (offen).

---

## 0. Vision

Ein tiefgehender Motorsport-Manager. Der Spieler ist **Teamchef** eines F1-Teams und gestaltet alles, was ein Team schneller macht: Fahrer, Personal, Gelände, Auto, Motor, Geld.

**Leitsätze (Pillars)**

1. **Alles führt auf die Strecke.** Jede Entscheidung im Management muss am Ende im Rennen spürbar sein – schneller, zuverlässiger, cleverer.
2. **Menschen machen den Unterschied.** Fahrer und Personal sind Individuen mit Stärken, Schwächen, Charakter und Entwicklungskurve. Es gibt Ausnahmetalente, Durchschnitt und Totalausfälle.
3. **Übersicht wie Motorsport Manager, Tiefe wie Football Manager.** Die Oberfläche ist klar und schnell lesbar; darunter steckt ein dichtes Zahlenmodell, das man erforschen kann.
4. **Unsicherheit ist Spielmechanik.** Man sieht nicht alles: Talente muss man scouten, Teile müssen sich auf der Strecke beweisen.
5. **Die Rennen sind passiv.** Das Rennen wird in 2D von oben beobachtet; man greift nur taktisch ein. Der Fokus liegt auf dem Management.
6. **Simulation zuerst, Darstellung danach.** ✅ Training, Qualifying und Rennen laufen zuerst als **reine Simulation** (ohne Grafik). Erst wenn das Grundgerüst und eine sehr gute Simulation stehen, kommt die 2D-Rennansicht dazu. Am Ende entscheidet der Spieler pro Session: **nur simulieren** (Ergebnis sofort) oder **zuschauen und mitentscheiden**.

---

## 1. Rahmen

| Thema | Entscheidung |
|---|---|
| Rolle des Spielers | ✅ Teamchef / Manager. Der **Besitzer** ist eine eigene Figur, die den Spieler entlassen kann. |
| Spielstart | ✅ Ein bestehendes Team übernehmen. **Alle 11 Teams frei wählbar.** (Später als Schwierigkeits-Feature: z. B. Start nur beim letzten Team.) |
| Teamchef-Avatar | ✅ Eigener Name, Nationalität und Hintergrund mit kleinen Boni (siehe 1.1). |
| Sprint-Wochenenden | ✅ Nicht in v1, erst später. |
| Spielsprache | ✅ Godots Übersetzungssystem von Anfang an, **Englisch und Deutsch ab Start**. |
| Rennwochenende | ✅ Training, Qualifying und Rennen zuerst als reine Simulation; 2D-Ansicht erst danach. Später pro Session wählbar: simulieren oder zuschauen/mitentscheiden. |
| Gesichter | ✅ Prozedural generierte Porträts für **alle Personen** + generierte **Helm-Designs** für Fahrer. Teil von R0 (Stil-Auswahl per Vorschau). |
| Spielwelt | ✅ Feste Startwelt (11 Teams, Fahrer, Personal) in Datendateien. **Nachwuchs- und vertragslose Fahrer/Personal werden laufend neu erzeugt** (Dynamik). Siehe 1.2. |
| KI-Teams | ✅ Gleiche Regeln wie der Spieler (v1 mit vereinfachten Entscheidungen, später schlauer). |
| Plattform | ✅ Spaßprojekt, lokal auf **Windows und macOS**. Alles Open Source/kostenlos. Veröffentlichung nur, wenn es wirklich fertig ist. |
| Strecken | ✅ Erst **nach v0** – zuerst hat das UI Priorität. Dann Strecken-Editor (Pfad zeichnen, automatische Analyse). |
| Erstes großes Feature danach | ✅ **Eigenes Team gründen** → Feld wächst von 11 auf **12 Teams (22 → 24 Fahrer)**. |
| Serien | ✅ F1 wird live gespielt. F2 und F3 werden komplett im Hintergrund simuliert (Ergebnisse, Tabellen, Fahrerentwicklung). |
| Namen | ✅ Komplett fiktiv (Fahrer, Teams, Personal, Sponsoren, Strecken). |
| Komplexität | ✅ Eher komplex – Mischung MM (Übersicht) + FM (Zahlentiefe). |
| Echte F1-Regulierungen (Budget Cap, Aero-Testlimit, Motorkontingente) | ✅ **Nicht** zum Start – eigene Feature-Runde später. |
| Code-Sprache | ✅ Englisch (inkl. Kommentare). |
| Kosten der Entwicklung | ✅ **Alles kostenlos**: nur freie Tools und Assets (Godot, frei lizenzierte Schriften wie Google Fonts/OFL, eigene oder CC0-Grafiken). Keine kostenpflichtigen Plugins oder Asset-Packs. |
| Schwierigkeit (v1) | ✅ Nur über die **Teamstärke** beim Start (Top-Team vs. Hinterbänkler). Schwierigkeitsstufen (z. B. strenge Besitzer) kommen am Ende als eigenes Feature. |
| Saisonformat | ✅ Wie in der echten F1: ca. 24 Rennen plus Vorsaison-Tests. |
| Spielstände | ✅ v1: **ein** Spielstand. Mehrere Karrieren kommen in einer späteren Version. |
| Rennen | ✅ Fokus liegt auf dem Management. Wetter, Safety Car und Darstellung des Rennens werden in laufenden Runden nebenbei verbessert. |

### 1.1 Teamchef-Avatar ✅
Beim Spielstart legt der Spieler seinen Teamchef an: Name, Nationalität, Alter und **Hintergrund**. Der Hintergrund gibt kleine Boni und färbt den Start-Ruf:

| Hintergrund | Beispiel-Bonus |
|---|---|
| Ex-Ingenieur | Entwicklungsprojekte etwas schneller, Respekt der Technik-Abteilung |
| Ex-Fahrer | Bessere Beziehung zu Fahrern, Vorteile bei Fahrerverhandlungen |
| Ex-Manager / Kaufmann | Bessere Sponsoren- und Investorenverhandlungen |
| Ex-Stratege | Bessere Strategie-Prognosen im Rennen |
| Quereinsteiger | Keine Boni, aber mehr Startbudget oder Vertrauen des Besitzers |

Die Boni sind bewusst klein (wenige Prozent), damit keine Wahl „falsch“ ist.

### 1.2 Die Spielwelt ✅
- **Feste Startwelt**: 11 Teams mit Fahrern, Schlüsselpersonal, Sponsoren, Motorenherstellern und Strecken – von Hand erstellt, in Datendateien (später auch für Mods/Fan-Patches nutzbar).
- **Vorgeschichte**: Die Welt hat eine erfundene Vergangenheit – frühere Weltmeister (Fahrer und Teams), Rekorde, Teamhistorie, legendäre Fahrer. Das gibt Erfolgen Bedeutung („erster Titel seit 12 Jahren“, „neuer Rekord für die meisten Poles“).
- **Dynamik durch Generierung**: Jedes Jahr entsteht ein neuer Jahrgang an Nachwuchsfahrern; der Markt an vertragslosen Fahrern und Mitarbeitern wird laufend mit neu erzeugten Personen aufgefüllt. Dadurch verläuft jede Karriere anders.
- **Geld**: realistische F1-Größenordnungen (Budgets ca. 100–400+ Mio. pro Jahr), Währung US-Dollar oder fiktiv.

### Technische Konsequenz der 24 Autos
Alles muss von Anfang an für **mindestens 24 Autos / 12 Teams** ausgelegt sein:
- Strecken: 24 Startplätze, 12 Boxen.
- UI: Zeitenturm, Tabellen und Listen müssen 24 Zeilen sauber darstellen.
- Simulation und Performance auf 24 Autos testen.
- Keine fest eingebauten Zahlen wie „11 Teams“ im Code – immer aus den Daten lesen.

---

## 2. Spielablauf & Zeit

### Kern-Loop
```
Saison
 ├─ Zwischen den Rennen (Tage/Wochen)
 │    ├─ Entscheidungen: Entwicklung, Personal, Verträge, Gelände, Finanzen
 │    ├─ "Weiter" → Zeit läuft bis zum nächsten wichtigen Ereignis
 │    └─ Inbox: Berichte, Angebote, Probleme, Nachrichten
 ├─ Rennwochenende: Training → Qualifying → Rennen → Nachbesprechung
 └─ Saisonende: Preisgeld, Vertragsende, Rücktritte, neue Talente, Regeländerungen
```

### Zeitmodell
- Die kleinste Einheit ist **1 Tag**.
- Der **„Weiter“-Button** spult automatisch vor, bis etwas die Aufmerksamkeit des Spielers braucht (Inbox-Nachricht mit Priorität, Rennwochenende, abgeschlossenes Projekt, Vertragsangebot …).
- ✅ Daneben gibt es den passiven Button **„+1 Tag“** für genau einen Tag.
- Alles mit Dauer (Teil-Entwicklung, Gebäudebau, Scouting-Auftrag, Gardening Leave) läuft über einen zentralen **Scheduler** mit Start- und Enddatum.
- Ein Saisonkalender hat ca. 20–24 Rennen; dazwischen Winterpause mit Vorsaison-Tests.

---

## 3. Fahrer (Kernsystem)

Fahrer sind das wichtigste System im Spiel und bekommen deshalb das detaillierteste Modell.

### 3.1 Attribute
Skala ✅: **Anzeige 1–20** (wie in FM), **intern 0–100** für feinere Berechnungen. Die Umrechnung steckt an einer zentralen Stelle im Code, damit man die Anzeige später leicht umstellen kann.

**Fahrerisch**
| Attribut | Wirkung im Rennen |
|---|---|
| Cornering (Kurvenspeed) | Tempo in Kurven |
| Braking (Bremsen) | Tempo in Bremszonen, Überholen beim Anbremsen |
| One-Lap Pace (Qualifying) | Bonus nur im Qualifying |
| Race Pace / Consistency | Streuung der Rundenzeiten, Fehlerquote |
| Tyre Management | Reifenverschleiß |
| Fuel/Energy Management | Verbrauch, Spritsparen ohne viel Zeitverlust |
| Overtaking | Erfolgschance beim Überholen |
| Defending | Abwehr von Angriffen |
| Starts | Reaktion und Positionsgewinne beim Start |
| Wet Driving | Tempo und Fehlerquote bei Regen |
| Racecraft | Zweikämpfe, Verkehr, Überrundungen, Safety-Car-Restarts |

**Mental**
| Attribut | Wirkung |
|---|---|
| Composure (Nervenstärke) | Leistung unter Druck (Titelkampf, letzte Runden) |
| Focus (Konzentration) | Fehler im späten Rennen, lange Stints |
| Aggression | Mehr Überholversuche, aber höheres Unfallrisiko |
| Adaptability | Wie schnell er neue Strecken, Autos und Regeln lernt |
| Technical Feedback | Setup-Qualität, Entwicklungshinweise für Ingenieure |
| Work Ethic (Arbeitsmoral) | Entwicklungstempo, Training |
| Professionalism | Konstanz der Moral, Medienverhalten |
| Ambition | Gehaltsforderungen, Wunsch nach Top-Team |
| Loyalty | Bereitschaft zu verlängern, Wechselwille |
| Temperament | Reaktion auf Stallorder, Kritik, Pech |

**Körperlich**
| Attribut | Wirkung |
|---|---|
| Fitness | Leistungsabfall am Rennende, Verletzungsrisiko, Erholung |
| Reactions | Starts, Reaktion auf Zwischenfälle |

**Erfahrung** (eigener Wert): wächst mit jedem Rennen, jeder Strecke, jeder Saison. Sie gleicht Schwächen teilweise aus (z. B. weniger Fehler, besseres Reifenmanagement).

**Streckenwissen**: pro Strecke ein eigener Wert. Ein Rookie ist auf einer neuen Strecke langsamer; der Simulator im HQ verkürzt die Lernzeit.

### 3.2 Aktuelle Stärke & Potenzial
- **CA (Current Ability)**: aktuelle Gesamtstärke, ergibt sich aus den Attributen.
- **PA (Potential Ability)**: verborgene Obergrenze. Wird **nie direkt** angezeigt, nur über Scouting geschätzt.
- Die Entwicklung Richtung PA hängt ab von:
  - Alter (Kurve, siehe 3.3)
  - Fahrpraxis (Renneinsätze in F1/F2/F3, Testfahrten, Simulator)
  - Qualität des Trainings (Akademie, Jugendtrainer, Driver Performance Center)
  - Work Ethic, Moral, Selbstvertrauen
  - Mentoring durch einen erfahrenen Teamkollegen
- Talente können **stagnieren** (schlechte Bedingungen, keine Fahrpraxis, schlechte Moral) – Potenzial ist eine Chance, keine Garantie.

### 3.3 Alterskurve – mit Ausnahmen ✅
Jeder Fahrer hat seine **eigene, verborgene Alterskurve**:

| Parameter | Bedeutung |
|---|---|
| `peak_start_age` | Ab wann er seinen Höhepunkt erreicht |
| `peak_end_age` | Bis wann er ihn hält |
| `decline_rate` | Wie schnell er danach abbaut |

Dazu verschiedene Arten von Attributen, die unterschiedlich altern:
- **Körperliche Attribute** (Reactions, Fitness) bauen zuerst ab.
- **Fahrerische Attribute** halten länger.
- **Mentale Attribute + Erfahrung** wachsen oft bis ins hohe Alter weiter.

**Ergebnis:** Ein 40-Jähriger mit langsamer Abbaurate, hoher Erfahrung, Top-Reifenmanagement und Nervenstärke kann immer noch schneller sein als ein 25-Jähriger.

Beispiel-Typen (verborgen, nur über Scouting/Beobachtung zu erahnen):
| Typ | Kurve |
|---|---|
| Frühstarter | Früh stark (19–20), Peak 23–28, früher Abbau |
| Normal | Peak ca. 26–32 |
| Spätzünder | Langsame Entwicklung, Peak 29–35 |
| **Evergreen** | Peak bis Ende 30, sehr langsamer Abbau – fährt mit 40+ noch auf hohem Niveau |

Beeinflussbar durch: **Driver Performance Center** im HQ (Fitness, Ernährung, Mentaltraining) verlangsamt den Abbau. Der Fahrer selbst beeinflusst ihn über Professionalism und Work Ethic.

### 3.4 Eigenschaften (Traits)
Besondere Merkmale, die das Rennen spürbar beeinflussen. Manche sind von Anfang an bekannt, andere werden erst entdeckt (durch Scouting oder Beobachtung).

| Positiv | Negativ |
|---|---|
| Regengott | Nervenschwach (Druck → Fehler) |
| Reifenflüsterer | Hitzkopf (Kollisionen, Strafen) |
| Qualifying-Spezialist | Reifenkiller |
| Startrakete | Schlechter Verlierer (Moraleinbruch bei schwachen Ergebnissen) |
| Teamplayer (akzeptiert Stallorder) | Diva (verlangt Nr.-1-Status) |
| Medienliebling (+Sponsoren) | Skandalnudel |
| Mentor (hilft jungen Teamkollegen) | Faul im Training |
| Evergreen | Verletzungsanfällig |
| Clutch-Fahrer (stark in entscheidenden Momenten) | Langsamer Lerner bei neuen Strecken |

### 3.5 Moral, Form, Selbstvertrauen
- **Moral** (langfristig): Vertragssituation, Status im Team, Ergebnisse im Vergleich zu den Erwartungen, Qualität des Autos, gehaltene oder gebrochene Versprechen, Verhältnis zum Teamkollegen.
- **Form** (kurzfristig): die letzten 3–5 Rennen.
- **Selbstvertrauen**: steigt mit Siegen und Duellen gegen den Teamkollegen, sinkt nach Unfällen.
- Alle drei wirken direkt auf die Rennleistung (kleine, aber spürbare Prozentwerte).

### 3.6 Versprechen
Bei Vertragsgesprächen oder in Konflikten macht der Teamchef Versprechen, z. B.:
- „Du bist unser Nr.-1-Fahrer.“
- „Das Auto wird bis zur Saisonmitte konkurrenzfähig.“
- „Du bekommst nächstes Jahr ein F1-Cockpit.“ (für Akademie-Fahrer)

Gebrochene Versprechen → Moraleinbruch, Wechselwunsch, schlechter Ruf bei anderen Fahrern.

### 3.7 Beziehungen
- **Teamkollegen-Rivalität**: Wer schneller ist, gewinnt an Selbstvertrauen; Stallorder kann zu Konflikten führen.
- **Fahrer ↔ Renningenieur**: Die „Chemie“ wächst mit der Zeit zusammen. Gute Chemie bedeutet besseres Setup und bessere Strategie-Kommunikation.
- **Fahrer ↔ Teamchef**: Vertrauen, beeinflusst durch Gespräche und eingehaltene Versprechen.

### 3.8 Verträge
| Bestandteil | Beschreibung |
|---|---|
| Gehalt | Pro Jahr |
| Laufzeit | 1–5 Jahre, optional mit Option für ein weiteres Jahr (Team oder Fahrer) |
| Status | Nr. 1 / gleichberechtigt / Nr. 2 / Test- oder Ersatzfahrer |
| Boni | Pro Punkt, Podium, Sieg, WM-Titel |
| Ausstiegsklausel | Ablöse, die ein anderes Team zahlen kann |
| Leistungsklausel | Das Team darf aussteigen, wenn bestimmte Ziele verfehlt werden |
| Mitgebrachte Sponsorengelder | „Paydriver“ bringen Geld mit, sind aber oft schwächer |

**Verhandlung** ✅: Fahrer haben einen **Manager/Agenten** mit eigener Persönlichkeit (gierig, fair, loyal). Gegenangebote, Fristen und konkurrierende Teams machen Verhandlungen spannend.
- Form: **Angebotsformular** wie in FM – man stellt das Paket zusammen (Gehalt, Laufzeit, Status, Boni, Klauseln).
- **Live-Feedback**: Während man das Angebot verändert, zeigt eine Anzeige, wie zufrieden der Agent damit wäre und welche Punkte ihm wichtig sind.
- **Mehrere Runden**: Annahme, Ablehnung oder Gegenangebot. Die Geduld des Agenten ist begrenzt; zu viele schlechte Angebote beenden die Gespräche.
- ✅ **Ablauf wie in der Realität**: Das Gespräch mit dem Berater läuft **direkt** (Live-Reaktion auf jedes Angebot). Ist man sich einig, **unterschreibt die Person erst nach ein paar Tagen** – in dieser Zeit kann ein anderes Team noch dazwischenfunken (Inbox-Meldung). Risiko 8 %, mit Handgeld bis auf 2 % senkbar; das Risiko wird in der Verhandlung angezeigt. Verlängerungen sind nie betroffen.
- Ob jemand überhaupt wechseln will, hängt ab von Team-Ruf, Stärke des Autos und angebotener Rolle.
- Gleiches System für Personal-Verträge.

### 3.9 Superlizenz
Punkte aus F2/F3-Ergebnissen. Ohne genug Punkte darf ein Fahrer nicht in die F1 – das macht die Jugendentwicklung planbar und strategisch.

### 3.10 Statistiken & Historie
Komplette Karrierehistorie: Teams, Saisons, Siege, Podien, Poles, Titel, Duelle gegen Teamkollegen, Entwicklung der Attribute im Zeitverlauf (Diagramm).

### 3.11 Training ✅
Einfach zu bedienen, aber mit spürbarer Wirkung:
- Der Fahrer trainiert **selbst** mit seinem Umfeld. Der Teamchef gibt nur einen **Schwerpunkt** vor (z. B. Reifenmanagement, Regenfahren, Fitness, Qualifying-Pace) oder lässt ihn ausgewogen trainieren.
- **Wie gut** ein Fahrer trainiert, hängt von ihm ab: Arbeitsmoral, Professionalität, Moral, Alter. Ein fauler Fahrer verbessert sich auch mit perfektem Plan kaum.
- Dazu wirken Fitness-/Mentaltrainer, Simulator und Driver Performance Center.
- **Simulator-Vorbereitung** vor jedem Rennen: Streckenwissen und Setup-Startpunkt.

### 3.12 Verletzungen & Ersatzfahrer ✅
- Unfälle können zu **Verletzungen** führen (Schwere abhängig von Aufprall; Fitness beeinflusst Risiko und Heilungsdauer).
- Ein verletzter Fahrer fällt für Rennen aus und kommt eventuell mit Formverlust zurück.
- Wie in der echten F1 hat jedes Team **fest angestellte Ersatz- und Testfahrer** (eigener Vertragsstatus). Sie springen bei Verletzung, Krankheit oder Sperre ein.
- Fehlt ein Ersatzfahrer, muss kurzfristig ein Fahrer vom Markt oder aus der Akademie geholt werden (Superlizenz nötig!).

---

## 4. Jugend & Scouting ✅ (wichtig)

### 4.1 Nachwuchspyramide
```
Kart / Nachwuchs (generiert, ca. 15–17 Jahre)
        ↓
       F3  (simuliert)
        ↓
       F2  (simuliert)
        ↓
       F1  (gespielt)
```
- Jedes Jahr wird ein neuer Jahrgang an Talenten generiert („Newgens“), mit zufälligem Potenzial, Traits und Alterskurve.
- F2/F3-Teams und -Saisons werden vollständig im Hintergrund simuliert: Ergebnisse, Tabellen, Superlizenzpunkte, Entwicklung.

### 4.2 Akademie
- Anzahl der Plätze und Qualität des Trainings hängen vom Akademie-Gebäude und den Jugendtrainern ab.
- Akademie-Fahrer kann man in F3/F2-Teams platzieren (Cockpit bezahlen oder über Kontakte).
- Entwicklungspläne: Schwerpunkte setzen (z. B. Reifenmanagement oder Regenfahren).
- Akademie-Fahrer können als Test-/Ersatzfahrer eingesetzt werden.
- Die Moral ist auch hier wichtig: Wer keine Perspektive sieht, geht zur Konkurrenz.

### 4.3 Scouting ✅
**Scouts sind Personal** mit eigenen Attributen:
| Attribut | Bedeutung |
|---|---|
| Judging Ability | Wie genau er die **aktuelle** Stärke einschätzt |
| Judging Potential | Wie genau er das **Potenzial** einschätzt |
| Network / Region | Kontakte in bestimmten Ländern/Serien → findet mehr Talente |
| Speed | Wie schnell ein Bericht fertig ist |

**Aufträge**: Serie beobachten (z. B. „F3 komplett“), Region, einen bestimmten Fahrer, oder „Ersatz für Position X finden“. Auch **Personal** kann gescoutet werden.

**Wissensmodell** (Kern der Mechanik):
- Das Team hat pro Person einen **Wissensstand** (0–100 %).
- Angezeigt werden **Bereiche** statt exakter Werte, z. B. Potenzial ★★★–★★★★★ oder Attribut „12–16“.
- Die **Breite** des Bereichs hängt ab vom Wissensstand und der Fähigkeit des Scouts.
- **Schlechte Scouts liegen auch daneben**, nicht nur ungenau: Ein schwacher Scout kann ein Talent komplett falsch einschätzen (verschobener Bereich). Ein **perfekter Scout** liefert exakte Werte.
- Scouting-Berichte enthalten eine Empfehlung („Sofort verpflichten“, „Beobachten“, „Nicht interessant“) und entdeckte Traits.
- ✅ **Eigene Fahrer** kennt man nach **1–3 Rennwochenenden exakt** (Telemetrie, Training, Rennen). Bis dahin gilt der Wissensstand aus dem Scouting.
- ✅ **Eigenes Personal** kennt man **sofort nach der Einstellung** exakt.
- ✅ **Das Wissensmodell kommt schon in R1** (Scouting-Aufträge erst in R7):
  - **Bekannte Personen** (etablierte F1-Fahrer, bekanntes Top-Personal) kennt man **perfekt**.
  - **Unbekannte** (Markt, Nachwuchs, Personal anderer Teams) nur als **grobe Bereiche**.
  - **Jugendfahrer** sind fast immer unbekannt – gerade hier lohnt sich später das Scouting.
  - In R7 machen Scouts die Bereiche enger (oder schätzen daneben).

---

## 5. Personal ✅

### 5.1 Struktur
**Schlüsselpersonen** haben einen Namen und eigene Attribute. **Abteilungen** (die breite Masse) werden als Anzahl × Qualitätsstufe geführt, ohne einzelne Namen.

✅ **16 Schlüsselrollen pro Team** (so realitätsnah wie möglich, R1):

| Bereich | Schlüsselpersonen | Abteilung (Masse) | Wirkt auf |
|---|---|---|---|
| Technik | Technischer Direktor, Chefdesigner, Aero-Chef, Chassis-Chef | Aerodynamiker, Designer, CFD-Ingenieure | Auto-Entwicklung (R3) |
| Motor | Motorenchef | Motoreningenieure | Motor (R5) |
| Produktion | Fabrikleiter | Mechaniker, Fertigung | Teilefertigung (R3) |
| Renn-Betrieb | Sportdirektor, 2 Renningenieure, Strategiechef, Boxencrew-Chef | Boxencrew, Renn-Mechaniker | Rennwochenende, Strategie, Boxenstopps |
| Nachwuchs | Akademieleiter, Chefscout | – | Akademie, Scouting (R7) |
| Kommerz | Kaufmännischer Leiter | Marketing | Sponsoren (R6) |
| Fahrerbetreuung | Fitnesstrainer, Mentaltrainer | – | Fitness, Moral, Altersabbau |

In R1 werden Abteilungen nur angezeigt (Anzahl × Qualität); Einstellen/Ausbauen kommt mit HQ und Finanzen.

**Personal-Profil**: gleiches Columns-Layout wie das Fahrerprofil, zusätzlich eine Karte **„Wirkung im Team“** (z. B. „Boxenstopps −0,3 s“), jeder Wert erklärbar.

### 5.2 Attribute (Beispiel)
- **Allgemein**: Fachkompetenz, Führung, Erfahrung, Arbeitsmoral, Anpassungsfähigkeit.
- **Rollenspezifisch**: z. B. Chefdesigner → Innovation, Detailgenauigkeit, Spezialgebiet (Aero/Mechanik); Boxencrew-Chef → Stopp-Tempo, Fehlerquote; Strategiechef → Reifenmodell-Genauigkeit, Wetterprognose.
- **Persönlichkeit**: Ehrgeiz, Loyalität, Gehaltsvorstellungen.
- ✅ **Traits auch beim Personal** (z. B. Perfektionist, Teamplayer, Innovator, Sturkopf) – mit Symbol wie bei den Fahrern.

### 5.3 Qualitätsverteilung ✅
Es gibt schlechte, gute, sehr gute und **legendäre** Mitarbeiter. Die Verteilung beim Generieren ist pyramidenförmig – Weltklasse ist selten und teuer.

### 5.4 Delegieren ✅
Wie in FM kann der Spieler Aufgaben an Personal abgeben. **Der Spieler entscheidet, was er selbst macht; die Qualität des Personals bestimmt, wie gut das Delegierte läuft.**

| Aufgabe | Zuständig (wenn delegiert) |
|---|---|
| Entwicklungsplanung (welche Teile, Prioritäten) | Technischer Direktor |
| Teileverteilung, Produktion | Fabrikleiter / Technischer Direktor |
| Verträge von Nachwuchs, Ersatzfahrern, Personal | Sportdirektor |
| Akademie, Platzierung in F2/F3 | Akademieleiter |
| Scouting-Aufträge | Chefscout |
| Rennstrategie (ohne Eingriff) | Strategiechef |
| Sponsorensuche | Kaufmännischer Leiter |
| Training der Fahrer | Fitness-/Mentaltrainer |

Delegiertes Personal meldet wichtige Entscheidungen in der Inbox (optional mit Rückfrage).

### 5.5 Teamstimmung ✅
Ein **übersichtlicher Gesamtwert** für die Stimmung im ganzen Team (z. B. 0–100 oder eine Stufe von „Krise“ bis „Euphorie“). Er entsteht aus den Einzelmoralen, den Ergebnissen und Ereignissen (Entlassungen, Erfolge, gebrochene Versprechen) und wirkt auf Produktivität, Fehlerquoten und darauf, wie leicht Personal abgeworben wird. Ein Tooltip zeigt, woraus er sich zusammensetzt.

### 5.6 Weitere Mechaniken
- Personal entwickelt sich (jüngere verbessern sich, ältere bauen ab oder gehen in Rente). **Training und Leistung** wirken bei allen: wer trainiert und gut abliefert, wird besser; wer nicht trainiert und schlecht abliefert, baut ab (Details: simulation_model.md, Abschnitt 13).
- Moral und Zufriedenheit (Gehalt, Erfolg, Gebäudequalität, Respekt).
- **Abwerben** von anderen Teams – und eigenes Personal wird abgeworben.
- Synergien: Ein guter Technischer Direktor macht die ganze Abteilung besser.
- Kündigungsfristen und Abfindungen.

---

## 6. Transfermarkt ✅
- Es gibt **immer** einen Pool an vertragslosen Fahrern und Mitarbeitern.
- Sie entstehen durch Vertragsende, Entlassungen, Teams ohne Platz und jährlich neue Generierung.
- Vertragslose Personen kann man scouten, kontaktieren und verpflichten (sie werden mit der Zeit günstiger, aber auch ungeduldiger).
- Personen mit Vertrag: Ablöse / Ausstiegsklausel oder Verhandlung mit deren Team.
- **Shortlist / Beobachtungsliste** mit Benachrichtigungen (z. B. „Vertrag läuft aus“, „ist jetzt vertragslos“).
- KI-Teams sind aktiv auf dem Markt (Konkurrenz um Talente).

---

## 7. Gelände / HQ ✅
Ein Standort mit einem **ausbaubaren Gelände**. Gebäude haben Stufen; jede Stufe kostet Geld **und** Bauzeit, verursacht Unterhaltskosten und braucht zum Teil Personal. Das Gelände ist für alle Teams gleich groß und hat für jedes der 15 Gebäude einen festen Platz – kein Grundstückskauf (Entscheidung 30.10.2026).

| Gebäude | Wirkung |
|---|---|
| Design-Büro | Mehr parallele Entwicklungsprojekte, schnellere Designphase |
| Windkanal | Bessere Aero-Ergebnisse, weniger Streuung (Korrelation) |
| CFD-Rechenzentrum | Schnellere Simulation, ergänzt den Windkanal |
| Fabrik / Fertigung | Produktionstempo, Teilequalität, Kosten pro Teil, Ersatzteile |
| Verbundwerkstoff-Abteilung | Leichtere Teile, Chassis-Qualität |
| Motorenwerk | Voraussetzung für eigenen Motor, Motorentwicklung |
| Prüfstände / Testlabor | Zuverlässigkeit neuer Teile |
| Fahrsimulator | Streckenwissen, Setup-Vorbereitung, Fahrerentwicklung |
| Driver Performance Center | Fitness, Mentaltraining, verlangsamt Altersabbau |
| Akademie | Plätze und Trainingsqualität für Nachwuchsfahrer |
| Scouting-Büro | Mehr Scouts, größeres Netzwerk |
| Boxencrew-Trainingszentrum | Schnellere, fehlerfreiere Boxenstopps |
| Strategie-/Mission-Control-Raum | Bessere Strategieentscheidungen und Echtzeitdaten im Rennen |
| Marketing & Hospitality | Mehr Sponsoren-Einnahmen, Ruf |
| Mitarbeiter-Einrichtungen | Moral des Personals, Attraktivität für Top-Personal |

---

## 8. Auto & Entwicklung ✅ (sehr wichtig)

### 8.1 Das Auto besteht aus Teilen
| Bereich | Teile |
|---|---|
| Aero | Frontflügel, Heckflügel, Unterboden, Diffusor, Seitenkästen, Motorabdeckung |
| Chassis | Monocoque, Aufhängung vorne, Aufhängung hinten, Bremsen |
| Antrieb | Getriebe, Kühlung, Auspuff |
| Motor (Power Unit) | Siehe Kapitel 9 |

Jedes Teil hat Werte, die zum Gesamtauto beitragen:
- **Abtrieb**, **Luftwiderstand**, **mechanischer Grip**, **Gewicht**, **Kühlung**, **Reifenschonung**, **Zuverlässigkeit**.
- Zielkonflikte sind gewollt: mehr Abtrieb ⇒ mehr Luftwiderstand; leichter ⇒ weniger zuverlässig.

**Streckencharakter**: Jede Strecke gewichtet die Werte unterschiedlich (Monaco-Typ: Abtrieb und mechanischer Grip; Monza-Typ: wenig Luftwiderstand). Man kann gezielt Spezialteile entwickeln (z. B. einen Low-Downforce-Heckflügel).

### 8.2 Entwicklungsprozess
```
1. Konzept     → Ziel wählen (z. B. "Frontflügel: mehr Abtrieb, gleicher Drag")
2. Design      → Designer + CFD + Windkanal; Dauer & Kosten abhängig von Personal und Gebäuden
3. Produktion  → Fabrik fertigt das Teil (Stückzahl! Ersatzteile für Unfälle)
4. Einsatz     → Teil wird zum Rennen gebracht
5. Korrelation → Echter Gewinn auf der Strecke kann vom Prognosewert abweichen
```
- **Projekte** haben: verantwortlichen Designer, zugeteiltes Personal, Dauer, Kosten, Risiko.
- **Ergebnis** ist zufällig, aber stark beeinflusst durch Personal-Qualität, Gebäude und Fahrer-Feedback.
- **Korrelation**: Prognose und Realität können auseinanderliegen. Guter Windkanal + gute Ingenieure ⇒ Prognose stimmt. Schlecht ⇒ Überraschungen (positiv wie negativ).
- **Fehlschläge** sind möglich: ein Teil, das schlechter ist als das alte.
- **Ersatzteile**: Unfälle zerstören Teile. Ohne Ersatz muss eine ältere Version gefahren werden.
- **Ressourcenverteilung**: Wie viel Personal arbeitet am aktuellen Auto und wie viel am Auto für die nächste Saison?
- ✅ **Jedes Auto hat seinen eigenen Teile-Stand.** Ist erst ein neuer Frontflügel fertig, muss man entscheiden, wer ihn bekommt. Das wirkt auf die Moral (Nr.-1-/Nr.-2-Status, Versprechen, Teamkollegen-Duell).

- ➡️ **Umsetzung und Ausbau:** Entwicklungslabor (Ideen → CFD → Windkanal → Freigabe → Strecke) in `docs/car_model.md` 3a; geplanter Ausbau (Track-Test, Entwicklungsrennen, Korrelationsprobleme, Streckencharakter, Pakete, Kopieren, Fahrzeugkonzept, Budget Cap/ATR, Regeländerungen) in `docs/car_model.md` 17.

### 8.3 Saisonwechsel
- Ein Teil der Entwicklung wird ins nächste Auto übernommen.
- Bei großen Regeländerungen werden betroffene Teile zurückgesetzt – wer früh am neuen Auto arbeitet, ist im Vorteil.

### 8.4 Rennwochenende & Setup
- Training: Programme wählen (Setup, Reifentests, Longruns, neue Teile testen).
- Die Setup-Qualität ergibt sich aus Fahrer-Feedback, Renningenieur, Chemie und Simulator-Vorbereitung.
- Gut genutztes Training ⇒ kleiner Tempobonus und genauere Reifendaten für die Strategie.

### 8.4b Entscheidungen des Teamchefs am Rennwochenende ✅ (R2)
Vorbild: ein Teamchef wie Toto Wolff – er stellt kein Setup ein und ruft keine Stopps aus, sondern setzt den Rahmen, trifft die großen Entscheidungen und führt die Menschen. **Bei jeder Entscheidung gibt es „Mitarbeiter entscheiden lassen“** (Hilfe für Einsteiger; das Ergebnis hängt von der Qualität des Mitarbeiters ab).

| Wann | Entscheidung | Wirkung |
|---|---|---|
| Vor dem Wochenende | **Wochenendziel** (z. B. „Beide in die Punkte“, „Angriff aufs Podium“) | Risikobereitschaft von Strategen und Fahrern; verfehlte Ziele kosten Moral |
| Vor dem Wochenende | **Trainingsprogramm pro Fahrer** (Setup-Arbeit, Longruns/Reifen, Freitagseinsatz für Akademiefahrer) | Setup-Qualität, Reifenwissen, Erfahrung für den Nachwuchs |
| Vor dem Wochenende | **Stallorder-Regel** (frei fahren, Positionen halten nach dem letzten Stopp, Priorität Fahrer X) | Teampunkte vs. Moral/Spannungen |
| Vor dem Wochenende (bei Bedarf) | **Ersatzfahrer einsetzen** (Verletzung/Krankheit) | Wer fährt? |
| Vor dem Rennen | **Strategie-Vorschlag** des Strategiechefs wählen (2–3 Pläne mit Prognose und Risiko) | Genauigkeit hängt vom Strategiechef ab |
| Vor dem Rennen (bei Regenrisiko) | **Regen-Poker**: Setup trocken / nass / Kompromiss | Großer Ausschlag nach oben oder unten |
| Vor dem Rennen | **Fahrerbesprechung** („Heimbringen“, „Angriff“, „Kein Druck“, „Teamplayer“) – Auswirkungen und Empfehlung des Renningenieurs stehen darunter | Selbstvertrauen, Aggressivität, Fehlerrisiko – je nach Persönlichkeit |
| Vor dem Rennen | **1:1-Gespräch** mit jedem Fahrer (fix vor jedem Rennen); seltene **Gespräche auf Wunsch des Fahrers** mit mehr Tiefe | Kurzfristige Boosts, Moral, Beziehung, Versprechen |
| Vor dem Rennen | **Flügelstufe** (nach Rücksprache mit dem Ingenieur) | Kurven vs. Geraden, Überholen, Reifen |
| Im Rennen | **2–4 Schlüsselmomente** (Safety Car: reinholen?, Regen: Reifenwechsel?, Stallorder: tauschen?) | Rest entscheidet der Strategiechef automatisch |

Später dazu: neue Teile mitbringen/verteilen (R3), Sponsoren-/PR-Termine (R6), Motorteile & Startplatzstrafen (R9).

**Ergebnis-Ansicht im Detail** ✅: Klassement, jeder Boxenstopp mit Standzeit, Rundenzeiten-Grafik, Reifen-Stints, Positionsverlauf, Wetter- und Safety-Car-Phasen – Daten wie für einen echten Teamchef.

**Simulation** ✅: Wetter (Vorhersage, Regen setzt ein/hört auf, abtrocknende Strecke, Intermediates/Regenreifen, Regenfahrer schneller, schwache Regenfahrer mehr Fehler) und **Safety Car**.

### 8.6 Simulationsmodell ✅ (Herzstück)
Alle Formeln, Startwerte und Zielwerte stehen in **[docs/simulation_model.md](simulation_model.md)**: Rundenzeit in Sekunden-Anteilen (erklärbar), Reifen mit Temperatur, Sprit-Strategie, Boxenstopps (Minimum 2,0 s), Strategiechef mit Schätzfehler, Überholzonen, Teilschäden, ereignisgesteuertes Safety Car, detailliertes Wetter, Quali Q1–Q3, Briefing und 1:1-Gespräche, Entwicklung durch Training und Leistung, Sim-Labor.

### 8.5 Eingriffe im Rennen ✅
Das Rennen läuft größtenteils **passiv**. Kurzfristige taktische Entscheidungen trifft im echten Leben die Kommandozentrale, nicht der Teamchef allein. Der Spieler kann eingreifen bei:
- Boxenstopps und Reifenwahl
- Pace-Modus (Schonen / Normal / Angriff)
- **Stallorder** (Plätze tauschen lassen, „Haltet die Positionen“) – mit Folgen für Moral und Medien
- Ohne Eingriff entscheidet der **Strategiechef** (Personal!) – je besser er ist, desto besser die automatischen Entscheidungen.

---

## 9. Motor (Power Unit) ✅

### 9.1 Modelle
| Option | Beschreibung |
|---|---|
| Kundenmotor | Motor von einem Hersteller kaufen. Feste Spezifikation, jährliche Kosten, Updates vom Hersteller. |
| Lizenzmotor mit Entwicklungsrechten | Motor eines anderen Herstellers kaufen **und selbst weiterentwickeln** (teurer, braucht Motorenwerk). |
| Werksmotor | Eigener Motor. Riesige Investition (Motorenwerk, Personal), volle Kontrolle; man kann ihn auch an andere Teams **verkaufen** (Einnahmequelle). |

### 9.2 Komponenten
Verbrennungsmotor, Turbolader, Energierückgewinnung (Bremse/Abgas), Batterie, Steuerelektronik.
Werte: Leistung, Effizienz (Verbrauch), Zuverlässigkeit, Gewicht, Fahrbarkeit.

➡️ **Ausgearbeitet für R5:** `docs/engine_model.md` (4 Hersteller, 5 Komponenten → 5 Motorwerte, Verträge, Einheiten mit Laufleistung, Motor-Modi, Schlüsselmomente, Motoren-Labor mit Dyno und Dauerlauf). Mockup: `docs/ui_mockups/r5_engine.html`.

### 9.3 Später (Regulierungs-Runde)
Motorkontingente pro Saison mit Startplatzstrafen, Entwicklungseinfrierung.

---

## 10. Finanzen

### Einnahmen
- Preisgeld nach WM-Platz (Konstrukteure)
- Sponsoren (fix + Bonus)
- TV-/Startgeld (Basis für alle Teams)
- Motorverkauf an Kundenteams
- Paydriver-Gelder
- Investoren / Besitzer-Zuschüsse

### Ausgaben
- Gehälter (Fahrer, Personal, Abteilungen)
- Entwicklungsprojekte und Teileproduktion
- Gebäudebau und Unterhalt
- Motorkosten (Kunde) oder Motorentwicklung (Werk)
- Logistik pro Rennen
- Unfallschäden
- Ablösen, Abfindungen, Strafen

✅ **Schon ab R1**: Gehälter werden **monatlich** vom Budget abgezogen, dazu Handgeld bei Verpflichtungen und Abfindungen bei Entlassungen. Die vollständigen Finanzen (Einnahmen, Übersichten, Prognosen) folgen in R6.

### Wirtschafts-Zielwerte ✅ (Startpunkt, wird nachjustiert)
Alle Preise werden an diesen Werten ausgerichtet. **Grundregel: Der Weltmeister kann sich den besten Fahrer leisten; Preisgeld muss für Gebäude-Ausbau reichen.**

| Größe | Zielwert |
|---|---|
| Preisgeld Weltmeister (Konstrukteure) | ca. $140M |
| Preisgeld letzter Platz | ca. $55M |
| Gehalt des besten Fahrers | ca. $15–20M |
| Gehalt eines Hinterbänkler-Fahrers | ca. $1–3M |
| Personal eines Topteams pro Jahr | ca. $30–40M |
| Großer Gebäude-Ausbau (R4) | ca. $20–60M |

Faustregel: Ein Topteam stemmt jedes Jahr **einen Star + ein großes Bauprojekt**; ein Hinterbänkler muss sich entscheiden.

**Entwicklermenü** ✅ (R2): per Taste aufrufbares Test-/Cheat-Menü (Geld, Datum springen, Moral/Stimmung setzen …) für Tests.

### Darstellung
Übersicht mit Verlauf (Diagramm), Prognose bis Saisonende, Aufschlüsselung nach Kategorien, Warnungen bei drohendem Minus.

---

## 11. Besitzer & Investoren ✅
- Der **Besitzer** hat eine Persönlichkeit (geduldig/ungeduldig, ehrgeizig, sparsam).
- Er setzt **Ziele**: pro Saison (z. B. „Top 5 Konstrukteure“) und langfristig (z. B. „Titel innerhalb von 5 Jahren“, „Akademie aufbauen“, „schwarze Zahlen“).
- **Vertrauen** als Kernwert: verfehlte Ziele, Skandale und Schulden senken es. Bei zu niedrigem Vertrauen wird der Spieler **entlassen**.
- ✅ **v1 ist nachsichtig**: Eine Entlassung passiert nur bei massivem Versagen (z. B. Weltmeister-Team wird Letzter der Konstrukteurs-WM). Der Fokus liegt auf dem Managen, nicht auf dem Überleben. Strengere Besitzer kommen später mit den Schwierigkeitsstufen.
- Der Spieler kann **um Geld bitten** (Budgeterhöhung, Freigabe für große Bauprojekte). Die Antwort hängt vom Vertrauen und der Persönlichkeit des Besitzers ab.
- **Investoren** tauchen auf und bieten Geld an – mit Bedingungen (Ziele, Anteile, Mitspracherecht, z. B. einen bestimmten Fahrer einsetzen).
- ✅ **Nach einer Entlassung geht die Karriere weiter**: Der Spieler bekommt Jobangebote von anderen Teams. Realistisch kommen sie von Teams, die selbst ihre Ziele verfehlt haben und einen neuen Teamchef suchen – nicht vom amtierenden Weltmeister. Der Ruf des Teamchefs bestimmt, wie gut die Angebote sind.
- Auch ohne Entlassung können später Angebote anderer Teams kommen (Wechsel möglich).

---

## 12. Sponsoren ✅
- Stufen: Titelsponsor, Hauptsponsor, Nebensponsor. Werbeflächen am Auto sind begrenzt.
- Jeder Sponsor hat: Zahlung pro Rennen, Unterschriftsbonus, Zielbonus, Laufzeit, Mindest-Ruf, eventuell Wünsche (z. B. Fahrer aus einem bestimmten Land).
- Verfehlte Ziele ⇒ Unzufriedenheit ⇒ Kündigung oder keine Verlängerung.
- Der Kaufmännische Leiter und das Marketing-Gebäude beeinflussen, welche Angebote kommen.

---

## 13. Ruf & Medien ✅
- **Team-Ruf**: öffnet Türen zu Sponsoren, Top-Fahrern und Top-Personal.
- **Teamchef-Ruf**: wichtig für die Karriere des Spielers (Jobangebote).
- **Fans**: wachsen mit Erfolg und beliebten Fahrern ⇒ Einnahmen über Merchandising.

### Medien – tief, aber wie in der echten F1
Kein Spiel, das nur aus Pressekonferenzen besteht. Medien tauchen dort auf, wo sie auch in der F1 vorkommen, und **Antworten haben Folgen**:
- **Interviews** nach Qualifying und Rennen (kurz, 1–3 Fragen).
- **Pressekonferenzen** nur zu besonderen Anlässen (Saisonstart, Fahrerwechsel, Skandal).
- **Fragen zu konkreten Themen**: Teamkollegen-Duell, Stallorder, Vertragsgerüchte, Kritik am Auto, Konkurrenz.
- **Wirkung** der Antworten auf: Moral einzelner Fahrer/Mitarbeiter, Verhältnis zu anderen Teamchefs, Vertrauen des Besitzers, Sponsorenzufriedenheit, Ruf.
- **Paddock-Gerüchte** in der Inbox (Transfers, Probleme anderer Teams) – manche wahr, manche falsch.
- Fahrer selbst geben Interviews; Traits wie „Medienliebling“ oder „Skandalnudel“ erzeugen eigene Schlagzeilen.

---

## 14. Regeln & Politik (später)
- Regeländerungen alle paar Jahre (Aero, Motor, Reifen).
- Abstimmungen der Teams über Vorschläge.
- Strafen (z. B. für Kollisionen oder Teilewechsel).
- **Spätere Feature-Runde**: Budget Cap, Aero-Testlimit, Motorkontingente.

---

## 15. UI / UX ✅

### 15.1 Ziele
Modern, clean, übersichtlich – der Spieler verbringt den größten Teil der Zeit mit Daten. Es soll **Spaß machen**, sich in den Menüs aufzuhalten.

### 15.2 Grundprinzipien
1. **Alles auf einen Blick.** ✅ Klickt man auf einen Fahrer, sieht man **alle** wichtigen Informationen auf **einem** Bildschirm – ohne Scrollen und ohne sich durch Untermenüs zu klicken. Das gilt für alle Profile (Fahrer, Personal, Teile, Sponsoren). Das gelingt nur mit dichtem, aber sauberem Layout: klare Raster, Gruppierung in Karten, kompakte Darstellungen (Balken, Farben, kleine Diagramme) statt langer Texte. Tabs nur für selten gebrauchte Bereiche (z. B. vollständige Historie).
2. **Jede Zahl ist erklärbar.** ✅ Tooltips zeigen, woraus sich ein Wert zusammensetzt („Rundenzeit-Prognose: Auto +0,3 s, Fahrer −0,1 s, Reifen +0,4 s …“). Das ist der Schlüssel, um Komplexität verständlich zu machen. Technisch: Berechnungen liefern nicht nur das Ergebnis, sondern auch die Liste ihrer Faktoren.
3. **Vergleichen ist einfach.** Zwei Fahrer, Teile oder Angebote nebeneinander, Unterschiede farbig markiert.
4. **Einheitliche Farbcodes.** Z. B. Rot → Gelb → Grün → Lila für Werte, gleiche Farben im ganzen Spiel.
5. **Schnelle Navigation.** Seitenleiste, Zurück-Verlauf, Suche, Klick auf jeden Namen öffnet dessen Profil.
6. **Unsicherheit sichtbar machen.** Gescoutete Werte werden als Bereich oder mit „?“ angezeigt, nicht als falsche exakte Zahl.

### 15.3 Layout
```
┌──────────────────────────────────────────────────────────────────┐
│ Topbar: Team | Datum | Budget | Nächstes Rennen      [ WEITER ▶ ] │
├──────────┬───────────────────────────────────────────────────────┤
│ Home     │                                                       │
│ Inbox    │   Inhaltsbereich                                      │
│ Kalender │   (meist: Liste links + Detailansicht rechts)          │
│ Fahrer   │                                                       │
│ Personal │                                                       │
│ Auto     │                                                       │
│ Motor    │                                                       │
│ HQ       │                                                       │
│ Finanzen │                                                       │
│ Sponsoren│                                                       │
│ Scouting │                                                       │
│ Akademie │                                                       │
│ Markt    │                                                       │
│ Tabellen │                                                       │
│ Besitzer │                                                       │
└──────────┴───────────────────────────────────────────────────────┘
```

### 15.4 Bausteine (wiederverwendbare UI-Szenen)
`StatBar`, `AttributeGrid`, `RangeValue` (für gescoutete Werte), `PersonCard`, `DataTable` (sortier- und filterbar), `MoneyLabel`, `StarRating`, `TrendArrow`, `LineChart`, `ProgressTimer` (Projekte, Bau), `InboxItem`, `CompareView`, `ConfirmDialog`, `Tooltip mit Aufschlüsselung`.

### 15.4b Visueller Stil ✅
- **Stil „Pit Wall“**: angelehnt an die Zeitenmonitore an der Boxenmauer. Dunkles Graphit, feine Linien, eckige Formen (Radius ≈ 2 px), Zahlen in Monospace, Akzentfarbe Bernstein für Überschriften und Hervorhebungen, Teamfarbe als Streifen.
- **Schriften** (frei, OFL): *Barlow Condensed* (Überschriften), *IBM Plex Sans* (Text), *JetBrains Mono* (Zahlen).
- **Farbskala für Attribute 1–20**: 1–5 Rot, 6–10 Bernstein, 11–15 Hellgrün, 16–20 Türkisgrün.
- **Layout „Columns“** für das Fahrerprofil (und als Vorbild für andere Profile): Identität + Bewertung oben, darunter eine Status-Kachelleiste, dann vier gleich hohe Spalten (Fahrerisch · Mental · Körperlich & Traits · Vertrag), unten Saison · letzte Rennen · Beziehungen & Versprechen · Verlauf.
- **Traits** mit Symbol, Name und einem kurzen Satz zur Wirkung (in Godot später freies Icon-Set statt Emoji).
- **Klare Begriffe**: ausgeschriebene Bezeichnungen („Average finishing position“, „Ahead in qualifying: 9 of 14“), „Races“ statt Fußball-Begriffen.
- Referenz-Mockup: [ui_mockups/driver_profile_styles.html](ui_mockups/driver_profile_styles.html) (Layout 1).

### 15.5 Beispiel: Fahrerprofil auf einen Blick
✅ Vorbild ist das **Spielerprofil im Football Manager**: alle Attribute, Persönlichkeit, Vertrag, Form und Statistiken detailliert auf einem Bildschirm.
```
┌────────────────────────────────────────────────────────────────────────────┐
│ [Foto] Marco HALE  🇮🇹 28 J.   Vortex Racing · Nr.-1-Fahrer   CA ████▌ PA ★★★★ │
│ Moral 😊 Hoch · Form ▲ · Selbstvertrauen ▲ · Fitness 94%   Traits: [Regengott] │
├──────────────────┬──────────────────┬──────────────────┬───────────────────┤
│ FAHRERISCH       │ MENTAL           │ KÖRPERLICH       │ VERTRAG           │
│ Kurven      16   │ Nervenstärke 15  │ Fitness     17   │ 4,2 Mio/Jahr      │
│ Bremsen     15   │ Fokus        14   │ Reaktion    16   │ bis Ende 2028     │
│ Quali-Pace  17   │ Aggression   11   │                  │ Ausstieg 12 Mio   │
│ Konstanz    14   │ Feedback     13   │ ERFAHRUNG        │ Boni: Sieg 250k   │
│ Reifen      12   │ Arbeitsmoral 16   │ ███████░░ 112 R. │                   │
│ Überholen   15   │ Ehrgeiz      18   │                  │ SAISON            │
│ Verteidigen 13   │ Loyalität     9   │ ATTRIBUT-TREND   │ P4 · 126 Pkt      │
│ Starts      14   │ Temperament  12   │ [Mini-Diagramm]  │ 2 Siege · 5 Pod.  │
│ Regen       18   │                  │                  │ vs. Teamk. 9:5    │
├──────────────────┴──────────────────┴──────────────────┴───────────────────┤
│ Beziehungen: Teamkollege ▼ angespannt · Renningenieur ▲ sehr gut · Chef ● ok │
│ Letzte 5 Rennen: P3 P1 DNF P5 P2       Versprechen: Nr.-1-Status (gehalten)  │
└────────────────────────────────────────────────────────────────────────────┘
```

### 15.6 Technik
- Globales Godot-**Theme** von Anfang an.
- Freie Schriftart (z. B. *Inter* oder *Roboto*, OFL/Apache-Lizenz) und freie Icons (z. B. *Lucide*, *Material Symbols*).
- Zielauflösung 1920×1080, skaliert auf andere Bildschirme.
- UI enthält **keine Spiellogik** – sie liest Daten und ruft Manager-Klassen auf.

---

## 16. Technische Architektur (Kurzfassung)
- **Datenmodell**: Resources für Definitionen, IDs für Verweise, eigene Laufzeit-Klassen für Rennen.
- **Manager-Klassen** (Logik je System): `ContractManager`, `DevelopmentManager`, `FacilityManager`, `ScoutingManager`, `FinanceManager`, `OwnerManager`, `TransferMarket`, `YouthManager` …
- **Scheduler**: alle zeitbasierten Vorgänge mit Start/Ende.
- **EventBus**: Systeme kommunizieren lose über Signale.
- **Inbox**: zentrale Nachrichtenquelle, jede Nachricht kann auf einen Bildschirm verlinken.
- **Wissensmodell**: pro Team und Person ein Wissensstand (für Scouting).
- **Weltgenerator**: erzeugt Teams, Fahrer, Personal, Sponsoren und jährliche Newgens.
- **Spielstand**: JSON über `to_dict()` / `from_dict()`, mit Versionsnummer.
- **Headless-Simulation** für F2/F3 und Balancing-Tests.
- **Übersetzung**: Alle sichtbaren Texte laufen über Godots Übersetzungssystem (`tr()` mit Schlüsseln, CSV-Übersetzungsdatei). Englisch zuerst, Deutsch später.
- **Plattformen**: Windows und macOS. Dafür: nur `user://` für Spielstände/Einstellungen, keine plattformspezifischen Pfade oder Treiber, Projekt über Git zwischen beiden Rechnern synchronisieren.

---

## 17. Roadmap

| Runde | Inhalt |
|---|---|
| **R0 – Fundament** | UI-Gerüst (Theme, Seitenleiste, Topbar, Navigation, Bausteine), Zeit & Inbox, Datenmodell erweitern, Weltgenerator |
| **R1 – Menschen** | Fahrer-Detailmodell, Personal, Verträge, Transfermarkt |
| **R2 – Saison** | Kalender, Rennwochenende (Quali + Rennen), WM-Tabellen, Preisgeld, Saisonwechsel |
| **R3 – Auto** | Teile, Entwicklungsprojekte, Produktion, Korrelation |
| **R4 – HQ** ✅ | Gelände, Gebäude, Bau, Effekte |
| **R5 – Motor** ✅ | Kunde / Lizenz / Werk |
| **R6 – Geld & Macht** ✅ | Finanzen komplett, Sponsoren, Besitzer, Investoren, Ruf (`docs/finance_model.md`) |
| **R7 – Nachwuchs** ✅ | F2/F3-Simulation, Akademie, Scouting mit Wissensmodell, Newgens, Superlizenz (`docs/youth_model.md`) |
| **R8 – Eigenes Team** | Team gründen, Feld auf 24 Autos |
| **R9 – Regulierung** | Regeländerungen, Budget Cap, Aero-Testlimit, Motorkontingente |
| **Nach R0** | Strecken-Editor und die ersten 4–6 fiktiven Strecken |
| **Laufend** | Rennsimulation verbessern (Safety Car, Wetter, DRS, Boxengasse, Training) |

---

## 18. Entscheidungs-Log
| # | Frage | Entscheidung |
|---|---|---|
| 1 | Attribut-Skala | ✅ Anzeige 1–20, intern 0–100 (umstellbar) |
| 2 | Nach Entlassung | ✅ Jobangebote von Teams, die selbst Ziele verfehlt haben; v1 entlässt nur bei massivem Versagen |
| 3 | Wetter | ✅ Später, in laufenden Runden zur Rennsimulation |
| 4 | Verletzungen | ✅ Ja, mit fest angestellten Ersatzfahrern |
| 5 | Medien | ✅ Tief, aber realistisch verteilt (Interviews, Anlass-Pressekonferenzen, Gerüchte) |
| 6 | Stallorder | ✅ Im Rennen steuerbar; sonst entscheidet der Strategiechef |
| 7 | Schwierigkeit | ✅ v1 nur Teamstärke; Stufen am Ende |
| 8 | Saisonlänge | ✅ Wie F1: ca. 24 Rennen + Vorsaison-Tests |
| 9 | Spielstände | ✅ v1 ein Spielstand, mehrere Karrieren später |
| 10 | Eigene Fahrer kennen | ✅ Nach 1–3 Rennwochenenden exakt |
| 11 | Kosten | ✅ Nur kostenlose Tools und Assets |
| 12 | Eigenes Personal kennen | ✅ Sofort nach der Einstellung exakt |
| 13 | Sprint-Wochenenden | ✅ Nicht in v1 |
| 14 | Teamchef-Avatar | ✅ Ja, mit Hintergrund und kleinen Boni |
| 15 | Teamauswahl | ✅ Alle 11 Teams frei wählbar |
| 16 | Spielsprache | ✅ Übersetzungssystem von Anfang an, **Englisch und Deutsch ab Start** (i18n/strings.csv, Umschaltung in der Seitenleiste) |
| 17 | Spielwelt | ✅ Feste Startwelt + laufend generierte Nachwuchs-/vertragslose Personen |
| 18 | Strecken | ✅ Erst nach v0, dann mit Strecken-Editor |
| 19 | KI-Teams | ✅ Gleiche Regeln wie der Spieler |
| 20 | Delegieren | ✅ Ja, Qualität des Personals bestimmt das Ergebnis |
| 21 | Vertragsverhandlung | ✅ Formular mit Live-Feedback, mehrere Runden |
| 22 | Teile pro Auto | ✅ Jedes Auto eigener Teile-Stand |
| 23 | Training | ✅ Einfacher Schwerpunkt; Trainingsqualität hängt vom Fahrer ab |
| 24 | Vorgeschichte | ✅ Ja, erfundene Historie |
| 25 | Teamstimmung | ✅ Ein übersichtlicher Gesamtwert |
| 26 | Geld | ✅ Realistische F1-Größenordnungen |
| 27 | Plattform | ✅ Lokal auf Windows + macOS, kostenlos/Open Source |
| 28 | UI-Stil | ✅ „Pit Wall“ (dunkel, Telemetrie-Look, Bernstein-Akzent) |
| 29 | Profil-Layout | ✅ „Columns“ (FM-ähnlich, vier Spalten) |
| 30 | Zeitsteuerung | ✅ Zwei Buttons: passiv „+1 Tag“ und aktiv „Weiter“ (bis zum nächsten wichtigen Ereignis) |
| 31 | Simulation zuerst | ✅ Training, Quali, Rennen erst als reine Simulation; 2D-Rennen danach; am Ende pro Session „simulieren“ oder „zuschauen & mitentscheiden“ |
| 33 | Personal-Rollen | ✅ 16 Schlüsselrollen pro Team, so realitätsnah wie möglich |
| 34 | Verhandlung | ✅ Direktes Gespräch mit dem Berater, Unterschrift einige Tage später (andere Teams können dazwischenfunken) |
| 35 | Gehälter | ✅ Ab R1 monatlich vom Budget, plus Handgeld und Abfindungen |
| 36 | Wissensmodell | ✅ Ab R1: Bekannte perfekt, Unbekannte/Jugend als grobe Bereiche, Eigene exakt; Scouting in R7 |
| 37 | Personal-Traits | ✅ Ja, Personal hat Persönlichkeit und Traits |
| 38 | Mockups | ✅ Für jede neue Grafik oder Grafik-Idee zuerst ein HTML-Mockup |
| 39 | Unsichere Werte | ✅ **Bereichsbalken** (Band auf der Skala 1–20, unsichere Sterne als Umriss) – in Markt-Tabelle und Personen-Vorschau |
| 40 | Verhandlung | ✅ **Gespräch im Mittelpunkt**: Gesprächspunkte (teils riskant) beeinflussen die Stimmung, Angebote erscheinen als Karten im Gespräch; Zufriedenheit = Angebot + Gesprächsklima; Prioritäten des Beraters erst nach Nachfrage sichtbar |
| 42 | Teamstimmung (Anzeige) | ✅ Wert 0–100 in fünf Stufen (Krise, Angespannt, Ruhig, Gut, Euphorie). Sichtbar als **Block in der Topbar** (mit Balken und Aufschlüsselung im Tooltip) und als **Karte auf der Startseite** (Halbkreis-Anzeige + alle Faktoren) |
| 43 | 2D-Rennansicht | ✅ Wird von einer **zweiten Person** gebaut (Autos, Strecken, Test Ring). Test Ring und „Testrennen ansehen“-Button bleiben bestehen. Unser Fokus: die Simulation. |
| 44 | Rennwochenende-Tempo | ✅ Session für Session, aber **schnell** – wer es detaillierter will, schaut/spielt später das 2D-Rennen |
| 45 | Preisgeld | ✅ Realistische Größenordnung, muss für Gebäude-Ausbau reichen; **der Weltmeister muss sich den besten Fahrer leisten können**. Alle Preise (Gehälter, Gebäude, Teile) werden darauf abgestimmt – wird mehrfach nachjustiert. |
| 46 | Wetter in der Simulation | ✅ Schon in R2: Regen macht gute Regenfahrer schneller, schlechte machen mehr Fehler; realistische, detaillierte Ergebnisse |
| 47 | F2/F3 | ✅ Bleibt in R7 (Nachwuchs, Jugendfahrer, Training, Supertalente) |
| 41 | Abwechslung im Gespräch | ✅ Großer Pool an Gesprächspunkten, pro Gespräch eine zufällige Auswahl (verbrauchte werden ersetzt), Antworten in mehreren Varianten und abhängig von Berater-Persönlichkeit und Situation, **riskante Optionen mit großen Ausschlägen** nach oben und unten. Darf auch nach vielen Verhandlungen nicht langweilig werden. |
| 48 | Simulationsmodell | ✅ Rundenzeit in Sekunden-Anteilen, alles ab Anfang im Detail (Reifentemperatur, Sprit, Teilschäden, Wetter, SC); Formeln in simulation_model.md |
| 49 | Gewichtung | ✅ Auto ~70 %, Fahrer und Personal sollen sich lohnen (mehr als in der echten F1) |
| 50 | Siegquoten | ✅ Abhängig vom Auto-Vorsprung: dominant + Top-Fahrer 70–85 %, dominant + schwacher Fahrer 15–30 %, enges Feld 30–40 % |
| 51 | Boxenstopp | ✅ Minimum 2,0 s, große Unterschiede je nach Crew; perfekte Crews machen keine schweren Fehler |
| 52 | Safety Car | ✅ Nur durch Ereignisse (Unfälle, Ausfälle, Trümmer), beliebig oft pro Rennen; VSC und rote Flagge |
| 53 | Strecke | ✅ Vorerst nur Test Ring (wird nicht verändert), Rennen mit unterschiedlichen Bedingungen; echte Strecken kommen von der zweiten Person |
| 54 | Fahrergespräche | ✅ Variante B: Briefing als schnelle Taktikwahl (mit Auswirkungen + Empfehlung), **1:1 fix vor jedem Rennen**, seltene Gespräche auf Wunsch des Fahrers mit mehr Tiefe; große Abwechslung |
| 55 | Fahrmodus | ✅ Nur im 2D-Modus; in der Simulation nur Briefing, 1:1, Strategie, Schlüsselmomente |
| 56 | Flügelstufe | ✅ Entscheidung des Teamchefs nach Rücksprache mit dem Ingenieur |
| 57 | Entwicklung | ✅ Fahrer und Personal (inkl. Boxencrew) werden durch Training/Leistung besser und bauen ohne Training/bei schlechter Leistung ab |
| 32 | Gesichter | ✅ Prozedurale Porträts im Stil **„Flat“** mit vielen Merkmalen für alle Personen (R0). Helm-Designs vorerst **nicht** im UI – überall werden Gesichter verwendet. |

## 19. Offene Fragen ❓
*(siehe Diskussion – wird nach Beantwortung ins Log übernommen)*
