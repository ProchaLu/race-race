# Nachwuchs, Akademie & Scouting (R7)

> Ziel: Die Zukunft des Teams entsteht im Nachwuchs. Jedes Jahr kommt ein Jahrgang neuer Talente, sie gehen durch F3 und F2 in den F1-Markt, das eigene Team kann sie in der Akademie ausbilden und platzieren, und der Chefscout zeigt, wer wirklich etwas taugt – mit Unsicherheit.
> Verwandt: Design-Dokument Kapitel 3.9 (Superlizenz), 4 (Jugend & Scouting), `docs/finance_model.md` (Kosten), `docs/hq_screen_design.md` (Gebäude).
> **Alle Zahlen sind Startwerte.** Feinabstimmung kommt mit dem Playtest.

---

## 0. Grundprinzipien

1. **Eine Pyramide mit festen Stufen.** Newgens → Apex F3 → Apex F2 → F1 (nur mit Superlizenz). Jede Stufe hat feste Plätze, und Plätze werden jedes Jahr neu vergeben.
2. **Nachwuchsserien laufen im Hintergrund.** Keine Budgets, keine Teams mit Personal, keine Autoentwicklung. Ergebnisse entstehen aus Fähigkeit, Teamstärke und Zufall.
3. **Man sieht nicht alles.** Gescoutete Werte sind Bereiche, und ein schwacher Scout kann ganze Bereiche verschieben. Exakte Werte gibt es nur für eigene Leute (Vertrag oder Akademie).
4. **Gleiche Regeln für KI und Spieler.** KI-Teams haben Akademien, verpflichten Junioren und platzieren sie (Abschnitt 10). Ihr Scouting ist vereinfacht: ein fester Schätzfehler, kleiner mit besserem Scouting-Büro.

---

## 1. Die Pyramide

| Stufe | Teams | Plätze | Alter | Rein | Raus |
|---|---|---|---|---|---|
| Kart (3 Regionen, verborgen) | – | 24 neue pro Jahr | 14–15 | Jahrgang mit 14 | mit 16 in den Pool (dann für alle sichtbar) |
| Pool (ohne Team) | – | – | 16–24 | aus dem Kart, aus F3/F2 | Akademie, Platz in F3/F2 oder zu alt |
| Apex F3 | 10 | 2 je Team = 20 | bis 20 | Pool (beste Werte zuerst) | zu alt oder Platz verloren |
| Apex F2 | 10 | 2 je Team = 20 | bis 24 | Pool und F3 (beste Werte zuerst) | zu alt |
| F1-Markt | – | – | – | Ex-Junioren mit Superlizenz | – |

**Saisonwechsel** (`Youth.new_season`, nach der Winterentwicklung):
1. Junioren über dem Höchstalter gehen. Mit Superlizenz kommen sie auf den F1-Markt, ohne Lizenz verlassen sie den Sport (Ruhestand).
2. Alle Juniorenplätze werden neu besetzt. **Akademie-Platzierungen bleiben erhalten** und kosten erneut.
3. Der Jahrgang kommt in den Pool (24 Newgens).
4. F2 zuerst: Die besten Junioren bis 24 Jahre füllen die 20 Plätze.
5. F3: Die besten Übrigen bis 20 Jahre füllen die 20 Plätze.
6. Akademie: Wachstum im Winter (Abschnitt 4).
7. Teamstärke der Juniorenteams schwankt um ±3 (Grenzen 30–75).

Der Wert eines Juniors für die Auswahl: **Gesamtwert + halbes Potenzial**.

---

## 2. Juniorrennen

- Pro F1-Runde fährt jede Juniorenserie einmal (`Youth.resolve_round`, nach dem F1-Rennen).
- Stärke je Fahrer: Gesamtwert × 0,8 + Teamstärke × 0,3 + Zufall (±6). Die Reihenfolge ergibt sich daraus.
- Ausfall: 3 % je Rennen.
- Punkte wie in der F1 (25 bis 1 für die ersten zehn).
- Die Tabellen gelten für eine Saison (`GameState.youth_standings`). Am Saisonwechsel werden sie zurückgesetzt.
- Pro Fahrer werden Starts (`starts`) und das letzte Ergebnis (`last`, 0 = Ausfall) gespeichert.
- Ein Juniorrennen wird nicht einzeln gezeigt. Die Ergebnisse stehen im Akademie-Bildschirm (Top fünf, eigene Fahrer mit Tabellenplatz und letztem Rennen) und in der Saisonmeldung.
- **Rundenbericht:** Nach jeder Runde schickt der Akademieleiter eine Nachricht mit Platz, Tabellenplatz und Punkten jedes eigenen platzierten Fahrers (`Academy.round_report`).

