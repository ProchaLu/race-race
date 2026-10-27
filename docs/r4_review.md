# R4 – HQ: Review (30.10.2026)

Grundlage: Code (`core/facility_manager.gd`, `ui/components/hq_campus.gd`, `ui/screens/hq_screen.gd`), Spieldesign §7, `docs/hq_screen_design.md` und Bildschirmaufnahmen im Spiel (1600×900 und 1280×720, Deutsch). **Umgesetzt am 30.10.2026** (siehe Abschnitt „Umsetzung“ am Ende); alle Punkte erledigt (zweiter Durchgang mit Kalibrierung am Ende).

## Wie weit ist R4?

R4 laut Roadmap: **Gelände, Gebäude, Bau, Effekte**.

| Teil | Stand | Bewertung |
|---|---|---|
| Gelände | ✅ fester Campus, 15 Bauplätze, Straßen, Rennbetrieb (Autos, Transporter) | sieht schon nach Spiel aus |
| Gebäude | ✅ 15 Gebäude, 75 Grafiken (5 Stufen), Stufen sichtbar verschieden | stark |
| Bau | ✅ Bauen/Ausbauen, Zahlung, Bauzeit, Baustelle sichtbar, Inbox, über den Saisonwechsel | gut, sauber geprüft |
| Effekte | ⚠️ 3 von 15 wirken (Design, Windkanal, Fabrik – über die alten Felder) | größte Lücke |
| Unterhalt, Personal-Bedarf | ❌ | im Spieldesign verlangt |
| KI-Teams bauen | ❌ | der Spieler baut allein → KI fällt zurück |

**Einschätzung:** Optik ~85 %, Spielsysteme ~35 %, gesamt etwa **die Hälfte von R4**.

## Was richtig gut ist
- Der Campus ist die stärkste Grafik im Spiel: man erkennt sofort ein Rennteam-HQ, die Stufen unterscheiden sich wirklich (nicht nur ein Badge).
- Baustelle mit Zaun, Kran, Gerüst/Netz bei Ausbau – sehr verständlich.
- `FacilityManager` trennt Logik von der Oberfläche; veraltete Angebote werden erkannt („stale quote“), Prüf-Skripte decken Bau, Geld, Saisonwechsel und Klick-Treffer ab.
- Klicks treffen die sichtbaren Pixel (Alpha), nicht nur Rechtecke; Tastatur-Auswahl über die Liste.

## 🔴 Sofort beheben (stört das Spielen)
- [x] **Der Knopf „Ausbauen“ ist bei 1600×900 nicht sichtbar** – er liegt unter dem Rand des Inspektors, man muss scrollen. Aktion gehört nach oben oder fest unten in den Inspektor.
- [x] **Fortschrittsbalken „Im Bau“** ist ein unformatierter Godot-`ProgressBar` (graues Kästchen, „9 %“ weit rechts) – sieht kaputt aus. Ersetzen durch `Meter`.
- [x] **12 von 15 Gebäuden kosten Geld ohne Wirkung.** Bis die Wirkung kommt: deutlich kennzeichnen („Wirkung kommt mit R5/R6/R7“) oder Bau sperren – sonst verbrennt man $ für nichts.
- [x] **Preise zu hoch für hohe Stufen:** Windkanal Stufe 4 = $72,8M, Fabrik Stufe 5 = $81M (Budget $180M). Spieldesign: „großer Gebäude-Ausbau ca. $20–60M“. Formel `Basis × Stufe^1,3` an die Tabelle anpassen.

## 🎨 Styling & Ausrichtung
Der HQ-Bildschirm benutzt kaum die gemeinsamen Bausteine – deshalb wirkt er anders als Fahrzeugentwicklung, Fahrer oder Wochenende.

