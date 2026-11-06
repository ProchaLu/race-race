# Backlog – Bugs, Feinschliff, offene Punkte

Regel: **Kaputtes oder Störendes sofort beheben.** Feinschliff wird gesammelt und am Ende jeder Runde abgearbeitet. Erledigtes wird abgehakt und bleibt als Verlauf stehen.

## 📍 Stand (03.11.2026)
**R3 komplett (Auto & Entwicklung):** 13 Teile mit Versionen, Masse, Zuverlässigkeit; Autowerte daraus, Gewicht, Kühlung (Renningenieur wählt Öffnungen), Bremsleistung, Traktion, Defekte pro Teil. Entwicklung mit 5 Abteilungen (Design, CFD, Windkanal, Prüfstände, Fabrik; Personalstärke aus dem Budget, Schlüsselpersonen, Gebäudestufen), parallele Projekte, Kosten, Prognose vs. Realität. Teile pro Auto, Stückzahlen und Ersatzteile, Unfälle zerstören Teile, Bremsen als Verbrauchsteil, Notfertigung, Wochenend-Block „Teile“, Training „Neue Teile testen“. Nächstjahresauto, Saisonwechsel mit Nächstjahres-Entwicklung. KI entwickelt nach denselben Regeln.
**Entwicklungslabor umgesetzt:** alte Version als Basis → Ideen → CFD (grob, mit ±) → Windkanal/Prüfstand (Kombinieren, Verfeinern) → Freigeben/Verwerfen → Detailkonstruktion → Werkzeuge → Fertigung → Qualität → Direktvergleich auf der Strecke, „Zurück zur alten Version“. Entscheidungen an Meilensteinen (Inbox + Werkstatt-Spalte „Deine Entscheidung“), „Aero-/Chassis-Chef entscheiden lassen“; delegiert/KI automatisch. Details: `docs/car_model.md` 3a.
**R4 komplett (HQ):** 15 Gebäude mit 5 Stufen auf festem Gelände, Bau mit Kosten/Bauzeit/Unterhalt, bis zu zwei Bautrupps, Wirkung auf Entwicklung, Wochenende und Stimmung (Stufe 1 gegen 5 deutlich), KI baut, Saisonbilanz. Details: `docs/hq_screen_design.md`, `docs/r4_review.md`.
**R5 komplett (Motor):** 4 erfundene Hersteller, Power Unit mit 5 Komponenten → 5 Motorwerte in der Simulation (Leistung, Sprit, Defekte, Gewicht, Traktion/Reifen/Regen), Kunden-/Lizenz-/Werksmotor, Specs mit Verzögerung für Kunden, Motoreinheiten mit Laufleistung (4 pro Fahrer, weitere kosten), Motormodi, 4 neue Entscheidungen (Motortemperatur, ERS-Fehler, Sprit knapp, „Motor klingt nicht gut“), Verträge und Angebote, Motoren-Labor mit Dauerlauf, Power-Unit-Programm, Kunden beliefern. Details: `docs/engine_model.md`.
**R6 Geld & Macht komplett (Stand 28.10.2026):** Kontobuch mit allen Geldbewegungen, Einnahmen pro Rennen (TV, Sponsoren, Merchandising), Abteilungspersonal und Logistik als Kosten, Finanzen-Bildschirm mit Verlauf und Prognose. 15 Sponsoren mit Werbeflächen, Angeboten, Bonus und Zufriedenheit; Gastronomie/Marketing entsperrt. Besitzer mit Persönlichkeit, Saisonziel, langfristigem Titelziel, Vertrauen, Geld-Bitten und Investoren; Teamruf, Fans und Ruf des Teamchefs. Details: `docs/finance_model.md`.
**R7 Nachwuchs komplett (29.10.2026):** Apex F3 und F2 mit je zehn Teams und zwei Plätzen, 24 Newgens pro Jahr, Juniorenrennen im Hintergrund, Superlizenz aus den Juniorenergebnissen. Akademie mit Plätzen nach Gebäudestufe, Aufnahme, Platzierung in Juniorensitzen, Gebühren und Winterentwicklung. Scouting mit Aufträgen (Serie, Region, Einzelner), Wissen je Woche, Fehlgriffen schwacher Scouts und Empfehlungen; Akademie- und Scouting-Bildschirm. Details: `docs/youth_model.md`.
**R8b Karriere komplett (03.11.2026):** Ruf des Teamchefs gehört dem Spieler, Entlassung am Saisonende (nach letzter Warnung oder bei massivem Versagen), Jobangebote von Teams, die ihre Ziele verfehlt haben, Angebote besserer Teams bei hohem Ruf, Zeit wartet nach der Entlassung, Teamwechsel mit neuem Besitzer, Karriere-Bildschirm. Details: `docs/career_model.md`.
**R8a Spielstart & eigenes Team komplett (03.11.2026):** Startmenü (Neues Spiel, Sprache), echter Start am 1. Januar ohne gefahrene Rennen, Team übernehmen (elf Teams mit Einordnung) oder eigenes Team gründen (Name, Kürzel, Farbe, Kundenmotor) als 12. Team mit 24 Autos, Gründer kann nicht entlassen werden. Details: `docs/career_model.md` 6–7.
**Grafik Auto & Motor überarbeitet (06.11.2026):** Auto von oben als technische Illustration (weiche Formen, Reifen, Schatten, Cockpit mit Halo und Helm in Teamfarbe, Flügelklappen, Diffusor, Kühleröffnungen, Hover), Teile-Symbole daraus erzeugt (`tools/part_icons.tscn`); Power Unit als Zeichnung (V6 mit Zylinderbänken, Turbine/Verdichter, Motor-Generator, Batterie, Steuergerät, Leitungen und Kabel).
**Nachwuchs überarbeitet (06.11.2026):** Sitz kaufen (auch während der Saison, ersetzt den schwächeren Nicht-Akademiefahrer), Rennpraxis in F3/F2 und Ergebnisse zählen für die Entwicklung, Junioren mit Sitz verpflichten, Rundenbericht der Akademie und Tabellenplatz/letztes Rennen im Akademie-Bildschirm, Juniorenliste mit Filter (frei/F3/F2), Scouten direkt aus der Liste, „Alle gescoutet“ statt „0 zu scouten“. Details: `docs/youth_model.md` 2a, 4.
**Nachwuchs ausgebaut (06.11.2026):** Kart als verborgene Stufe mit drei Regionalserien, Wunderkinder und Spätzünder, Scout-Netzwerk (Scouts einstellen), Regionsreisen entdecken Kartkinder, Rennbesuche, ausführliche Berichte, Beobachtungsliste; KI-Akademien, Angebote mit Laufzeit/Versprechen/Handgeld und Interesse, rivalisierende Akademien, Ausstiegsklausel, Abwerben, Verkauf; Trainingsschwerpunkt, Mentor, Nachwuchstest, Stimmung; Juniorenprofil, Juniorentabellen, Nachrichten; Befördern, Verleihen. Akademieplätze 2–8, höchstens 2 F3 + 2 F2. Details: `docs/youth_model.md` 9–13.
**Nächster Schritt:** R9 Regulierung laut Roadmap – vorher mit dem Nutzer abstimmen (Alternativen: Playtest/Feinabstimmung, Speichern/Laden für „Weiter“ im Startmenü). Offen für später: Playtest und Feinabstimmung R3–R7 (Geldwerte: `docs/finance_model.md` 1, Nachwuchs: `docs/youth_model.md` 6), Styling, R3e (`docs/car_model.md` 17).

