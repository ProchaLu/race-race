# Simulationsmodell – Rennwochenende (R2)

> Das Herzstück des Spiels. Ziel: **jeder Faktor macht einen echten, messbaren Unterschied** – Auto, Fahrer, Strecke, Personal, HQ und die Entscheidungen des Teamchefs. Alle Zahlen sind Startwerte und werden mit dem **Sim-Labor** (Abschnitt 14) gegen Zielwerte eingestellt.
>
> Verwandt: Design-Dokument 8.4–8.6, Mockups `docs/ui_mockups/r2_weekend.html` und `r2_driver_talk.html`.

---

## 0. Grundprinzipien

1. **Alles wird in Sekunden pro Runde gerechnet**, nicht in abstrakten Punkten. Jeder Anteil (Auto, Fahrer, Setup, Reifen, Sprit, Wetter, Verkehr, Form, Fehler, Schaden) wird pro Runde gespeichert ⇒ das Ergebnis kann erklären, *warum* jemand schneller war.
2. **Die 0,1-s-Physik bleibt** (Positionen auf der Strecke, Windschatten, Verkehr, Überholzonen). Die Rundenzeit-Anteile werden in Geschwindigkeits-Multiplikatoren pro Streckenabschnitt umgerechnet. Die 2D-Ansicht (zweite Person) liest dieselben Zustände.
3. **KI-Teams nutzen exakt dieselben Regeln** und ihre eigenen Mitarbeiter.
4. **Gewichtung:** Das Auto ist der größte Einzelfaktor (~70 % der Leistungsunterschiede), Fahrer und Personal machen bewusst etwas mehr aus als in der echten F1 (dort ~75–80 % Auto) – sie sollen sich lohnen.
5. **Ab Anfang vollständig:** Reifentemperatur, Sprit-Strategie, Teilschäden, Wetter mit abtrocknender Strecke und ereignisgesteuertes Safety Car sind von Beginn an Teil der Logik.
6. **Strecken:** 24 **Platzhalter-Strecken** (`sim/weekend/track_layouts.gd`) nach dem Vorbild echter Kurse (Monaco, Monza, Spa, Silverstone …): Geraden und Kurven mit Kurvengeschwindigkeit ⇒ Tempoprofil, dazu Länge, Rundenzeit, Boxenverlust, Reifenverschleiß, Überholfaktor, DRS-Zonen, Temperatur, Regen- und Safety-Car-Risiko. Die echten Strecken werden später gebaut und ersetzen die Platzhalter. Der Test Ring wird nicht verändert. Die 2D-Ansicht kommt erst viel später – Fokus ist die Schnellsimulation.

---

## 1. Rundenzeit

```
Rundenzeit = Referenzzeit der Strecke
           + Auto + Fahrer + Setup + Reifen + Sprit + Wetter
           + Schaden + Verkehr + Form (Zufall) + Fehler
```

### 1.1 Auto
- Pro Streckenabschnitt: **Geraden** → Motorleistung + Luftwiderstand, **schnelle Kurven** → Abtrieb, **langsame Kurven** → mechanischer Grip.
- Gewichtet nach Zeitanteil der Abschnittsarten auf der Strecke ⇒ eine Abtriebsstrecke bevorzugt andere Autos als eine Motorstrecke.
- **1 Bewertungspunkt ≈ 0,05 s** pro Runde (auf einer ausgewogenen Strecke). Feld 55–90 ⇒ **1,5–2 s**.
- Reifenschonung (Verschleiß) und Zuverlässigkeit (Defekte) wirken separat.