- [x] **Inspektor aus `UICard`s bauen** statt loser Labels: Karte „Gebäude“ (Stufe, Zweck, Bild), Karte „Wirkung“, Karte „Ausbau“. Überschriften `CardTitle`/`SectionLabel` statt `HeadingLabel` – jetzt sind „Aktuelle Wirkung“ und „Auf Stufe 4 ausbauen“ so groß wie der Gebäudename.
- [x] **Kosten/Bauzeit/Fertigstellung als `FactRow`** (Wert rechtsbündig, Zebra) statt Fließtext.
- [x] **Wirkung als Vergleich:** „Windkanal-Kapazität ×0,96 → ×1,08 (+12 %)“ in einer Zeile mit grünem Plus, statt den ganzen Wirkungstext zweimal untereinander. Dazu eine Übersetzung in Spielsprache: „≈ 1 Windkanal-Runde mehr alle 2 Wochen“, „+1 paralleles Projekt“.
- [x] **Bilder:** aktuell und nächste Stufe **nebeneinander**, kleiner, mit „Stufe 3 → Stufe 4“ darunter. Jetzt zwei fast gleiche große Bilder untereinander, die viel Platz fressen.
- [x] **Bestätigung:** der native Godot-`ConfirmationDialog` passt nicht zum Spiel. Eigener Dialog wie „Neues Projekt“ (dunkel, Akzentrahmen, `AccentButton`), oder Bestätigung direkt im Inspektor („Wirklich bauen? $72,8M · fertig 9. Nov“).
- [x] **Titel „Vortex Racing“** ist doppelt (Topbar sagt schon „Hauptquartier“). Stattdessen eine **Statusleiste mit `StatusTile`s**: Gebäude in Betrieb (13/15), Im Bau (Fabrik 9 %, fertig 4. Nov), Unterhalt/Monat, Investiert diese Saison, Wert des HQ / Rang im Feld.
- [x] **Gebäudeliste unten** (15 Knöpfe, 12 px, zentriert) liest sich wie eine Werkzeugleiste. Besser: Liste im Inspektor, wenn nichts ausgewählt ist (Name links, Stufe als 5 Punkte ●●●○○ rechts, Bau-Symbol), oder als ein-/ausklappbare Leiste. Status nicht nur als Text, auch als Symbol/Farbe.
- [x] **Leere Bauplätze:** nur ein kleines „+“ – man weiß nicht, was dort hinkommt. Beim Überfahren Umriss + „Bauplatz: Motorenwerk · $20M“. Gebäudenamen auf dem Campus beim Überfahren als Label (jetzt nur Tooltip), optional Schalter „Namen zeigen“.
- [x] **Farben aus `UIStyle`** statt fester Hex-Werte (`#1e3029`, `#f2a93b`, `#17232b` …) – sonst passen sie nicht mehr, wenn wir das Styling ändern.
- [x] **Campus-Farben:** das Gras ist sehr gesättigt neben der dunklen Pit-Wall-Oberfläche. Etwas entsättigen/dunkler, damit Gebäude und Auswahl hervorstechen. Rahmen um den Campus wie bei `UICard`.
- [x] **Große leere Rasenflächen** im Mittelfeld (zwei Bauplätze nebeneinander) – nach dem Bau gut, im Startzustand wirkt es leer. Etwas Leben (Parkplatz, Lager, Bäume), das beim Bau verschwindet.
- [x] **Stil-Entscheidung nötig:** Doku sagt „Pixel-Art, Nearest-Neighbour“, umgesetzt sind detaillierte Illustrationen mit weichem Skalieren (`LINEAR`, Lanczos) und schräger 3/4-Ansicht der Gebäude auf Draufsicht-Straßen. Sieht gut aus – dann aber die Doku auf „illustrierter Tycoon-Stil“ ändern und diesen Stil festhalten, damit spätere Grafiken (Autos, Personen, Animationen) dazu passen.

## ⚙️ Spielsysteme (fehlend für R4)
- [x] **Wirkung aller 15 Gebäude** (Vorschlag, was sofort an bestehende Systeme andockt):
  - CFD-Zentrum → Kapazität der Abteilung „CFD / Simulation“ (heute rechnet die über Design-Büro + Windkanal)
  - Verbundwerkstoffe → Gewichtsgewinn bei „Gewicht sparen“, Grundmasse neuer Teile
  - Testlabor → Prüfstand-Kapazität + Zuverlässigkeit neuer Teile (heute hängt „rig“ an der Fabrik)
  - Simulator → Streckenwissen / Lernzeit (Spieldesign §3), Setup-Vorbereitung im Training
  - Boxencrew-Training → Boxenstopp-Zeit und Fehlerquote (Wochenend-Sim)
  - Rennzentrale → Strategie-Qualität des Renningenieurs, Wetter-Prognose
  - Mitarbeiter-Einrichtungen → Teamstimmung, Attraktivität beim Anwerben
  - Fahrerleistungszentrum → Fitness, langsamerer Altersabbau
  - Akademie / Scouting → schon als alte Felder vorhanden, Wirkung mit R7
  - Motorenwerk → R5, Marketing & Hospitality → R6 (bis dahin gesperrt/gekennzeichnet)