## Nachwuchs-Ausbau (Y1–Y5) ✅ (06.11.2026)
- [x] Sitzlimit (2 F3 + 2 F2), Akademieplätze nach Stufe 2/3/4/6/8
- [x] Y1 Kart-Ebene, Wunderkinder/Spätzünder, Scout-Netzwerk, Regionsreise mit Entdeckung, Rennbesuch, Berichte, Beobachtungsliste
- [x] Y2 KI-Akademien, Angebote mit Interesse und Rivalen, Akademievertrag mit Ausstiegsklausel, Abwerben, Versprechen
- [x] Y3 Trainingsschwerpunkt, Mentor, Nachwuchstest, Stimmung
- [x] Y4 Juniorenprofil, Juniorentabellen im Tabellen-Bildschirm, Nachrichten (Fahrerlager-Gespräch, Rundenbericht)
- [x] Y5 Befördern, Verleihen, Verkaufen
- [ ] Playtest: Interesse-Schwelle (60), Häufigkeit der KI-Verpflichtungen und Abwerbeangebote, Marktwerte, Anzahl der Entdeckungen
- [ ] KI baut Akademie und Scouting-Büro aus (`Facilities.AI_WEIGHT`)
- [ ] Rückkaufoption beim Verkauf, Leihgebühr verhandeln
- [ ] Mehrere Versprechen (z. B. Nachwuchstest), Gespräche mit Junioren
- [ ] Juniorenzustand beim Speichern (discovered, junior_offers, junior_hype, neue Fahrerfelder)

