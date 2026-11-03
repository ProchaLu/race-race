# Nachwuchs, Akademie & Scouting (R7)

> Ziel: Die Zukunft des Teams entsteht im Nachwuchs. Jedes Jahr kommt ein Jahrgang neuer Talente, sie gehen durch F3 und F2 in den F1-Markt, das eigene Team kann sie in der Akademie ausbilden und platzieren, und der Chefscout zeigt, wer wirklich etwas taugt – mit Unsicherheit.
> Verwandt: Design-Dokument Kapitel 3.9 (Superlizenz), 4 (Jugend & Scouting), `docs/finance_model.md` (Kosten), `docs/hq_screen_design.md` (Gebäude).
> **Alle Zahlen sind Startwerte.** Feinabstimmung kommt mit dem Playtest.

---

## 0. Grundprinzipien

1. **Eine Pyramide mit festen Stufen.** Newgens → Apex F3 → Apex F2 → F1 (nur mit Superlizenz). Jede Stufe hat feste Plätze, und Plätze werden jedes Jahr neu vergeben.
2. **Nachwuchsserien laufen im Hintergrund.** Keine Budgets, keine Teams mit Personal, keine Autoentwicklung. Ergebnisse entstehen aus Fähigkeit, Teamstärke und Zufall.
3. **Man sieht nicht alles.** Gescoutete Werte sind Bereiche, und ein schwacher Scout kann ganze Bereiche verschieben. Exakte Werte gibt es nur für eigene Leute (Vertrag oder Akademie).
4. **Gleiche Regeln für KI und Spieler**, außer bei Akademie und Scouting: Die KI nutzt beides noch nicht (siehe Abschnitt 8).

---

## 1. Die Pyramide

| Stufe | Teams | Plätze | Alter | Rein | Raus |
|---|---|---|---|---|---|
| Newgens (Pool, ohne Team) | – | 24 neue pro Jahr | 15–17 | Jahrgang | Akademie, Platz in F3/F2 oder zu alt |
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
- Ein Juniorrennen wird nicht einzeln gezeigt. Die Ergebnisse stehen im Akademie-Bildschirm (Top fünf) und in der Saisonmeldung.

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

- **Plätze** = Stufe des Gebäudes (0 bis 5). Stufe 0 heißt keine Akademie.
- **Aufnahme:** nur Pool-Junioren bis 22 Jahre, die keinem Team gehören. **Einmalgebühr 250 000 $**, danach **40 000 $ je Fahrer und Monat**.
- **Platzierung** auf einen freien Juniorensitz, dessen Alter passt. **Gebühr je Saison:** F3 300 000 $, F2 900 000 $. Sie wird bei jeder Platzierung und beim Saisonwechsel fällig.
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

- **KI:** Keine KI-Akademie und kein KI-Scouting. Die KI schickt keine Junioren in die Akademie. (`Facilities.AI_WEIGHT` kennt die beiden Gebäude nicht.)
- **Personal scouten** (Design 4.3, „auch Personal kann gescoutet werden“) fehlt.
- **Reserve- und Testfahrer aus der Akademie** (Design 4.2): nur der FP1-Hook ist da, kein fester Reserve-Platz.
- **Kontakte:** Platzierung über Netzwerk ohne Gebühr (Design 4.3, „Network / Region“) fehlt.
- **Lizenzverfall** nach drei Jahren: vereinfacht, siehe Abschnitt 3.
- **Speichern und Laden:** Der Juniorenzustand (`youth_teams`, `youth_standings`, `scout_assignments`, `scout_bias`, `next_scout_id`) muss beim Speichern erfasst werden, sobald Speichern kommt.
- **Juniorentabellen** nur im Akademie-Bildschirm, nicht im Tabellen-Bildschirm.
- **Playtest:** Stärke der Newgens, Lernrate, Akademiekosten und Ausfallrate der Juniorenrennen sind Startwerte.
- **Abgang und Entlassung** gehören zu R8.