### 2a. Rennpraxis zählt
Die Winterentwicklung aller Fahrer (`Development._develop_driver`) hängt an der Rennpraxis. Für Junioren gilt `Youth.practice`:
- Ohne Rennen: Pool 0,45, Akademie ohne Sitz 0,55.
- Mit Rennen: Grundwert + (Serie − Grundwert) × Anteil der gefahrenen Rennen. Volle Saison: **F2 0,9, F3 0,8** (F1-Stammfahrer 1,0).
- Bonus für Ergebnisse: Punkte pro Start / 25 × 0,3, höchstens +0,15.
- Die Akademie-Entwicklung (Abschnitt 4) kommt obendrauf.

---

## 3. Superlizenz

- Punkte am Saisonende nach Endplatzierung:
  - **Apex F2:** 40 / 30 / 20 / 10 / 5 (Plätze 1–5)
  - **Apex F3:** 5 / 3 / 1 (Plätze 1–3)
- Gesamt zählen die **letzten drei Saisons** (`DriverData.superlicence_points`). 40 Punkte geben die Lizenz (`has_superlicence`).
- **Vereinfachung:** Einmal erreicht, bleibt die Lizenz. Ein Verfall nach drei Jahren ist nicht eingebaut.
- Der F1-Markt zeigt nur Fahrer, die frei sind, nicht zu den Junioren gehören und eine Lizenz haben (`GameState.free_drivers`). Junioren erscheinen dort nie, auch nicht mit Lizenz, solange sie in der Pyramide sind. Erst beim Altersabgang werden sie frei.
- Meldung am Saisonende, wenn eine Lizenz neu erworben wurde.

---

## 4. Akademie

Gebäude `academy` (HQ, 4 Mio. $ Basis, bisher gesperrt bis R7, jetzt bebaubar).

- **Plätze** nach Gebäudestufe 0–5: 0 / 2 / 3 / 4 / 6 / 8. Davon fahren **höchstens 2 in der F3 und 2 in der F2** gleichzeitig; die übrigen fahren Kart oder trainieren ohne Sitz.
- **Aufnahme:** Junioren bis 22 Jahre, frei im Pool **oder mit Sitz in F3/F2** (der Sitz bleibt, er gilt dann als platziert). **Einmalgebühr 250 000 $**, danach **40 000 $ je Fahrer und Monat**. Wenig bekannte Junioren kann man direkt aus der Liste scouten oder „blind“ verpflichten.
- **Platzierung** bei jedem Juniorenteam, dessen Alter passt, auch während der Saison. **Gebühr je Saison:** F3 300 000 $, F2 900 000 $. Sie wird bei jeder Platzierung und beim Saisonwechsel fällig.
- **Sitz kaufen:** Ist das Team voll, ersetzt der Akademiefahrer den schwächeren der beiden Fahrer, der kein Akademiefahrer ist (er geht in den Pool). Ablöse obendrauf: **F3 250 000 $, F2 750 000 $** (`Academy.seat_offer`). Sind beide Sitze Akademiefahrer, geht es nicht.
- **Zurückholen:** Der Fahrer bleibt in der Akademie, der Sitz wird frei.
- **Freigeben:** Der Fahrer verlässt die Akademie und die Junioren.
- **Entwicklung im Winter:** Anteil der Lücke zum Potenzial, der pro Winter aufgeholt wird:
  `0,15 × (0,6 + Fähigkeit des Akademieleiters / 100) × (1 + 0,1 × Stufe)`, höchstens die ganze Lücke. Wirkt gleichmäßig auf die Fahrattribute des Fahrens.
- **Wissen:** eigene Akademiefahrer sind exakt bekannt (100 %).
- **Rennbetrieb:** bestehender Hook – Akademiefahrer im FP1 (`RaceWeekend.has_academy_driver`).
- Der Akademieleiter (`StaffData.Role.ACADEMY_HEAD`, Fähigkeit „Nachwuchsförderung“) ist der einzige Einfluss auf das Tempo. Ohne Leiter gilt 30.

---

## 5. Scouting

Gebäude `scouting` (HQ, 2 Mio. $ Basis, bisher gesperrt bis R7, jetzt bebaubar). Der Chefscout (`Knowledge.chief_scout`) arbeitet von dort aus.