- [x] **Unterhalt** pro Gebäude und Stufe, monatlich mit den Gehältern abgebucht; im Inspektor „Unterhalt +$0,4M/Monat“.
- [x] **KI-Teams bauen** nach denselben Regeln (Prioritäten nach Budget und Schwächen), sonst gewinnt der Spieler allein durch das HQ.
- [x] **Startwelt:** jedes Team bekommt ein eigenes HQ in `TestWorld` (reiche Teams fast alles, kleine Teams 5–7 Gebäude), statt alles aus der Design-Stufe abzuleiten.
- [x] **Personal-Bedarf** (Spieldesign §7: „braucht zum Teil Personal“): z. B. Windkanal Stufe 4 braucht mehr Aerodynamiker – passt zur Personalstärke der Abteilungen aus R3 (dort steht „Einstellen mit R4/R6“).
- [x] Ein Bauprojekt gleichzeitig ist ok für den Anfang; später 2 Projekte ab einer bestimmten Größe/Budget.

## 🧹 Code & Aufräumen
- [x] **Eine Quelle für Stufen:** jetzt gibt es `team.facilities` **und** die fünf alten Felder (`design_center_level` …), synchron gehalten. R3 sollte direkt `FacilityManager.level(team, &"wind")` lesen, die alten Felder fallen weg.
- [x] **Gebäudedaten doppelt:** Namen und Stufen-Tiers stehen in `FacilityManager.CATALOG` **und** in `hq_campus.gd` `SITES`; die Grafik-Zuordnung hängt an der Reihenfolge von `SITES`. Alles in eine Datei (z. B. `core/facilities.gd` wie `CarParts`), Campus liest nur Position/Fläche.
- [x] **IDs als `StringName`** (`&"wind"`) wie überall sonst (Teile, Abteilungen) statt `String`.
- [x] **Tagesablauf:** `FacilityManager` ist ein eigener Autoload und hängt am Signal `day_passed`; alle anderen Systeme (Entwicklung, Stimmung) laufen über `Season._daily_world_update`. Gleich machen (statische Klasse + Aufruf aus Season) – dann ist die Reihenfolge klar.
- [x] **Leistung:** jede Neuzeichnung baut ein 1600×1000-Bild auf der CPU und skaliert jede Gebäudegrafik neu (Lanczos); bei laufendem Bau wird der Bildschirm jeden Tag neu aufgebaut. Skalierte Grafiken zwischenspeichern, Gebäude als eigene `TextureRect`/`Sprite2D` über dem Gelände statt alles in ein Bild zu malen.
- [x] **Ungenutzte Dateien:** `campus_ground.png`, `campus_ground_v2.png`, `facilities.png` (zusammen ~7 MB) werden nicht mehr geladen; `docs/ui_mockups` ist 44 MB groß. Alte Varianten in einen Archiv-Ordner außerhalb des Projekts oder löschen.
- [x] `docs/hq_screen_design.md` ist ein Verlauf vieler Versionen (neuester Stand oben, Widersprüche: „no gameplay implementation yet“ in Zeile 3). Auf eine aktuelle Beschreibung kürzen, Verlauf in einen Abschnitt „Historie“.
- [x] Doppeltes `tr()` (Wirkungstexte werden in `effects()` und im Bildschirm übersetzt) – harmlos, aber aufräumen.

## Vorschlag Reihenfolge
1. **Sofort-Punkte** (Knopf sichtbar, Balken, Preise, Kennzeichnung ohne Wirkung) – klein, großer Effekt.
2. **Inspektor + Statusleiste im gemeinsamen Stil** (UICard, FactRow, StatusTile, eigener Bestätigungsdialog) – gleich mit dem allgemeinen Styling-Durchgang nach R3.
3. **Code aufräumen** (eine Quelle für Stufen, Daten in einer Datei, StringName, Tagesablauf) – vor den Effekten, sonst wird es doppelt Arbeit.
4. **Effekte der Gebäude**, die an R2/R3 andocken (CFD, Verbundwerkstoffe, Testlabor, Simulator, Boxencrew, Rennzentrale, Mitarbeiter, Fahrerleistung).
5. **Unterhalt + KI baut + Startwelt pro Team.**
6. Danach Grafik-Feinschliff (Stil festhalten, Leben auf dem Campus, Animationen).

