# Finanzmodell, Sponsoren, Besitzer & Ruf (R6)

> Ziel: Geld ist eine Entscheidung mit Folgen. Einnahmen (Preisgeld, Fernsehen, Sponsoren, Merchandising, Besitzer, Investoren) stehen Ausgaben (Gehälter, Abteilungen, Unterhalt, Logistik, Entwicklung, Motor) gegenüber. Sponsoren, Besitzer und Ruf geben dem Spieler echte Entscheidungen.
> Verwandt: Design-Dokument Kapitel 10–13, `docs/car_model.md` (Budget), `docs/engine_model.md` (Motorgebühr, Motoreinheiten).
> **Alle Zahlen sind Startwerte.** Feinabstimmung kommt mit dem Playtest (Entscheidung: nicht jetzt tunen).

---

## 0. Grundprinzipien

1. **Jede Geldbewegung läuft über `Finance.pay()` oder `Finance.receive()`** und landet im Kontobuch (Kategorie je Team und Saison). Kein Budget wird mehr direkt verändert.
2. **Gleiche Regeln für KI und Spieler.** Ausnahmen: Besitzer und Investoren gibt es nur beim Spielerteam.
3. **Kein Geld ohne Grund.** Einnahmen hängen an Leistung oder Verträgen, Ausgaben wachsen mit der Größe des Teams.

---

## 1. Einnahmen und Ausgaben (Startwerte)

| Posten | Wann | Wert (Start) |
|---|---|---|
| Preisgeld | Saisonende, nach WM-Platz (`Season.PRIZE_MONEY_M`) | 140 M $ (P1) … 55 M $ (letzter) |
| TV- und Startgeld | pro Rennen, alle Teams | 1,5 M $ |
| Sponsoren | pro Rennen (Vertrag), Handgeld bei Unterschrift, Bonus am Saisonende | Abschnitt 3 |
| Merchandising | pro Rennen: Fans × 15 000 $ | Fans 50–100 → 0,75–1,5 M $ |
| Zuschuss des Besitzers | auf Anfrage | 10 / 25 / 50 M $ |
| Investor | Summe bei Annahme (Abschnitt 5) | 20–50 M $ × Ruf/60 |
| Logistik | pro Rennen | −2,5 M $ |
| Gehälter | monatlich (Fahrer und Personal) | Vertragssumme / 12 |
| Abteilungspersonal | monatlich: Kopfzahl × 100 000 $ / 12 | Topteam ca. 34 M $/Jahr |
| HQ-Unterhalt | monatlich | Gebäudestufen (`Facilities`) |
| Motorgebühr | monatlich | Motorvertrag / 12 |
| Entwicklung, Motor, HQ-Bau, Handgelder, Abfindungen, Ablösen | beim Auslösen | wie bisher |
| Investoren-Anteil | Saisonende | Anteil × Preisgeld |

---

## 2. Kontobuch, Verlauf und Prognose

- **Kontobuch** (`GameState.cash_book`): Team → Kategorie → Summe dieser Saison (Einnahmen positiv, Kosten negativ). Am Saisonwechsel geleert; der Saisonrückblick bekommt eine Kopie (`review.cash`).
- **Verlauf** (`GameState.budget_history`): Team → [[Jahr, Tag, Budget]] nach jedem Monat und jedem Rennen. Die Kurve im Finanzen-Bildschirm liest die Punkte des laufenden Jahres.
- **Prognose** (`Finance.forecast`): verbleibende Rennen × (TV + Sponsoren + Merchandising), Preisgeld der aktuellen Platzierung, Boni bei der aktuellen Platzierung; verbleibende Monate × (Gehälter + Abteilungen + Unterhalt + Motorgebühr), Logistik pro Rennen.

---

## 3. Sponsoren (R6b, `core/sponsors.gd`)

- **Firmen:** `Sponsors.CATALOG`, 15 erfundene Firmen in drei Stufen. Werbeflächen am Auto: Titel 1, Haupt 2, Neben 3.
- **Angebote:** jeden Monat. Anzahl offener Angebote = 2 + Gastronomie-/Marketinggebäude / 2 + (Netzwerk des Kommerziellen Leiters − 50) / 25, begrenzt auf 1–5. Nur Firmen, deren Mindestruf das Team erreicht und deren Stufe eine freie Fläche hat. Ein Angebot gilt 60 Tage.
- **Vertrag:** Zahlung pro Rennen; Handgeld bei Unterschrift (2 × Zahlung); Bonus am Saisonende, wenn die Platzierung ≤ Ziel ist (4 × Zahlung). Ziel: Titel P5, Haupt P8, Neben P10, jeweils ±1.
- **Zufriedenheit** (Start 70): Bonus erreicht +15, verfehlt −25. Läuft der Vertrag aus und liegt die Zufriedenheit bei ≥ 50, kommt ein neues Angebot über 2 Jahre, sonst endet er. Sinkt sie während der Laufzeit auf ≤ 10, kündigt der Sponsor.
- **Kommerzieller Leiter:** Verhandlungsgeschick skaliert die Zahlungen (Faktor 0,8 ohne Leiter bis 1,2 bei 100). Netzwerk erhöht die Zahl der Angebote.
- **KI-Teams** unterschreiben die besten Angebote mit freier Fläche automatisch.
- **Nicht umgesetzt:** Wünsche der Sponsoren (z. B. Fahrer aus einem Land).