### 1.2 Fahrer
| Anteil | Berechnung | Spanne |
|---|---|---|
| Pace | 45 % Kurven + 35 % Bremsen + 20 % One-Lap-Pace (Quali: 50 % One-Lap-Pace) · **1 Punkt ≈ 0,02 s** | Bester vs. schwächster F1-Fahrer ≈ **0,5 s**; vs. Durchschnitt ≈ 0,25 s; F2-Niveau ≈ 1 s |
| Selbstvertrauen + Moral | (Wert − 50) / 50 × 0,08 s | ±0,08 s |
| Fitness | ab 60 % Renndistanz bis +0,2 s (schlechte Fitness) | 0–0,2 s |
| Streckenkenntnis | Rookie beim ersten Besuch +0,3 s; Training, Simulator und Anpassungsfähigkeit bauen ab | 0–0,3 s |
| Form pro Runde | Zufall, σ = 0,15 s (Konstanz 100) bis 0,45 s (Konstanz 0) | – |
| Regen | siehe 9 | bis > 1 s |

### 1.3 Setup
**Qualität (0–100 %)** entsteht im Training aus: Renningenieur (Setup-Arbeit), technischem Feedback des Fahrers, Chemie Ingenieur–Fahrer, Trainingsprogramm, Streckenkenntnis, später Simulator (HQ). Wetter im Training (Regen = wenig Trockendaten) senkt sie.

| Setup | Zeit | Typisch |
|---|---|---|
| 100 % | −0,20 s | perfekter Ingenieur + Feedback-Ass + volles Training |
| 85 % | ±0 | gutes Team |
| 70 % | +0,25 s | normal |
| 50 % | +0,60 s | schwacher Ingenieur, Rookie, wenig Training |
| 30 % | +1,0 s | verkorkst (z. B. verregnetes Training) |
| 0 % | +1,6 s | praktisch nie |

Ein schlechtes Setup kostet zusätzlich: **Fehler** bis +30 %, **Reifenverschleiß** bis +12 %, Selbstvertrauen.

**Setup-Richtung (Flügelstufe)** – Entscheidung des Teamchefs nach Rücksprache mit dem Ingenieur (Empfehlung sichtbar, delegierbar):
| Stufe | Kurven | Geraden | Folgen |
|---|---|---|---|
| Viel Flügel | schneller | langsamer | Reifen schonender, Überholen schwerer, leichter zu überholen |
| Ausgewogen | – | – | – |
| Wenig Flügel | langsamer | schneller | Überholen/Verteidigen leichter, mehr Reifenverschleiß, unruhiger im Regen |

**Regen-Poker** (bei Regenrisiko): Setup trocken / Kompromiss / nass verschiebt das Tempo je nach Nässe (trocken: −0,1 s im Trockenen, +0,6 s im Nassen; nass: umgekehrt).

---

## 2. Reifen

### 2.1 Mischungen (Startwerte, Streckenfaktor 1,0)
| Mischung | Grundtempo | Abbau pro Runde | Klippe ab Runde ~ | Aufwärmrunde |
|---|---|---|---|---|
| Soft | ±0 | 0,09 s | 18 | +0,5 s |
| Medium | +0,45 s | 0,06 s | 28 | +0,8 s |
| Hard | +0,85 s | 0,04 s | 40 | +1,3 s |
| Intermediate | siehe 9 | – | – | +0,8 s |
| Regen | siehe 9 | – | – | +1,0 s |

Nach der Klippe: +0,3 s pro Runde, steigend. **Regel:** mindestens zwei Trockenmischungen pro trockenem Rennen.

### 2.2 Abbau-Faktoren
| Einfluss | Wirkung |
|---|---|
| Reifenmanagement Fahrer | ×0,75 … ×1,25 |
| Reifenschonung Auto | ±15 % |
| Setup-Qualität | bis +12 % |
| Flügelstufe | ±5 % |
| Briefing „Angriff“ | +8 % |
| Schmutzige Luft (Hinterherfahren) | +10 % |
| Streckenfaktor | ×0,5 … ×1,5 |