## R8 — Eigenes Team & Karriere ✅ abgeschlossen (03.11.2026)
- [x] R8b Karriere: Entlassung, Jobangebote (nach Entlassung und bei hohem Ruf), Zeit wartet, Teamwechsel, Karriere-Bildschirm, Saisonrückblick merkt sich das Team; Prüfung `tools/career_check.tscn` (Regel, Angebote, Wechsel, eine echte Saison mit Entlassung und neuem Team); owner/finance/sponsor/youth grün
- [x] R8a Startmenü mit echtem Saisonstart (1. Januar), Team übernehmen oder gründen (12. Team, 24 Autos), Gründer nicht entlassbar; Prüfung `tools/new_game_check.tscn`; Preisgeld Platz 12 ergänzt (Absturz im Tabellen-Bildschirm bei 12 Teams behoben)
- [ ] Gründung: Fahrer selbst wählen, Startkapital/Geldgeber wählen, Name des Teamchefs, Standort
- [ ] „Weiter“ im Startmenü (kommt mit Speichern/Laden); Zurück ins Hauptmenü aus dem Spiel
- [ ] Startmenü-Styling (Hintergrundbild, Logo) – zusammen mit dem Styling-Durchgang
- [ ] Playtest: Startwerte des gegründeten Teams (Budget 140 M, Auto 48) und Erwartung P12
- [ ] Entlassung während der Saison, strengere Besitzer (Schwierigkeitsstufen)
- [ ] Angebote während der Saison, Abwerbung durch Spitzenteams
- [ ] Akademie und Scouting des alten Teams nach einem Wechsel (KI-Akademien fehlen)
- [ ] Gehalt und Vertrag des Teamchefs
- [ ] Karriereverlauf mit Erfolgen pro Team
- [ ] Karrierezustand beim Speichern erfassen (zusammen mit Speichern/Laden)

## R7 — Nachwuchs ✅ abgeschlossen (29.10.2026)
Modell und Startwerte: `docs/youth_model.md`.
- [x] R7a Nachwuchspyramide: 10 F3- und 10 F2-Teams mit je zwei Plätzen, Newgens-Jahrgang, Saisonwechsel mit Altersabgang und Neubesetzung, Juniorenrennen nach jeder F1-Runde, Saisonmeldung
- [x] R7b Superlizenz: Punkte aus F2 (40/30/20/10/5) und F3 (5/3/1), 40 Punkte in drei Saisons, F1-Markt nur mit Lizenz
- [x] R7c Akademie: Plätze nach Gebäudestufe, Aufnahme (250 000 $ und 40 000 $ im Monat), Platzierung mit Saisongebühr, Zurückholen, Freigeben, Winterentwicklung über Akademieleiter, Akademie-Bildschirm mit Top-5-Tabellen
- [x] R7d Scouting: Büro mit Stufe als Auftragsplätze, Aufträge für Serie, Region und Einzelnen, Wissen je Woche, Fehlgriffe (verschobener Bereich), Berichte mit Empfehlung, Scouting-Bildschirm
- [x] Prüfung: `tools/youth_check.tscn` (Teams, Saisonwechsel, Akademie, Scouting, Lizenz, eine ganze Saison über den echten Saisonwechsel, deutsche Texte); bestehende Prüfungen finance/owner/sponsor/hq grün
- [ ] Personal scouten (Design 4.3)
- [ ] Reserve- und Testfahrer aus der Akademie mit festem Platz (Design 4.2); bisher nur FP1
- [ ] Platzierung über Kontakte ohne Gebühr (Netzwerk, Design 4.3)
- [ ] KI-Akademien und KI-Scouting (Gebäude sind für die KI noch nicht gewichtet)
- [ ] Lizenzverfall nach drei Jahren (jetzt einmal erreicht, bleibt sie)
- [ ] Juniorenzustand beim Speichern erfassen (zusammen mit Speichern/Laden)
- [ ] Playtest: Stärke der Newgens, Lernrate, Akademiekosten, Ausfallrate der Juniorenrennen
- [ ] Juniorentabellen auch im Tabellen-Bildschirm

