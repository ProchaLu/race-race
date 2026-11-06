# Karriere des Teamchefs und Spielstart – Modell (R8)

Code: `core/career.gd` (Zustand in `GameState.career`), Entlassungsregel in `core/owners.gd`, Bildschirm `ui/screens/career_screen.gd`. Prüfung: `godot --headless --path . res://tools/career_check.tscn`.

## 1. Ruf des Teamchefs
- 0–100, Start 50. Gehört dem Spieler, nicht dem Team (bleibt beim Wechsel).
- Folgt am Saisonende dem Saisonschritt des eigenen Teams (wie der Teamruf, ±4).
- Eine Entlassung kostet 10 Punkte, bevor die Angebote kommen.

## 2. Entlassung (nachsichtig, v1)
Am Saisonende nach dem Urteil des Besitzers. Der Spieler wird entlassen, wenn:
- er im Vorjahr die **letzte Warnung** bekam (Vertrauen ≤ 10 am Saisonende), das Vertrauen noch immer ≤ 10 ist und das Saisonziel wieder verfehlt wurde, **oder**
- das Saisonziel um **6 oder mehr Plätze** verfehlt wurde und das Vertrauen unter 30 liegt (massives Versagen).

Keine Entlassung während der Saison (später, mit den Schwierigkeitsstufen).

## 3. Jobangebote
- **Nach einer Entlassung:** bis zu 3 Angebote von Teams, die ihr eigenes Ziel verfehlt haben (Platz schlechter als ihr Ruf-Rang) und deren Anspruch der Ruf des Teamchefs erfüllt (Teamruf − 15). Beste Teams zuerst. Findet sich keins, bietet das Team mit dem niedrigsten Ruf immer einen Job an.
- **Ohne Entlassung:** nur ab Ruf 55, nur von Teams mit höherem Ruf als das eigene, je Team 50 % Chance, höchstens 2. Sie gelten bis zum 31. Dezember.
- Jedes Angebot nennt den neuen Besitzer (Name, Persönlichkeit) und das Saisonziel (Ruf-Rang + Verschiebung der Persönlichkeit).

## 4. Zeit wartet
Nach einer Entlassung läuft keine Zeit weiter, bis ein Angebot angenommen ist („Job wählen“ in der oberen Leiste führt zum Karriere-Bildschirm). Das letzte Angebot kann nicht abgelehnt werden.

## 5. Wechsel
- `player_team_id` wechselt; das alte Team wird von der KI geführt (KI-Teams haben keinen Besitzer).
- Das neue Team bekommt einen Besitzer mit Vertrauen 60 und den Zielen aus dem Angebot.
- Es enden: offene Verhandlungen, vereinbarte, noch nicht unterschriebene Verträge, Versprechen, Scouting-Aufträge. Auto- und Motorentwicklung sind wieder ans Personal delegiert.
- Bleibt: Wissen über Personen, Shortlist, Ruf des Teamchefs, Karriereverlauf.
- Der Saisonrückblick merkt sich das Team der Saison (`team_id`).

## 6. Spielstart (R8a, `ui/menu/start_menu.gd`, `TestWorld.new_game()`)
- Das Spiel startet mit dem **Startmenü**: Neues Spiel, Weiter (gesperrt bis Speichern/Laden), Beenden, Sprache.
- **Echter Saisonstart:** 1. Januar 2026, noch kein Rennen gefahren, erstes Rennen am 2. März.
- **Team übernehmen:** eines der elf Teams; Liste nach Ruf mit Einordnung (Titelkandidat / Mittelfeld / Hinterbänkler), Budget, Auto, Motor, Fahrer, Erwartung des Besitzers. Besitzer mit zufälligem Namen und zufälliger Persönlichkeit; das Team behält seine Sponsoren.
- Die Prüfwerkzeuge und `tools/screen_shot` (ohne `NEW_GAME`/`MENU`) nutzen weiter die Entwicklungswelt mitten in der Saison (`TestWorld.build()`, `main.skip_menu`).

## 7. Eigenes Team gründen (R8a, `core/team_founding.gd`)
- Das eigene Team kommt als **12. Team** dazu: **24 Autos**. Preisgeld für Platz 12: 53 M $.
- Eingaben: Name (mind. 3 Buchstaben, nicht vergeben), Kürzel (3 Buchstaben, nicht vergeben), Farbe (10 zur Wahl), Motorenlieferant mit freiem Platz (Kundenmotor, 2 Jahre, Jahrespreis des Herstellers; Meridian ist voll).
- Startwerte: Budget 140 M $, Teamruf 30, Fans 15, Autowertung 48, Campus der Stufe 1 (einfache Gebäude), Personal um 45 in allen 16 Schlüsselpositionen.
- Fahrer: der Sportdirektor verpflichtet die zwei besten freien Fahrer mit Superlizenz für zwei Saisons (gleichberechtigt, Marktwert als Gehalt).
- Besitzer: ein **geduldiger Geldgeber**. Der Spieler ist Mitgründer und **kann nicht entlassen werden** (`owner.founder`); Vertrauen wirkt weiter auf Geldbitten. Jobangebote anderer Teams kommen trotzdem; wer geht, überlässt das Team der KI.

## 8. Offen
- Entlassung während der Saison und strengere Besitzer (Schwierigkeitsstufen).
- Angebote während der Saison; Abwerbeversuche durch Spitzenteams.
- Akademie des alten Teams: die Fahrer bleiben dort, KI-Akademien gibt es noch nicht.
- Gehalt des Teamchefs und Vertragslaufzeit des Teamchefs.
- Karriereverlauf mit Erfolgen pro Team (Titel, Platzierungen).
- Gründung: Fahrer selbst wählen, Startkapital/Geldgeber wählen, eigener Name des Teamchefs, Herkunftsland/Standort.
- Prüfung: `godot --headless --path . res://tools/new_game_check.tscn` (Übernahme am 1. Januar, Gründung mit 12 Teams und 24 Autos, Gründerregel, eine ganze Saison).