- **Aufträge gleichzeitig** = Stufe des Büros. Stufe 0 heißt kein Scouting.
- **Ziele** (bis 8 Personen, nach Wert sortiert):
  - **Serie:** alle Juniorenplätze einer Serie (Apex F3, Apex F2)
  - **Region:** Europa, Amerika, Asien & Pazifik (Nationalität)
  - **Einzelner Junior**
- **Kosten:** 40 000 $ je Person, Finanzkategorie „Scouting“. Personen, die schon gut bekannt sind, zählen nicht mit.
- **Ziel des Auftrags:** Wissensstand `70 + 0,2 × Fähigkeit` (Fähigkeit = Mittel aus Urteilskraft Fähigkeit und Potenzial des Chefscouts). Fähigkeit 50 ergibt 80, Fähigkeit 100 ergibt 90 (exakt). Ohne Chefscout gilt Fähigkeit 10.
- **Fortschritt pro Woche:** `4 + Fähigkeit / 12` Wissenspunkte. Die Dauer ist die der langsamsten Person.
- **Fehlgriff:** Chance `max(0; 0,5 − Fähigkeit / 200)`: 50 % bei Fähigkeit 0, 25 % bei 50, nie ab 100. Dann wird der Bereich um 1 bis 3 Anzeigepunkte verschoben, getrennt für Fähigkeit und Potenzial. Der wahre Wert liegt dann außerhalb des Bereichs. Ein Fehlgriff entfällt bei eigenen Leuten.
- **Bericht:** Nachricht im Posteingang mit der Empfehlung je Person.
- **Empfehlung** (Schlüssel `Scouting.recommendation`):
  - Wissen unter 40: „Noch zu wenig bekannt“
  - Alter über 21: „Nicht interessant“
  - Potenzial-Mitte ab 4 Sterne: „Sofort verpflichten“
  - ab 3 Sterne: „Beobachten“
  - sonst: „Nicht interessant“

Wissensmodell (`core/knowledge.gd`): Die Formel für die Breite der Bereiche bleibt. Neu sind eigene Akademiefahrer (100 %) und die Verschiebung durch einen Fehlgriff (`GameState.scout_bias`).

---

## 6. Startwerte

| Größe | Wert |
|---|---|
| Juniorenteams | 10 F3, 10 F2, je 2 Plätze |
| Newgens pro Jahr | 24 |
| Höchstalter | F2 24, F3 20, Akademie-Aufnahme 22 |
| Superlizenz | 40 Punkte in drei Saisons |
| Akademie: Aufnahme / Monat / Platzierung F3 / F2 | 250 000 $ / 40 000 $ / 300 000 $ / 900 000 $ |
| Sitz kaufen: Ablöse F3 / F2 | 250 000 $ / 750 000 $ |
| Rennpraxis: Pool / Akademie / F3 / F2 / Ergebnisbonus | 0,45 / 0,55 / 0,8 / 0,9 / bis +0,15 |
| Akademie: Entwicklung je Winter | 0,15 Anteil der Lücke, skaliert |
| Scouting: Kosten je Person | 40 000 $ |
| Scouting: Ziel / Wochengewinn | 70 bis 90 / 4 + Fähigkeit/12 |
| Scouting: Fehlgriff | 50 % bei Fähigkeit 0, 0 % ab 100 |

---

## 7. Technik

| Datei | Inhalt |
|---|---|
| `core/youth.gd` | Juniorenteams, Newgens, Saisonwechsel, Juniorenrennen, Superlizenz, Tabellen |
| `core/academy.gd` | Plätze, Aufnahme, Platzierung, Gebühren, Winterentwicklung |
| `core/scouting.gd` | Aufträge, Wochenfortschritt, Fehlgriff, Berichte, Empfehlung |
| `data/classes/youth_team.gd` | Juniorenteam (zwei Plätze, Teamstärke) |
| `ui/screens/academy_screen.gd` | Akademie: Fahrer, Platzierung, Juniorenpool, Juniorentabellen |
| `ui/screens/scouting_screen.gd` | Scouting: Aufträge, laufende Aufträge, Berichte |
| `tools/youth_check.gd` | Prüfung: Teams, Saisonwechsel, Akademie, Scouting, Lizenz, eine ganze Saison |

Angebunden in: `season.gd` (Tag, Monat, Rennen, Saisonwechsel, Saisonende), `test_world.gd` (Startwelt), `game_state.gd` (Zustand, F1-Markt), `knowledge.gd`, `facilities.gd` (Gebäude und Wirkung), `finance.gd` (Kategorien und Prognose), `person_generator.gd` (Newgen-Stufe), `market_screen.gd` und `driver_list_screen.gd` (Junioren gehören nicht in diese Listen).