## R6 — Geld & Macht ✅ abgeschlossen (28.10.2026)
Modell und Startwerte: `docs/finance_model.md`.
- [x] R6a Finanzen: Kontobuch (`Finance.pay/receive`), Einnahmen und Kosten pro Rennen, Abteilungspersonal monatlich, Verlauf, Prognose, Finanzen-Bildschirm
- [x] R6b Sponsoren: 15 erfundene Firmen, Werbeflächen je Stufe, monatliche Angebote (Gastronomie und kommerzieller Leiter wirken), Handgeld, Zahlung pro Rennen, Bonus am Saisonende, Zufriedenheit, Verlängerung, Kündigung; Gastronomie/Marketing entsperrt
- [x] R6c Besitzer & Investoren: Persönlichkeit, Saisonziel, langfristiges Titelziel (5 Jahre), Vertrauen, Geld bitten (einmal pro Saison), Investor mit Anteil am Preisgeld, Besitzer-Ziel im Saisonrückblick
- [x] R6d Ruf & Fans: Teamruf und Fans nach Platzierung, Merchandising pro Rennen, Ruf des Teamchefs (für R8)
- [x] Entlassung durch den Besitzer und Jobangebote – in R8b umgesetzt
- [ ] Kalibrierung der Geldwerte im Playtest: AI-Teams wachsen über eine Saison noch (Spitze etwa +100 M, Schluss etwa +30 M), vor allem weil KI-Teams wenig in die Entwicklung investieren
- [ ] Abteilungspersonal einstellen und entlassen (heute aus dem Budget abgeleitet, monatlich bezahlt)
- [ ] Medien und Interviews (Design 13) – eigene Runde
- [ ] Sponsorwünsche (z. B. Fahrer aus einem Land)
- [ ] Sektornamen der Sponsoren übersetzen

## R5 — Motor ✅ abgeschlossen (31.10.2026)
- [x] Hersteller, Komponenten, Specs, Verträge; Motorwerte in der Simulation (R5a)
- [x] Einheiten & Laufleistung, Wochenend-Block „Motor“, Motor-Modi, Schlüsselmomente (R5b)
- [x] Hersteller-Entwicklung (KI), Angebote & Verträge, Saisonwechsel (R5c)
- [x] Motoren-Labor, Motorenwerk frei, Power-Unit-Programm, Kunden beliefern, Saisonbilanz (R5d)
- [ ] Später R9: Startplatzstrafen für zusätzliche Einheiten, Entwicklungseinfrierung/Token
- [ ] Playtest: Lebensdauer, Preise, Spec-Größe, Ausfallraten feinstimmen
- [ ] Motorgrafik (PU-Diagramm ist ein Platzhalter aus Blöcken)

