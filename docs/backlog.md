# Backlog – Bugs, Feinschliff, offene Punkte

Regel: **Kaputtes oder Störendes sofort beheben.** Feinschliff wird gesammelt und am Ende jeder Runde abgearbeitet. Erledigtes wird abgehakt und bleibt als Verlauf stehen.

## 📍 Stand (24.10.2026)
**R2 Teil 1 fertig – eine ganze Saison ist spielbar:** Rennwochenende (Ziel, Training, Stallorder → Training & Quali → Strategie, Regen-Poker, Briefing → Rennen), detailliertes Rennergebnis, Tabellen, Kalender, Startseiten-Karten, Saisonrückblick mit Preisgeld, Saisonwechsel (Verträge laufen aus, Ersatzfahrer rückt nach, Statistiken auf null).
**Nächster Schritt – R2 Teil 2:** Schlüsselmomente im Rennen (Safety Car / Regen / Stallorder, Hook `RaceEngine.decide` ist vorbereitet) und 1:1-Gespräche (Mockup `r2_driver_talk.html`, Effekte über `SimCar.talk`).

## 🐞 Bugs
- [ ] *(noch keine offenen)*

## ✨ UI-Feinschliff
- [ ] *(noch keine offenen)*

## 📌 Offen aus R1 (später)
- [ ] **Delegieren** an den Sportdirektor (Verträge für Nachwuchs, Ersatzfahrer, Personal) – sinnvoll ab R2/R3 (Design-Dok. 5.4)
- [ ] **Abwerben ohne Ausstiegsklausel**: mit dem anderen Team über eine Ablöse verhandeln
- [ ] **KI-Teams werben eigenes Personal ab** (Interesse anderer → Angebote, Inbox-Meldung)

## 📌 Offen aus R2 (Saison)
- [ ] **Schlüsselmomente im Rennen** (2–4 pro Rennen, Simulation pausiert) – R2 Teil 2
- [ ] **1:1-Gespräche** vor jedem Rennen + Gespräche auf Wunsch des Fahrers – R2 Teil 2
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
