# Backlog – Bugs, Feinschliff, offene Punkte

Regel: **Kaputtes oder Störendes sofort beheben.** Feinschliff wird gesammelt und am Ende jeder Runde abgearbeitet. Erledigtes wird abgehakt und bleibt als Verlauf stehen.

## 📍 Stand (24.10.2026)
**R2 Teil 1 + 2 fertig:** ganze Saison spielbar – Rennwochenende (Ziel, Training, Stallorder → Training & Quali → Strategie, Regen-Poker, Briefing, **1:1-Gespräche** → Rennen mit **Schlüsselmomenten**), detailliertes Rennergebnis, Tabellen, Kalender, Startseiten-Karten, Saisonrückblick mit Preisgeld, Saisonwechsel.
**Nächster Schritt:** Rest von R2 = Altern und Entwicklung von Fahrern/Personal über den Winter (siehe „Offen aus R2“). Danach Styling-Änderungen, UI-Feinschliff und Kleinkram.

## 🐞 Bugs
- [ ] *(noch keine offenen)*

## ✨ UI-Feinschliff
- [ ] *(noch keine offenen)*

## 📌 Offen aus R1 (später)
- [ ] **Delegieren** an den Sportdirektor (Verträge für Nachwuchs, Ersatzfahrer, Personal) – sinnvoll ab R2/R3 (Design-Dok. 5.4)
- [ ] **Abwerben ohne Ausstiegsklausel**: mit dem anderen Team über eine Ablöse verhandeln
- [ ] **KI-Teams werben eigenes Personal ab** (Interesse anderer → Angebote, Inbox-Meldung)

## 📌 Offen aus R2 (Saison)
- [ ] 1:1-Gespräche: mehr Themen und Formulierungen (Design-Dok.: ~30 Themen, mehrere Formulierungen je Persönlichkeit), Inhalte später in Datendateien; weitere Auslöser für Gesprächswünsche (Angebot eines Rivalen, Streit mit dem Ingenieur, Angst nach Unfall)
- [ ] Versprechen aus Gesprächen („Gleichbehandlung“, „bald Vertragsgespräche“) haben noch keine Frist und werden nicht geprüft
- [ ] Schlüsselmoment „Reparatur“ (Design-Dok. 11.3) fehlt noch
- [ ] Altern und Entwicklung von Fahrern und Personal über den Winter; Rücktritte alter Fahrer
- [ ] Ersatzfahrer bei Verletzung/Krankheit einsetzen; Flügelstufe als Entscheidung
- [ ] Besitzer-Ziel im Saisonrückblick (kommt mit R6 Besitzer)
- [ ] Saisonrückblick: „Große Momente“ nur aus Ergebnissen (Siege, Podien, Poles) – später auch Strategie-Treffer, Boxenstopp-Pannen, Gespräche

## 📌 Offen aus R2 (Simulation)
- [ ] **2D-Ansicht auf die neue Simulation umstellen** – erst viel später, gemeinsam mit der zweiten Person (alter `RaceSim` bleibt bis dahin unverändert)
- [ ] **Platzhalter-Strecken ersetzen**, sobald die echten Strecken gebaut sind (`sim/weekend/track_layouts.gd`)
- [ ] Feinabstimmung im Sim-Labor laufend (Werte in `sim/weekend/sim_tuning.gd`, Strecken-Werte in `track_layouts.gd`)
- [ ] **Top-Stratege bringt nach oben noch zu wenig** (95 ≈ 60, 25 = −28 Pkt./Saison). Ideen: Reifenwahl im Qualifying (Q2-Reifen), Streckenentwicklung, Tankmenge je nach Fahrer
- [ ] Vorgespielte Runden der Testwelt laufen noch über `QuickRace` (schneller Spielstart) – Detail-Ergebnisse gibt es erst ab dem ersten echten Rennen

## ✅ Erledigt
- [x] **R2 Teil 2:** Schlüsselmomente im Rennen (Safety Car/VSC: wer stoppt, Regen/abtrocknende Strecke: Reifenwechsel, Stallorder: tauschen/fahren lassen/halten – mit Weigerungsrisiko), max. 4 pro Rennen, Empfehlung des Strategiechefs, „Bis zum Ende simulieren“; 1:1-Gespräche (wöchentlich: Thema aus der Lage des Fahrers, 4 Antworten, Wirkung je nach Persönlichkeit, unbekannte Reaktionen, Abnutzung; auf Wunsch des Fahrers: 3 Fragen, Gesprächsstimmung skaliert bleibende Effekte, Versprechen, Wechselwunsch/Loyalität), Mentaltrainer kann übernehmen
- [x] **R2 Teil 1 – Saison spielbar:** Rennwochenende in Schritten (alle Entscheidungen auch an das Personal delegierbar), Rennergebnis mit Rundenzeiten-Grafik, Boxenstopps, Reifen-Stints und Ereignissen, Tabellen (Fahrer mit Ergebnis-Raster, Teams mit Preisgeld), Kalender mit Streckencharakter und „passt zu unserem Auto“, Saisonrückblick, Preisgeld, Saisonwechsel inkl. **Vertragsende zum Saisonende**
- [x] Absturz bei leerer Saisonstatistik (Startseite, Fahrerprofil) zu Beginn einer neuen Saison
- [x] **Major Bug:** Unterschrift trotz besetzter Stelle (z. B. 4 Fahrer). Jetzt feste Plätze (2 Cockpits, 1 Ersatzfahrer, 2 Renningenieure, je 1 andere Rolle); in der Verhandlung wählen, wer Platz macht (entlassen oder Ersatzfahrer), wird bei der Unterschrift umgesetzt; KI-Teams entlassen automatisch den Schwächsten
- [x] Inhalt rechts abgeschnitten: Topbar war nach dem Stimmungs-Block breiter als der Platz und hat den ganzen Inhalt verschoben (Topbar kompakter, Titel wird gekürzt statt zu schieben); Markt-Spalte „Bekannt“ ohne Scrollen sichtbar
- [x] R1-Abschluss: Teamstimmung (Topbar + Startseiten-Karte), Moral-Folgen (Entlassung, gescheiterte/erfolgreiche Verlängerung, Neuverpflichtung, Versprechen), Versprechen aus Verhandlungen werden gespeichert und zur Frist geprüft, Shortlist-Hinweise (Vertrag läuft aus, vertragslos, wechselt woandershin)
- [x] Verzerrtes Fahrerbild im Verhandlungsfenster
- [x] Verwirrende Meldung, wenn ein Rivale vor der Unterschrift dazwischenfunkt (jetzt „Transfer geplatzt“, Risiko sichtbar, mit Handgeld senkbar)
- [x] Personalliste per Klick auf Spalten sortierbar
- [x] Markt-Vorschau: Scouting-Dauer, mehr Details, Button-Anordnung, „Gespräche beginnen“ als Hauptbutton
- [x] Die beiden Renningenieure unterscheidbar („Renningenieur · Hale“)