### 2.3 Reifentemperatur
- Jede Mischung hat ein **Arbeitsfenster**. Die Temperatur ergibt sich aus Streckentemperatur (Tageszeit, Wolken, Sonne), Fahrstil/Pushen, schmutziger Luft, Safety-Car-Phasen.
- **Zu kalt:** weniger Grip, **Graining** (Abbau ↑). Typisch: nach Safety Car, Restart, harte Reifen an kühlen Tagen.
- **Zu heiß:** **Blasenbildung** (Abbau ↑↑). Typisch: Softs an heißen Tagen, langes Hinterherfahren.
- Reifenmanagement des Fahrers hält die Reifen im Fenster.

⇒ **Undercut und Overcut entstehen von selbst** (frischer Reifen vs. Aufwärmrunde vs. Boxenverlust vs. Verkehr).

---

## 3. Sprit
- **0,03 s pro kg**, Start mit ~100 kg ⇒ anfangs +3 s, pro Runde ~0,06 s schneller.
- Der **Strategiechef legt die Tankmenge fest**. Weniger Sprit ⇒ anfangs schneller, später **Spritsparen** (Lift & Coast).
- Kosten des Sparens durch **Spritmanagement** des Fahrers: 0,4 s (Ass) bis 1,2 s (schwach) pro Runde für dieselbe Ersparnis.
- Safety-Car-Phasen sparen Sprit. Verrechnet sich der Stratege ⇒ „Sprit leer“-Ausfall möglich.

---

## 4. Boxenstopp (Boxencrew-Chef)

### 4.1 Standzeit – **absolutes Minimum 2,0 s**
| Crew-Tempo | Typischer Stopp | Bestwert |
|---|---|---|
| 100 (perfekt) | 2,1 s | 2,0 s |
| 75 | 2,5 s | 2,2 s |
| 50 | 2,9 s | 2,5 s |
| 25 | 3,4 s | 2,9 s |
| 0 | 4,0 s | 3,4 s |

### 4.2 Fehler (Präzision; Risiko steigt mit dem Quadrat der Ungenauigkeit)
| Fehler | Zeitverlust | Perfekt (95+) | Durchschnitt (50) | Schwach (20) |
|---|---|---|---|---|
| Zögern | +0,3–1,5 s | 4 % | 10 % | 15 % |
| Langsames Rad | +2–6 s | 0 % | 4 % | 8 % |
| Radmutter klemmt | +8–25 s | 0 % | 1 % | 3 % |
| Unsichere Freigabe | 5 s Strafe | 0 % | 0,5 % | 1,5 % |
| Rad nicht fest | Ausfall | 0 % | 0,1 % | 0,4 % |

Eine perfekte Crew macht **keine schweren Fehler** – ihr „Patzer“ ist ein etwas längerer Stopp.

- **Druck erhöht das Risiko:** Doppelstopp (zweites Auto wartet), Safety Car (alle gleichzeitig), Reifenwechsel im Regen.
- **Reparaturen:** Nase/Frontflügel +6–10 s Standzeit. Unterboden nicht reparierbar.
- **Boxengasse:** Zeitverlust der Strecke; unter Safety Car ~55 %, unter VSC ~70 %.
- **Entwicklung:** siehe 13.

---

## 5. Strategiechef (und KI-Strategie)
- Berechnet alle sinnvollen Pläne (1/2/3 Stopps, Mischungen, Tankmenge) mit **geschätztem** Reifenabbau.
- **Schätzfehler** σ = 25 % × (1 − Reifenmodell/100); Longruns im Training verkleinern ihn um bis zu 50 %.
- Im Rennen korrigiert er die Schätzung jede Runde – wie schnell, hängt von der **Datenanalyse** ab.
- Safety Car / Regen / Stallorder: Entscheidung mit „Rauschen“ je nach **Rennverständnis** und **Wetterlesen**.
- Bietet dem Spieler 2–3 Pläne mit Prognose und Risiko an (Mockup) und entscheidet im Rennen alles, was nicht zu den Schlüsselmomenten gehört.
- Gilt identisch für KI-Teams.