---

## 4. Besitzer (R6c, `core/owners.gd`)

- **Besitzer des Spielerteams:** Persönlichkeit (geduldig, ungeduldig, ehrgeizig, sparsam) und Vertrauen 0–100 (Start 60).
- **Saisonziel:** Ruf-Rang des Teams, verschoben nach Persönlichkeit (ehrgeizig −1, geduldig und sparsam +1, ungeduldig 0). Wird am Saisonende bewertet.
- **Langfristiges Ziel:** der Konstrukteurstitel innerhalb von 5 Jahren. Erreicht +15 Vertrauen, verfehlt −10; danach läuft eine neue Frist.
- **Vertrauen am Saisonende:** Ziel erreicht +8; um 1–2 Plätze verfehlt −4; weiter weg −10. Verluste werden mit dem Faktor der Persönlichkeit multipliziert (ungeduldig 1,3, geduldig 0,7). Sparsame Besitzer ziehen −5 ab, wenn die Saison im Minus endet.
- **Geld bitten:** einmal pro Saison, in drei Stufen (10 / 25 / 50 M $). Chance = Vertrauen × Faktor × (1 − Betrag / 100 M), begrenzt auf 5–90 %. Eine Ablehnung kostet 3 Vertrauen.
- **Warnungen:** Vertrauen ≤ 25: „verliert die Geduld“. Vertrauen ≤ 10: „letzte Warnung“.
- **Entlassung** (R8b): nach der letzten Warnung oder bei massivem Versagen, danach Jobangebote – siehe `docs/career_model.md`.

## 5. Investoren (R6c)

- **Angebot:** monatlich mit 10 % Chance, solange der Ruf ≥ 50 ist und noch kein Investor (oder Angebot) besteht. Summe 20–50 M $ × Ruf/60, Anteil 10–20 % des Preisgelds, Bedingung: das Saisonziel des Besitzers, Laufzeit 2–3 Jahre. Das Angebot gilt 45 Tage.
- **Annahme:** die Summe kommt sofort. Jedes Saisonende geht der Anteil am Preisgeld an den Investor.
- **Verfehlte Bedingung:** der Investor steigt aus, das Vertrauen des Besitzers sinkt um 5.

## 6. Ruf, Fans und Merchandising (R6d, `core/team_reputation.gd`)

- **Teamruf** (0–100): Saisonschritt = Mitte − Platz, auf ±4 begrenzt (Mitte = (Teams + 1) / 2). Dazu kommt ein Bonus: Gastronomie-/Marketinggebäude (Stufe / 3) und ein Netzwerk-Kommerzieller-Leiter mit Markenbildung ≥ 75 (+1).
- **Fans** (0–100): gleicher Schritt; +1, wenn ein Fahrer des Teams die Eigenschaft „Medienliebling“ hat.
- **Ruf des Teamchefs** (`GameState.career`, Start 50): folgt dem Saisonschritt des Spielerteams und entscheidet über Jobangebote (`docs/career_model.md`).
- **Merchandising:** Fans × 15 000 $ pro Rennen.

---

## 7. Bildschirme

- **Finanzen** (`ui/screens/finance_screen.gd`): Kennzahlen, Verlauf des Kontostands in der Saison, Prognose zum Saisonende, Einnahmen und Ausgaben nach Kategorie.
- **Sponsoren** (`ui/screens/sponsor_screen.gd`): Verträge, Werbeflächen, Angebote unterschreiben oder ablehnen.
- **Besitzer** (`ui/screens/owner_screen.gd`): Vertrauen, Ziele, Geld bitten, Investor, Ruf und Fans.
- **Gastronomie / Marketing** ist entsperrt (vorher „R6“ gesperrt).
- **Saisonrückblick:** Ziel des Besitzers mit Vertrauen, Saldo der Saison.

## 8. Prüfung

- `tools/finance_check` – Buchung, Rennabrechnung, Prognose, eine ganze Saison (Geld aller Teams).
- `tools/sponsor_check` – Angebote, Flächen, Unterschrift, Zahlungen, Boni, Zufriedenheit, Verlängerung, Kündigung, Ablauf.
- `tools/owner_check` – Geldbitte, Vertrauen, langfristiges Ziel, Investor, Ruf, eine ganze Saison.
- `tools/screen_shot` – Bildschirm als PNG (braucht ein Fenster, also ohne `--headless`):
  `SCREEN=finances SHOT=/pfad/finances.png godot --path . res://tools/screen_shot.tscn`

## 9. Offen

- ~~Entlassung und Jobangebote~~ – umgesetzt in R8b (`docs/career_model.md`).
- **Abteilungspersonal einstellen und entlassen:** heute ist die Kopfzahl aus dem Budget abgeleitet und wird monatlich bezahlt.
- **Kalibrierung:** die Zahlen in Abschnitt 1 sind Startwerte. Im Playtest prüfen, ob Mittelfeld und Spitze etwa ausgeglichen sind.
- **Medien und Interviews** (Design 13) – eigene Runde.
- **Sektornamen der Sponsoren** sind noch nicht übersetzt.