## R4 — HQ ✅ abgeschlossen (30.10.2026)
**Review 30.10.2026:** Stand, Sofort-Punkte, Styling, fehlende Systeme und Aufräumen in `docs/r4_review.md` (Checkliste, Reihenfolge am Ende).
- [x] Straßenstil vereinheitlicht: ein zusammenhängender Asphalt-/Bordstein-Layer, keine zur Laufzeit darüber gemalten Wege, Straßenstücke oder Zebrastreifen. Gebäudemaßstab pro Familie begrenzt; alle 75 Varianten auf Grundstücks- und Straßenfreiraum geprüft. Aktueller Layer: `campus_ground_v3.png`.
- [x] Campus-Verbindungen bereinigt: eingebrannte Sackgassen/Stummel aus dem Gelände entfernt, Gebäudeeingänge an tatsächlichen Ankern angeschlossen, unterer Gehweg zum Tor und befahrbare Park-/Lieferzufahrt ergänzt.
- [x] Baustellen deutlich sichtbar: umzäunte Flächen mit Fundament/Baufortschritt für Neubauten, Gerüst/transparentes Schutznetz bei Ausbauten, Kran, Material und Baustellenhütte; Statusbanner mit Prozentanzeige. Gesamte Baustelle anklickbar, Entfernung bei Fertigstellung geprüft.
- [x] **R4b – Auswahl & Bau:** Gebäude und freie Standorte anklickbar, Tastatur-Auswahl über Gebäudeliste, Informationspanel mit Zweck/Stufe/Bildern/Effekten/Kosten/Bauzeit, bestätigte Bau- und Ausbauaufträge, ein laufendes Bauprojekt pro Team.
- [x] Eigenständiger FacilityManager und gespeicherter Zustand in TeamData: einmalig übernommene Startgebäude, Zahlung bei Baubeginn, täglicher Fortschritt auch über den Saisonwechsel, Inbox bei Abschluss und neue Gebäudegrafik. Bestehende Design-/Windkanal-/Fabrikstufen bleiben mit R3 synchron.
- [x] Wirkung für 11 Gebäude (R3-Kapazitäten, Wochenende über TeamOps, Teamstimmung), 4 bis R5/R6/R7 gesperrt; Unterhalt; KI baut; Startgelände pro Team; Platz für Personal; Bildschirm im gemeinsamen Stil (Review `docs/r4_review.md`, umgesetzt 30.10.2026)
- [x] Baupreise, Bauzeiten, Unterhalt und Wirkungen kalibriert – Stufe 1 gegen 5 deutlich (Testlauf in `docs/hq_screen_design.md`); Feinschliff im Playtest
- [x] Leben auf leeren Bauplätzen (Lager, Parkplatz, Garten) und Animationen (Boxencrew, Fußgänger, Transporter), abschaltbar. Später: echte Grafiken im Tycoon-Stil statt gezeichneter Platzhalter
- [x] Zweiter Bautrupp ab 45 Gebäudestufen
- [x] Saisonbilanz mit HQ (fertige Stufen, investiert, Rang des Geländes). Kein Grundstückskauf – jedes Gebäude hat seinen festen Platz (Entscheidung 30.10.2026)
- [x] **R4a – visuelle Grundlage:** HQ-Platzhalter durch nicht interaktive Campus-Ansicht ersetzt; native 640×400-Pixelgrafik, feste Grundstücksgröße und 15 Gebäudeanker, Teamfarben, Rennbetrieb mit Autos/Personal/Transportern, nummerierte Gebäudeliste.
- [x] Bestehende fünf Gebäudestufen werden gelesen; Stufen verändern Größe, Anbauten und Ausstattung innerhalb reservierter Flächen.
- [x] V1-Grafik überarbeitet: eigene Sprites für alle 15 Einrichtungen statt generischer Rechtecke; Gelände mit Bepflanzung, Zufahrt, Parkplätzen, Randsteinen und Teamdetails. Quelle/Prompt: `assets/hq/ART_NOTES.md`.
- [x] V3: 75 eigenständige Gebäudegrafiken (15 Einrichtungen × 5 Stufen) integriert; generische Anbauten und Skalierung als Stufenersatz entfernt. Detaillierter Gelände-Layer und 1600×1000-Komposition erhalten die Grafikdetails.
- [x] In Godot geprüft: alle 75 Sprites, fünf Campus-Stufen und HQ-Navigation; echte Bildschirmaufnahme mit Metal-Renderer erstellt. Prüfbefehl: `godot --headless --path . --script res://tools/hq_visual_check.gd`.
- [x] Stil festgelegt: illustrierter Tycoon-Stil (`docs/hq_screen_design.md` oben). Offen: Art-Pass mit dem Spieler abstimmen: Gelände/Gebäude-Maßstab, Stufenidentität, Perspektive und kleine Rennbetriebs-Sprites. Grafikqualität ist nicht durch technische Tests abgenommen.
- [x] R4-Datenmodell für alle 15 Gebäude: Verfügbarkeit, Stufen und Bauprojekte. Frühere visuelle Standardwerte werden einmalig übernommen.
- [x] Gebäudeauswahl, Details, Upgrade-Vorschau und Bau (R4b). Weitere Simulationseffekte bleiben offen.

## 🐞 Bugs
- [ ] *(noch keine offenen)*

## ✨ UI-Feinschliff
- [ ] *(noch keine offenen)*