---

## 6. Überholen
Statt eines Zufalls pro Tick gibt es **echte Versuche an Überholzonen** (Ende einer Geraden / Bremszone):

1. **Voraussetzung:** < 1,0 s Abstand am Zonenbeginn.
2. **Vorteil** = Tempounterschied (Reifen, Auto, Fahrer, Setup) + **DRS** (< 1 s am Messpunkt) + Windschatten + Flügelstufe.
3. **Versuch ja/nein:** Aggressivität, Briefing, 1:1-Gespräch, Lage (Rennende, Stallorder).
4. **Erfolg:** Zone × Vorteil × (1 + (Überholen + Bremsen/2 − Verteidigen − Zweikampf/2) / 150).
5. **Ausgang:**
   - vorbei
   - abgewehrt: beide verlieren 0,2–0,5 s, Verteidiger-Reifen leiden ⇒ „DRS-Züge“
   - Verbremser des Angreifers
   - **Kontakt:** ~2 % × Aggressivität beider × fehlende Zweikampfstärke (Regen ×2) ⇒ Schaden (7), Trümmer (8)
6. **Schmutzige Luft:** < 1 s dahinter ⇒ 1–2 % weniger Grip in schnellen Kurven, Reifen und Bremsen heizen auf.

---

## 7. Schäden
| Schaden | Wirkung | In der Box |
|---|---|---|
| Frontflügel leicht (Endplatte) | +0,1–0,3 s | wechselbar, lohnt oft nicht |
| Frontflügel schwer | +1–3 s, unruhig | Wechsel +6–10 s Standzeit |
| Unterboden | +0,1–0,5 s | nicht reparierbar |
| Seitenkasten/Kühlung | Überhitzen ⇒ Motor schonen | nicht reparierbar |
| Heckflügel | DRS defekt, weniger Abtrieb | nicht reparierbar |
| Reifenschaden | langsame Runde zur Box (20–40 s), kann Unterboden beschädigen | Reifen ja |
| Aufhängung | Ausfall oder stark verlangsamt | nein |
| Bremsen | Überhitzen beim Hinterherfahren, Verbremser ↑ | nein |

Der Stratege (bzw. der Spieler im Schlüsselmoment) entscheidet, ob sich eine Reparatur lohnt.

---

## 8. Fehler, Defekte, Safety Car

### 8.1 Fahrerfehler
Grundrisiko ~0,4 % pro Runde × Faktoren:
| Faktor | Wirkung |
|---|---|
| Konstanz | ×0,5 … ×2 |
| Fokus | Risiko ↑ spät im Stint |
| Nervenstärke | Risiko ↑ im Duell, letzte 5 Runden, Titelkampf |
| Nässe | ×1 … ×4 (je nach Regenkönnen) |
| Gischt | ×1,5 |
| Reifen nach der Klippe / außerhalb des Fensters | ×2 |
| Setup schlecht | bis ×1,3 |
| Fitness | Risiko ↑ spät im Rennen |
| Briefing / 1:1 | je nach Wahl |

**Schwere:** 80 % Verbremser (0,5–1,5 s, evtl. Bremsplatte), 17 % Ausritt (3–8 s, evtl. Schaden), 3 % Unfall. Ziel: ~3 % Unfallausfälle pro Fahrer und Rennen.

### 8.2 Defekte
- Pro Rennen ~4 % × (1,5 − Zuverlässigkeit/100), verändert durch Motorchef (Zuverlässigkeitsfokus) und Fabrik (Qualitätskontrolle).
- Nicht jeder Defekt ist ein Ausfall: Leistungsverlust (+0,5 s/Runde), Motor schonen, Getriebe-Gangverlust.