---

## 8. Nicht enthalten / offen

- **KI-Bau:** `Facilities.AI_WEIGHT` kennt Akademie und Scouting-Büro noch nicht; die KI baut sie nicht aus (Startstufen aus dem Weltgenerator).
- **Personal scouten** (Design 4.3, „auch Personal kann gescoutet werden“) fehlt.
- **Reserve- und Testfahrer aus der Akademie** (Design 4.2): nur der FP1-Hook ist da, kein fester Reserve-Platz.
- **Kontakte:** Platzierung über Netzwerk ohne Gebühr (Design 4.3, „Network / Region“) fehlt.
- **Lizenzverfall** nach drei Jahren: vereinfacht, siehe Abschnitt 3.
- **Speichern und Laden:** Der Juniorenzustand (`youth_teams`, `youth_standings`, `scout_assignments`, `scout_bias`, `next_scout_id`) muss beim Speichern erfasst werden, sobald Speichern kommt.
- **Juniorentabellen** nur im Akademie-Bildschirm, nicht im Tabellen-Bildschirm.
- **Playtest:** Stärke der Newgens, Lernrate, Akademiekosten und Ausfallrate der Juniorenrennen sind Startwerte.
- **Abgang und Entlassung** gehören zu R8.


---

## 9. Talente entdecken (Y1, 06.11.2026)

- **Kart als verborgene Stufe:** Jeder Jahrgang (24) beginnt mit 14 im Kart, aufgeteilt nach Region (Europa, Amerika, Asien & Pazifik, nach Nationalität). Drei Kartmeisterschaften fahren nach jeder F1-Runde (Stärke 45, Ausfall 5 %). Kartkinder sind **unsichtbar**, bis ein Scout sie findet (`GameState.discovered`). Mit 16 wechseln sie in den Pool und sind für alle sichtbar.
- **Wunderkinder und Spätzünder:** pro Jahrgang 1–2 Wunderkinder (Potenzial 86–95, schnelle Entwicklung) und 2 Spätzünder (heute 5–10 schwächer, Potenzial +32–42, Entwicklungsrate 1,3–1,5, späterer Höhepunkt). Versteckt (`DriverData.talent`); der Bericht deutet es ab 70 % Wissen an.
- **Scout-Netzwerk:** Chefscout plus angestellte Scouts (Rolle `SCOUT`, nicht unter den 16 Schlüsselpositionen). Höchstens ein Scout pro Bürostufe. Gleichzeitige Aufträge = Bürostufe, aber jeder Auftrag braucht einen freien Scout. Gehalt nach Können (180 000 $ × 0,6–1,6, Vertrag 2 Saisons). Der beste freie Scout fährt.
- **Regionsreise:** wie bisher bekannte Junioren der Region, plus Entdeckung: 2 + Netzwerk/20 Kartkinder (+2 in der Heimatregion des Scouts). Gute Ergebnisse und ein guter Blick für Potenzial helfen, die Juwelen zu finden. Kosten +60 000 $, mindestens 4 Wochen. In der Heimatregion 25 % schneller.
- **Rennen ansehen:** Ein Scout fährt zum nächsten Rennwochenende einer Serie (F2 60 000 $, F3 50 000 $, Kart 30 000 $). Danach +30 Wissen für jeden Fahrer dort; beim Kart findet er bis zu 6 Kinder (die Besten zuerst).
- **Bericht** (`Scouting.report_lines`): Stärken und Schwächen (aus den bekannten Bereichen), ab 60 % Charakter (Arbeit, Druck, Temperament, Ehrgeiz, Professionalität) und ein Vergleich mit einem F1-Fahrer gleichen Fahrstils, Hinweis auf Wunderkind/Spätzünder, Sicherheit der Einschätzung.
- **Beobachtungsliste:** Stern an jedem Junior (gleiche Liste wie der Transfermarkt). Siege der beobachteten Junioren stehen im Rundenbericht, Wechsel in fremde Akademien kommen als Nachricht.

## 10. Wettbewerb um Junioren (Y2)