## 📌 Später (vereinbart)
- [ ] **Speichern/Laden** (ein Spielstand in `user://`, Windows + macOS) – nach R3, evtl. erst nach R7; bis dahin startet jedes Spiel mit der Testwelt
- [ ] **Styling-Änderungen und UI-Feinschliff** – nach R3

## 📌 Offen aus R1 (später)
- [ ] **Delegieren** an den Sportdirektor (Verträge für Nachwuchs, Ersatzfahrer, Personal) – sinnvoll ab R2/R3 (Design-Dok. 5.4)
- [ ] **Abwerben ohne Ausstiegsklausel**: mit dem anderen Team über eine Ablöse verhandeln
- [ ] **KI-Teams werben eigenes Personal ab** (Interesse anderer → Angebote, Inbox-Meldung)

## 📌 Offen aus dem Entwicklungslabor
- [x] Vorauswahl der Häkchen nach CFD-Ergebnis
- [ ] Kosten und Gewinne der Schritte im Playtest kalibrieren (Freigabe ist der größte Kostenblock)

## 📌 Ausbau der Entwicklung (Details: `docs/car_model.md` 17)
**R3e – als Nächstes nach dem Playtest:**
- [ ] 17.1 Track-Test als echter Moment: Direktvergleich alt/neu mit Ergebnis-Bildschirm, Entscheidung „behalten / zurück“, technisches Feedback des Fahrers bestimmt die Genauigkeit
- [ ] 17.2 Entwicklungsrennen sichtbar: Fahrerlager-News über Updates der Gegner, Entwicklungs-Grafik pro Team, Rangliste „wer entwickelt am schnellsten“
- [ ] 17.3 Korrelationsprobleme: verschobene Prognosen nach mehreren Fehlschlägen, Projekt „Windkanal-Korrelation“ als Gegenmittel

**Nach R3 (mit den Strecken-Specs):**
- [ ] 17.4 Streckencharakter (Abtrieb / Effizienz / Bremsen / Hitze), danach streckenspezifische Teile

**Macht es spannender:**
- [ ] 17.5 Ideen mit Urheber; Wissen wandert mit dem Personal (mit R4)
- [ ] 17.6 Risiko-Abkürzungen: Qualitätsprüfung überspringen, Eil-Werkzeuge
- [ ] 17.7 Update-Pakete mit Zusammenspiel-Bonus über mehrere Teile
- [ ] 17.8 Kopieren: Fotos der Gegner-Teile werden zu neuen Ideen

**Große Hebel (später):**
- [ ] 17.9 Fahrzeugkonzept fürs nächste Jahr setzt die Obergrenze (falsches Konzept = Sackgasse) – nach R3e, spätestens R9
- [ ] 17.10 Budget Cap und Windkanal-/CFD-Stunden nach WM-Platz (ATR) – R9 (Finanzen R6)
- [ ] 17.11 Regeländerungsjahre setzen Teile zurück – R9

## 📌 Offen aus R2 (Saison)
- [ ] 1:1-Gespräche: mehr Themen und Formulierungen (Design-Dok.: ~30 Themen, mehrere Formulierungen je Persönlichkeit), Inhalte später in Datendateien; weitere Auslöser für Gesprächswünsche (Angebot eines Rivalen, Streit mit dem Ingenieur, Angst nach Unfall)
- [ ] Versprechen aus Gesprächen („Gleichbehandlung“, „bald Vertragsgespräche“) haben noch keine Frist und werden nicht geprüft
- [ ] Schlüsselmoment „Reparatur“ (Design-Dok. 11.3) fehlt noch
- [ ] Entwicklung auch während der Saison (Training, Leistung, Selbstvertrauen – Sim-Dok. 13); bisher nur einmal im Winter
- [ ] **Budget wächst ohne Grenze** (Preisgeld ≫ Gehälter, sonst keine Kosten) – R6a: Einnahmen und Kosten sind gekoppelt; Restwachstum bei KI-Teams offen, siehe R6 oben
- [ ] Autos ändern sich im Winter nur per Platzhalter-Regel (Technik-Personal, etwas Budget, Zufall) – echte Entwicklung mit R3
- [ ] Sportdirektor besetzt am Renntag leere Cockpits und Stellen automatisch (für Playtests) – später als Delegieren-Option einstellbar
- [ ] Ersatzfahrer bei Verletzung/Krankheit einsetzen; Flügelstufe als Entscheidung
- [x] Besitzer-Ziel im Saisonrückblick (R6c)
- [ ] Saisonrückblick: „Große Momente“ nur aus Ergebnissen (Siege, Podien, Poles) – später auch Strategie-Treffer, Boxenstopp-Pannen, Gespräche