### 8.3 Safety Car – nur durch Ereignisse, beliebig oft
| Ereignis | Folge |
|---|---|
| Unfall auf der Strecke | 70 % Safety Car, 25 % VSC |
| Auto steht neben der Strecke | 50 % VSC, sonst gelbe Flagge |
| Trümmer nach Kontakt | 30 % SC oder VSC |
| Schwerer Einschlag (Barriere) / Starkregen | Rote Flagge |

- SC 3–6 Runden; Feld schiebt sich auf ~0,8 s zusammen; Überrundete dürfen sich zurückrunden.
- Restart: Reaktion + Zweikampfstärke, kalte Reifen (Temperatur!), Chaos-Chance.
- Rote Flagge: Reifenwechsel frei, Neustart.

---

## 9. Wetter
- **Zeitverlauf pro Minute:** Regenstärke 0–1 (Niesel / Regen / Starkregen), Lufttemperatur, Wolken, Wind.
- **Streckennässe 0–1:** steigt mit Regen, sinkt durch Abtrocknen (Temperatur, Wind, Sonne, Autos auf der Ideallinie). **Die Ideallinie trocknet zuerst.**
- **Reifen vs. Nässe:**
  - Slicks: ab ~15 % Nässe steil schlechter (bis +25 s)
  - Intermediates: ideal 30–60 %; im Trockenen +3 s und Überhitzen (Verschleiß ×3)
  - Regenreifen: ideal > 70 %
  - Die **Übergangspunkte** ergeben sich daraus von selbst.
- **Regenkönnen:** (60 − Regenkönnen) × 0,02 s × Nässe; Fahrerunterschiede wachsen auf > 1 s.
- **Gischt:** hinter anderen Autos weniger Sicht ⇒ mehr Fehler, weniger Überholen.
- **Vorhersage:** Fehler hängt vom **Wetterlesen** des Strategiechefs ab (Mockup: „±10 %“).

---

## 10. Start, Qualifying, Training

### 10.1 Start
- Reaktion 0,15–0,35 s (Reaktion + Starts) + Streuung; Fehlstart-Risiko gering.
- Gedränge in Kurve 1: Kontakt-Chance vor allem im Mittelfeld (Aggressivität, Zweikampf).

### 10.2 Qualifying
- Q1 (22 → 16), Q2 (16 → 10), Q3 (10), je 2 Versuche.
- One-Lap-Pace zählt stark, wenig Sprit, neue Softs, **Streckenentwicklung** (spätere Runs schneller).
- Letzter Versuch: Nervenstärke. Verkehr: ~10 % der Runden verlieren 0,2–0,6 s (Strategie-Timing reduziert).
- Wetter: Regen-Quali möglich, Timing wird zur Lotterie (Stratege!).

### 10.3 Training
- Programm pro Fahrer (Mockup): **Setup-Arbeit** (Setup %), **Longruns** (Reifendaten ⇒ kleinerer Schätzfehler des Strategen), **Akademiefahrer im FP1** (Erfahrung für ihn, weniger Setup-Zeit für den Stammfahrer).
- Rookies bauen Streckenkenntnis ab. Regen im Training ⇒ weniger Trockendaten.

---

## 11. Entscheidungen des Teamchefs und ihre Wirkung

### 11.1 Briefing (Strategie-Bildschirm)
Schnelle Taktikwahl pro Fahrer. **Unter jeder Option stehen die Auswirkungen**, dazu die **Empfehlung des Renningenieurs mit Begründung**. Die Werte hängen von der Persönlichkeit ab (z. B. „Angriff“ beim Hitzkopf ⇒ mehr Kontaktrisiko).
| Option | Startwerte |
|---|---|
| Heimbringen | Fehler −15 %, Überholversuche −30 %, Reifen −5 % |
| Angriff | Überholversuche +30 %, +0,05 s Tempo am Limit, Reifen +8 %, Kontakt +10 % |
| Kein Druck | Nervenstärke +6, Fehler −8 %, Überholversuche −10 % |
| Teamplayer | akzeptiert Stallorder, hilft im Duell, Moral −1 (bleibend) |