## Umsetzung (30.10.2026)
- Neue Datei `core/facilities.gd` (statisch) statt `FacilityManager`-Autoload: Daten, Stufen, Bau, Unterhalt, KI, Startgelände, alle Wirkungen. Die alten Felder `design_center_level` … sind aus `TeamData` entfernt; R3 liest `Facilities`. Alter Code liegt in `../race-race-archive/`.
- Preise: Basis × [1,0 / 1,4 / 2,0 / 2,8 / 3,8] (Stufe 5 Windkanal ≈ $46M statt $93M). Unterhalt 0,8 % des Basispreises je Stufe und Monat, mit den Gehältern abgebucht (Zeile in der Gehalts-Nachricht).
- Motorenwerk (R5), Marketing & Hospitality (R6), Akademie und Scouting (R7) sind bis dahin gesperrt und so gekennzeichnet.
- Personal-Bedarf als **Platz für Personal**: die Kopfzahl der R3-Abteilungen ist durch das zugehörige Gebäude begrenzt.
- KI baut wöchentlich mit Rücklage (6 Monate Gehälter + Unterhalt). Test über eine Saison: alle Teams bauen 4–6 Stufen, kein Budget negativ.
- Bildschirm neu im gemeinsamen Stil (Statusleiste, UICards, FactRows, Vergleich alt → neu mit %, Bilder nebeneinander, Tab „Alle Gebäude“, feste Aktionsleiste mit Bestätigung, Namen beim Überfahren / „Namen zeigen“, Bauplatz mit Preis). Gelände als eigene, leicht entsättigte Ebene; Gebäudeebene nur bei Änderungen neu, skalierte Grafiken im Speicher.
- Stil-Entscheidung festgehalten (`docs/hq_screen_design.md`, oben): illustrierter Tycoon-Stil.
- Ungenutzte Grafiken (`campus_ground.png`, `campus_ground_v2.png`, `facilities.png`) nach `../race-race-archive/assets_hq/` verschoben (nicht gelöscht). `docs/ui_mockups` (44 MB) bleibt, weil die Doku darauf verweist.
- Prüf-Werkzeuge als Szenen (`tools/hq_construction_check.tscn`, `tools/hq_visual_check.tscn`), weil `--script` die Autoloads nicht kennt; beide laufen durch.
- Zusätzlich aus dem Labor: Häkchen werden nach dem besten CFD-Ergebnis vorausgewählt.

## Zweiter Durchgang: Kalibrierung und Rest (30.10.2026)
- **Wirkung Stufe 1 → 5 deutlich:** Abteilungen etwa ×2 (Design 0,8 → 1,6; Windkanal 0,65 → 1,45), parallele Projekte 2 → 6, Prognosefehler im Windkanal ×1,3 → ×0,5, Teilekosten ×1,08 → ×0,80, Wochenend-Werte +5 bzw. +4 je Stufe, Teamstimmung −2 … +6.
- **Preise:** Stufenfaktor 1,0 / 1,5 / 2,3 / 3,4 / 5,0 (Windkanal Stufe 5 = $60M), Bauzeit +35 % je Stufe (Windkanal Stufe 5: 144 Tage), Unterhalt wächst mit Stufe^1,3.
- **Testlauf** (gleiches Team, ganze Saison, alles Stufe 1 gegen alles Stufe 5): 9 gegen 26 neue Teile, −0,10 s gegen −0,24 s, Auto P7 gegen P4, Prognosefehler 23 % gegen 8 %, Boxenstopp 2,66 s gegen 2,24 s, Stimmung 52 gegen 62, Unterhalt $0,4M gegen $3,1M pro Monat.
- **Fehler behoben:** ohne CFD-Zentrum oder Testlabor (Stufe 0) hatte die Abteilung 0 Mitarbeiter – Projekte wären stecken geblieben. Jetzt 45 % Platz in anderen Gebäuden.
- **Zweiter Bautrupp** ab 45 Gebäudestufen insgesamt (auch für die KI).
- **Leben auf dem Gelände:** leere Bauplätze als Lager, Parkplatz oder Garten; Animation (Boxenstopp-Training, Fußgänger, Transporter), abschaltbar.
- Kein Grundstückskauf (Entscheidung 30.10.2026): jedes der 15 Gebäude hat seinen festen Platz.
- Saisonbilanz zeigt das HQ: fertige Gebäudestufen, investiertes Geld, Rang des Geländes.

**R4 abgeschlossen.** Feinabstimmung der Zahlen kommt mit dem Playtest.
