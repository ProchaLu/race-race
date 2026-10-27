# Backlog – Bugs, Feinschliff, offene Punkte

Regel: **Kaputtes oder Störendes sofort beheben.** Feinschliff wird gesammelt und am Ende jeder Runde abgearbeitet. Erledigtes wird abgehakt und bleibt als Verlauf stehen.

## 📍 Stand (30.10.2026)
**R3 komplett (Auto & Entwicklung):** 13 Teile mit Versionen, Masse, Zuverlässigkeit; Autowerte daraus, Gewicht, Kühlung (Renningenieur wählt Öffnungen), Bremsleistung, Traktion, Defekte pro Teil. Entwicklung mit 5 Abteilungen (Design, CFD, Windkanal, Prüfstände, Fabrik; Personalstärke aus dem Budget, Schlüsselpersonen, Gebäudestufen), parallele Projekte, Kosten, Prognose vs. Realität. Teile pro Auto, Stückzahlen und Ersatzteile, Unfälle zerstören Teile, Bremsen als Verbrauchsteil, Notfertigung, Wochenend-Block „Teile“, Training „Neue Teile testen“. Nächstjahresauto, Saisonwechsel mit Nächstjahres-Entwicklung. KI entwickelt nach denselben Regeln.
**Entwicklungslabor umgesetzt:** alte Version als Basis → Ideen → CFD (grob, mit ±) → Windkanal/Prüfstand (Kombinieren, Verfeinern) → Freigeben/Verwerfen → Detailkonstruktion → Werkzeuge → Fertigung → Qualität → Direktvergleich auf der Strecke, „Zurück zur alten Version“. Entscheidungen an Meilensteinen (Inbox + Werkstatt-Spalte „Deine Entscheidung“), „Aero-/Chassis-Chef entscheiden lassen“; delegiert/KI automatisch. Details: `docs/car_model.md` 3a.
**R4 komplett (HQ):** 15 Gebäude mit 5 Stufen auf festem Gelände, Bau mit Kosten/Bauzeit/Unterhalt, bis zu zwei Bautrupps, Wirkung auf Entwicklung, Wochenende und Stimmung (Stufe 1 gegen 5 deutlich), KI baut, Saisonbilanz. Details: `docs/hq_screen_design.md`, `docs/r4_review.md`.
**Nächster Schritt:** R5 (Motor). Offen für später: Playtest und Feinabstimmung von R3/R4, Styling, R3e (`docs/car_model.md` 17).

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
- [ ] **Budget wächst ohne Grenze** (Preisgeld ≫ Gehälter, sonst keine Kosten) – Finanzen kommen mit R6
- [ ] Autos ändern sich im Winter nur per Platzhalter-Regel (Technik-Personal, etwas Budget, Zufall) – echte Entwicklung mit R3
- [ ] Sportdirektor besetzt am Renntag leere Cockpits und Stellen automatisch (für Playtests) – später als Delegieren-Option einstellbar
- [ ] Ersatzfahrer bei Verletzung/Krankheit einsetzen; Flügelstufe als Entscheidung
- [ ] Besitzer-Ziel im Saisonrückblick (kommt mit R6 Besitzer)
- [ ] Saisonrückblick: „Große Momente“ nur aus Ergebnissen (Siege, Podien, Poles) – später auch Strategie-Treffer, Boxenstopp-Pannen, Gespräche

## 📌 Offen aus R3
- [ ] Kalibrieren im Sim-Labor: Entwicklungstempo über eine volle Saison (Ziel +0,6–1,0 s), Abstand reich/arm, Ausfallquote (Tests: 5–7 %, Ziel ~5 %)
- [ ] Getriebe-Laufleistung (6 Rennen, danach höheres Risiko) – kommt mit R9 (Kontingente, Strafen)
- [ ] Personal der Abteilungen selbst einstellen/entlassen und bezahlen – R4 (HQ) / R6 (Finanzen); bis dahin Kopfzahl aus dem Budget
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