### 11.2 1:1-Gespräch vor jedem Rennen
- **Fix vor jedem Rennen mit jedem Fahrer** (wie ein 1:1 mit dem Teammanager). Ein Wochenthema aus seiner Lage, 4 Antworten (aus 6–8 möglichen), kleine Effekte meist nur für dieses Rennen.
- **Gespräch auf Wunsch des Fahrers:** selten, mit echtem Auslöser (benachteiligt, Nr.-1-Rolle, Angebot eines Rivalen, Streit mit dem Ingenieur, Stallorder-Konflikt, Angst nach Unfall, private Krise). 3 Runden, mehr Antworten, verzweigt; **Gesprächsstimmung** steigt und fällt und skaliert am Ende alle Effekte; große Folgen (Moral ±10, Versprechen, Teamregeln, Wechselwunsch oder jahrelange Loyalität).
- **Effekte (logisch zu einem Gespräch):** Selbstvertrauen, Fehlerrisiko/Konzentration, Nervenstärke, Angriffslust, Stallorder-Akzeptanz, Setup (Technik-Hilfe) – nur dieses Rennen; Moral, Beziehung, Chemie, Versprechen – bleibend. **Kein** Fitness-Effekt (kommt aus dem Training).
- **Verdeckte Reaktionen** („?“) werden mit der Zeit bekannt; Mentaltrainer verrät sie schneller.
- **Abnutzung:** dieselbe Ansprache wirkt bei Wiederholung schwächer.
- **Gedächtnis:** Fahrer beziehen sich auf frühere Gespräche und Versprechen.
- **Abwechslung:** ~30 Themen, mehrere Formulierungen pro Thema und Persönlichkeit, Antwort-Pool; Inhalte in Datendateien (übersetzbar, leicht erweiterbar).
- Delegierbar an den Mentaltrainer.

### 11.3 Weitere Entscheidungen
Wochenendziel, Trainingsprogramm, Stallorder-Regel, Ersatzfahrer, Strategie-Plan, Regen-Poker, Flügelstufe, 2–4 Schlüsselmomente im Rennen (Safety Car, Regen, Stallorder, Reparatur) – alle mit „Mitarbeiter entscheiden lassen“.

### 11.4 Stallorder
Befolgen hängt von Temperament, Loyalität, Moral, Briefing „Teamplayer“ und 1:1 ab. Weigerung ⇒ Konflikt (Moral, Medien, evtl. Gesprächswunsch).

### 11.5 Simulations- vs. 2D-Modus
Im Simulationsmodus gibt es nur Briefing, 1:1, Strategie und Schlüsselmomente. Den **Fahrmodus** (Schonen/Normal/Pushen) gibt es nur im 2D-Modus; in der Simulation wählt ihn der Fahrer/Ingenieur selbst.

---

## 12. Unterschiede im Überblick

Pro Runde:
| Faktor | Perfekt vs. Durchschnitt | Perfekt vs. schlecht |
|---|---|---|
| Auto (Feld) | 0,6–0,8 s | 1,5–2 s |
| Fahrer-Pace (trocken) | 0,25 s | 0,5 s (F1), 1 s (F2-Niveau) |
| Fahrer im Regen | 0,6 s | 1,5 s + |
| Setup | 0,2–0,45 s | 1+ s (selten) |
| Konstanz | Streuung ±0,2 s | ±0,45 s + Fehler |
| Reifenmanagement | Stint +3–4 Runden | +6–8 Runden ⇒ andere Strategie |

Pro Rennen:
| Faktor | Perfekt vs. Durchschnitt | Perfekt vs. schlecht |
|---|---|---|
| Boxenstopp | 0,8 s je Stopp, keine schweren Fehler | 1,9 s je Stopp + Fehlerrisiko |
| Strategiechef | 2–5 s | 10–20 s, im Regen/SC bis 30 s |
| Start | 0–1 Platz | 1–3 Plätze |
| Zuverlässigkeit | 2 % vs. 4 % Ausfall | 2 % vs. 8–10 % |