## 📌 Offen aus R3
- [ ] Kalibrieren im Sim-Labor: Entwicklungstempo über eine volle Saison (Ziel +0,6–1,0 s), Abstand reich/arm, Ausfallquote (Tests: 5–7 %, Ziel ~5 %)
- [ ] Getriebe-Laufleistung (6 Rennen, danach höheres Risiko) – kommt mit R9 (Kontingente, Strafen)
- [ ] Personal der Abteilungen selbst einstellen/entlassen – bezahlt seit R6a (monatlich), Einstellen offen; bis dahin Kopfzahl aus dem Budget
- [ ] Platzhalter-Grafiken (`assets/car/car_top.svg`, `assets/parts/*.svg`) durch echte Grafiken ersetzen – Dateinamen und Zonen (`ui/car_layout.gd`) beibehalten
- [ ] Strecken-Specs (Low-/High-Downforce-Teile) – nach R3
- [ ] Teil-Historie als eigene Ansicht (alle Versionen mit Prognose/Realität) – im Teil-Panel bisher die letzten 4

## 📌 Offen aus R2 (Simulation)
- [ ] **2D-Ansicht auf die neue Simulation umstellen** – erst viel später, gemeinsam mit der zweiten Person (alter `RaceSim` bleibt bis dahin unverändert)
- [ ] **Platzhalter-Strecken ersetzen**, sobald die echten Strecken gebaut sind (`sim/weekend/track_layouts.gd`)
- [ ] Feinabstimmung im Sim-Labor laufend (Werte in `sim/weekend/sim_tuning.gd`, Strecken-Werte in `track_layouts.gd`)
- [ ] **Top-Stratege bringt nach oben noch zu wenig** (95 ≈ 60, 25 = −28 Pkt./Saison). Ideen: Reifenwahl im Qualifying (Q2-Reifen), Streckenentwicklung, Tankmenge je nach Fahrer
- [ ] Vorgespielte Runden der Testwelt laufen noch über `QuickRace` (schneller Spielstart) – Detail-Ergebnisse gibt es erst ab dem ersten echten Rennen

## ✅ Erledigt
- [x] **R3 Auto & Entwicklung** komplett (siehe Stand); Mockup `docs/ui_mockups/r3_car.html`, Modell `docs/car_model.md`
- [x] **Saisonbilanz als Overlay** beim Saisonwechsel (auch aus dem Saisonrückblick aufrufbar): Urteil Ergebnis vs. Auto, WM-Platz vs. Vorjahr, Punkte, Siege/Podien/Poles, Preisgeld, Weltmeister, Saisonverlauf (Punkte-Kurve + Platz nach jeder Runde), Teamleistung (Boxenstopps, Fehler, Ausfälle Technik/Unfall, Überholmanöver, Schlüsselmomente), Fahrer mit Bewertung gegenüber dem Auto, Winterentwicklung (Fahrer mit größten Attribut-Änderungen, Personal), neues Auto je Wert, größte Fortschritte/Rückschritte im Feld, Rücktritte, beendete Verträge, Endstand
- [x] **R2 Abschluss – mehrere Saisons:** Wintertraining nach verborgener Alterskurve (junge Fahrer wachsen Richtung Potenzial je nach Arbeitsmoral, Fahrpraxis und Moral; nach dem Peak zuerst Körper, dann Fahrkönnen; Mentales wächst weiter), Personal-Entwicklung, Karrierestatistik und Titel, Rücktritte (Fahrer ab 35, Personal ab 63, schwache vertragslose), Markt begrenzt, Erinnerung im September an eigene auslaufende Verträge, Notbesetzung von Cockpits und Stellen am Renntag, Auto-Änderung über den Winter (Platzhalter bis R3)
- [x] Posteingang zeigte bei Nachrichten aus dem Vorjahr das aktuelle Jahr
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