- **KI-Akademien:** jeden Monat 30 % Chance je KI-Team mit freiem Platz: es verpflichtet den Junior (bis 19), den es am höchsten schätzt (Wert ab 86). Kartkinder sieht die KI erst ab Scouting-Büro 2. Zum Saisonstart platziert die KI ihre Akademiefahrer (F2 ab Gesamtwert 56).
- **Angebot statt Knopfdruck:** Laufzeit (1–3 Saisons), Versprechen (keins / Juniorensitz / F2-Sitz nächste Saison), Handgeld (0 / 50 000 / 150 000 / 300 000 $). Interesse = 30 + Teamruf × 0,3 + Akademiestufe × 4 + Mentoring des Leiters × 0,08 + Versprechen (+8 / +16) + Handgeld (+2 je 25 000 $, max. +16) + Laufzeit (+4 / 0 / −4) − Ehrgeiz/15 (ohne Sitz und ohne Versprechen) − 6 (Wunderkind) − 5 (aus fremder Akademie). Er sagt ja ab **60** und nur, wenn keine rivalisierende Akademie ihn mehr reizt.
- **Akademievertrag:** Laufzeit, **Ausstiegsklausel** = 1,5 × Marktwert. Marktwert = (Wert − 70) × 120 000 $, mindestens 300 000 $. Junioren fremder Akademien kann man nur über die Klausel herauskaufen.
- **Abwerben:** Jeden Monat 8 % Chance (doppelt bei Stimmung unter 45) je wertvollem Junior: eine andere Akademie macht ein Angebot (zwei Wochen gültig) – oder zahlt bei einem unzufriedenen Junior gleich die Klausel.
- **Versprechen:** fällig beim ersten Juniorenrennen der nächsten Saison. Gehalten: Stimmung +8. Gebrochen: −25, im Jahr danach noch −10.
- **Vertragsende:** zufriedene Junioren (Stimmung ab 45) verlängern um zwei Saisons, unzufriedene gehen. „Verlängern“ kostet 100 000 $ je Saison.

## 11. Entwicklung (Y3)

- **Trainingsschwerpunkt:** Tempo, Zweikampf, Reifen & Konstanz, Regen, Fitness, Mentale Stärke. Schwerpunkt-Attribute ×1,8, die anderen ×0,7 der Akademie-Entwicklung im Winter.
- **Mentor:** ein eigener F1-Fahrer (Stamm- oder Ersatzfahrer): Wachstum ×1,1, mit der Eigenschaft „Mentor“ ×1,25; Stimmung +6.
- **Nachwuchstest am Saisonende:** bis zu 2 Junioren, je 150 000 $: +1 auf drei Fahrattribute, Stimmung +8, Bericht mit dem Abstand zur Bestzeit des eigenen schnellsten Fahrers.
- **Stimmung:** kein Juniorensitz ab 16 (−10), F2-Sitz (+6), Mentor (+6), Test (+8), Versprechen (+8 / −25), Aufnahme (+5). Unzufriedene werden eher abgeworben und gehen am Vertragsende.

## 12. Sichtbarkeit (Y4)

- **Juniorenprofil** (`ui/screens/junior_profile_screen.gd`): Steckbrief, Saison (Platz, Punkte, Siege, Rennen, letztes Rennen, Rennpraxis), Juniorenkarriere (eine Zeile pro Saison, `DriverData.junior_history`), Scoutingbericht, Angebot bzw. Akademieplan, Vertrag und Weg in die F1. Alle Junioren öffnen dieses Profil.
- **Tabellen-Bildschirm:** Reiter „Junioren“ mit F2, F3 und den drei Kartserien (Fahrer, bei F2/F3 auch Teams). Nicht entdeckte Kartkinder erscheinen als „Unbekanntes Kind“.
- **Nachrichten:** Rundenbericht (eigene Junioren, Siege der Beobachtungsliste), Fahrerlager-Gespräch über Wunderkinder mit 3 Siegen, Wechsel beobachteter Junioren, Angebote, Versprechen, Vertragsende, Kartmeister am Saisonende.

## 13. Der Weg in die F1 (Y5)

- **Befördern:** mit Superlizenz zum Ersatzfahrer (freier Ersatzplatz) oder Stammfahrer (freies Cockpit), Vertrag 2 Saisons zum Marktwert. Er verlässt die Akademie.
- **Verleihen:** mit Superlizenz an ein F1-Team, dessen schwächster Stammfahrer höchstens 4 Punkte besser ist. Bis Saisonende, das Team zahlt 300 000 $, der Junior bleibt in unserer Akademie und kommt zum Saisonwechsel zurück (über 24: frei).
- **Verkaufen:** an eine andere Akademie mit freiem Platz; Ablöse nach deren Schätzung (0,7–1,2 × Marktwert). Er behält seinen Sitz.

Prüfung: `tools/youth_check.tscn` (alle Regeln aus 9–13 und eine ganze Saison).