Saison: perfekte statt durchschnittliche Crew + Stratege ≈ **20–40 WM-Punkte** für ein Mittelfeldteam.

---

## 13. Entwicklung durch Training und Leistung (Fahrer **und** Personal)
- **Jeder** verbessert oder verschlechtert sich mit der Zeit – Fahrer, Boxencrew, Ingenieure, Strategen.
- Treiber: Training (Intensität/Schwerpunkt, Trainer, Einrichtungen), **Leistung** (gute Ergebnisse ⇒ Selbstvertrauen ⇒ schneller lernen), Arbeitsmoral, Alter, Moral.
- **Wer nicht trainiert oder dauerhaft schlecht abliefert, baut ab** (Rost, Selbstzweifel).
- **Boxencrew:** wird durch Übungsstopps (Crew-Training) und gute Stopps besser; Serien von Fehlern kosten Selbstvertrauen ⇒ mehr Fehler, bis Training und Erfolge sie wieder stabilisieren.
- Ingenieure/Strategen: lernen durch Erfahrung (Rennen, Daten), gute Arbeit; stagnieren bei schlechtem Umfeld.
- Alles sichtbar in Attribut-Verläufen und als Inbox-Hinweis („Die Crew hat sich verbessert“).

---

## 14. Sim-Labor (Testwerkzeug)
Spielt Hunderte Rennen ohne Grafik und misst gegen Zielwerte. Szenarien mit gezielt veränderten Autos, Fahrern und Mitarbeitern.

| Szenario | Ziel |
|---|---|
| Dominantes Auto (+0,5 s) + Top-Fahrer | 70–85 % Siege |
| Dominantes Auto + schwacher Fahrer | 15–30 % (vor allem auf passenden Strecken) |
| Enges Feld (< 0,15 s) | Bester 30–40 % |
| Top-Fahrer im Mittelfeldauto (−0,8 s) | 0–5 % Siege, regelmäßig über dem Auto platziert |
| Überholmanöver pro Rennen | wird gemessen und eingestellt |
| Mindestens ein Safety Car | ~50–60 % der Rennen, mehrere möglich |
| Ausfälle | 5–10 % |
| 1 Stopp vs. 2 Stopps | beide gewinnen regelmäßig |
| Perfekte vs. schlechte Crew / Stratege | messbar in Punkten pro Saison |
| Regenkönner im Regen | gewinnt deutlich mehr Plätze |
| Setup 90 % vs. 60 % | messbarer Unterschied in Quali und Rennen |

Ausgabe: Tabelle + Verteilungen (Siege, Positionen, Stopps, Überholmanöver, SC, Ausfälle, Rundenzeit-Anteile).

---

## 15. Umsetzung (Stand R2, Kern)

**Code:** `sim/weekend/` – unabhängig vom alten `RaceSim` (der bleibt für die 2D-Ansicht der zweiten Person unverändert, bis wir gemeinsam umstellen).

| Datei | Inhalt |
|---|---|
| `sim_tuning.gd` | **alle Stellschrauben** an einem Ort |
| `track_layouts.gd` | **24 Platzhalter-Strecken** (Charakter echter Kurse) |
| `track_model.gd` | Mikro-Sektoren aus Layout (oder Fahrlinie), Tempoprofil, Überholzonen, DRS, Varianten fürs Labor |
| `race_conditions.gd`, `weather_timeline.gd` | Distanz, Temperatur, Reifenverschleiß, Regenverlauf, Nässe, Abtrocknen, Vorhersage |
| `team_ops.gd` | Personalwerte des Teams (Stratege, Boxencrew, Ingenieure, Zuverlässigkeit, Trainer) |
| `sim_car.gd` | Zustand eines Autos im Rennen inkl. Rundenzeit-Aufschlüsselung |
| `pace_model.gd` | Rundenzeit-Anteile, Reifen (Temperatur, Klippe, Nässe), Fehler, Briefing |
| `pit_crew.gd` | Boxenstopp (min. 2,0 s, Fehler nach Präzision und Druck) |
| `strategy_planner.gd` | Strategiechef (Pläne mit Schätzfehler, Safety Car, Wetter, Undercut) |
| `qualifying_sim.gd` | Q1/Q2/Q3 |
| `race_engine.gd` | Rennen Sektor für Sektor in Zeitreihenfolge (Verkehr, Überholen, Kontakte, SC/VSC/rote Flagge, Stopps) |
| `weekend_setup.gd` | Autos aus der Spielwelt, Training, Wochenend-Form |

**Ergänzt beim Testen:** Wochenend-Form (Tagesform des Fahrers + „Auto passt zu den Bedingungen“ pro Team), sonst waren Rennen zu vorhersehbar. Auf Geraden zählen auch Abtrieb/mech. Grip (Kurvenausgang). Überholzonen nur auf Geraden ab ~300 m. Reifentemperatur milder, Stratege rechnet mit Betriebstemperatur. Härtere Klippe + Reifenschaden weit über der Klippe. Höherer Reifenabbau (Soft 0,11 / Medium 0,075 / Hard 0,05 s pro Runde), damit 2 Stopps sich lohnen können. Spritsparen 1–3 s pro kg; knapp tanken nur mit gutem Spritsparer. Safety-Car-Entscheidung einmal pro Phase. Stratege deckt Undercut-Versuche (Cover) nur, wenn die frischen Reifen des Hintermanns den Abstand wirklich aufholen würden. Regen: Regenreifen werden bei voll nasser Strecke rechtzeitig aufgezogen, Regenkönnen zählt auch im Duell. **Eigener Zufallsstrom pro Auto und Runde** – macht „Was wäre wenn“-Vergleiche fair.

**Geschwindigkeit:** ein ganzes Wochenende (Quali + 64 Runden) ≈ 0,9 s.

**Sim-Labor:** `godot --headless --path . res://tools/sim_lab.tscn -- <szenario> [rennen] [strecke]` – Rennen i läuft auf Strecke i % 24 (wie eine Saison). Personal-Szenarien sind **gepaarte Vergleiche**: dieselben Rennen zweimal (alle 60 vs. 95/25), so verschwindet der Zufall.
Szenarien: `single`, `tracks`, `baseline`, `dominant_top`, `dominant_weak`, `close_field`, `top_driver_midfield`, `staff`, `crew`, `strategist`, `engineers`, `attr`, `rain`, `setup`, `strategy`, `track`, `all`.

**Gemessen (Stand 23.10.2026, 24 Platzhalter-Strecken):**

| Test | Ergebnis |
|---|---|
| Dominantes Auto + Top-Fahrer | 76–85 % Siege |
| Dominantes Auto + schwacher Fahrer | ~10 % (Teamkollege ~23 %) |
| Enges Feld, bester Fahrer | ~38 % |
| Elite-Fahrer im Mittelfeldauto | 4–11 % Siege, Ø P7 statt P15 wie der Teamkollege |
| Boxencrew 95 / 25 vs. 60 | ±44 Punkte pro Saison, Standzeit 2,45 / 3,4 / 4,8 s |
| Stratege 95 / 25 vs. 60 | ≈ 0 / −30 Punkte pro Saison |
| Renningenieure 95 / 25 vs. 60 | +150 / −75 Punkte pro Saison (Setup) |
| Regenkönner (95 vs. 35) | Ø P10 vs. P13, deutlich mehr Siege |
| Überholmanöver | Ø ~35 pro Rennen, Monaco ~8, Las Vegas ~85 |
| Safety Car / DNF / Pole→Sieg | ~50–60 % der Rennen / ~5 % / ~55 % |
