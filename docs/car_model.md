# Automodell & Entwicklung (R3)

> Ziel: Die Entwicklung soll sich anfühlen wie in einem echten F1-Team – Konzept, Design, Simulation/Windkanal, Fertigung, Prüfstand, Einsatz, Korrelation. **Jede Zahl ist erklärbar** (Tooltip mit Faktoren), alles läuft für KI-Teams nach denselben Regeln.
> Verwandt: Design-Dokument Kapitel 8, `docs/simulation_model.md` (Rundenzeit), Personal-Rollen in `core/staff_roles.gd`.
> Alle Zahlen sind **Startwerte** und werden mit dem Sim-Labor eingestellt (Abschnitt 14).

---

## 0. Grundprinzipien

1. **Das Auto ist die Summe seiner Teile.** Die bisherigen Autowerte (Abtrieb, Luftwiderstand, mech. Grip, Reifenschonung, Zuverlässigkeit) werden aus den Teilen **berechnet**. Die Simulation liest weiter dieselben Werte – sie bekommt nur zusätzlich **Gewicht**, **Kühlung** und **Defekte pro Teil**.
2. **Werte sind relativ** (0–100, 50 = Durchschnitt des Feldes zu Saisonbeginn). 1 Punkt Autowert ≈ 0,05 s pro 90-s-Runde (bestehende Regel `CAR_FRAC_PER_POINT`).
3. **Entwicklung kostet Zeit, Geld und Kapazität.** Mehrere Projekte gleichzeitig sind möglich, jedes wird dann langsamer.
4. **Prognose ≠ Realität.** Was im Windkanal gut aussieht, kann auf der Strecke weniger bringen – oder mehr. Gute Leute und Anlagen machen die Prognose genauer.
5. **Jedes Auto hat seinen eigenen Teile-Stand** (Entscheidungs-Log Nr. 22). Wer das neue Teil zuerst bekommt, wirkt auf die Moral.
6. **Einfach anfangen, später vertiefen:** Abteilungen (Anzahl × Qualität) und Gebäude sind in R3 noch feste Werte (Gebäudestufen 1–5 aus `TeamData`). Ausbau kommt mit R4 (HQ) und R6 (Finanzen). Motor bleibt bis R5 ein fester Wert pro Team.

---

## 1. Die 13 Teile

| # | Teil | Bereich | Hauptwirkung | Nebenwirkung / Zielkonflikt | Masse (kg) | Testart |
|---|---|---|---|---|---|---|
| 1 | Frontflügel | Aero | Abtrieb (vorne), Balance | Luftwiderstand; empfindlich bei Kontakt | 8 | CFD + Windkanal |
| 2 | Heckflügel | Aero | Abtrieb (hinten) / wenig Drag | stärkster Drag-Hebel; streckenspezifische Versionen | 7 | CFD + Windkanal |
| 3 | Unterboden | Aero | **größter Abtriebs-Anteil** | Reifenschonung (Stabilität); Schäden über Randsteine | 25 | CFD + Windkanal |
| 4 | Diffusor | Aero | Abtrieb (hinten) | Traktion, Reifenschonung hinten | 8 | CFD + Windkanal |
| 5 | Seitenkästen | Aero | Luftwiderstand, Kühlöffnungen | Kühlung ↔ Drag | 12 | CFD + Windkanal |
| 6 | Motorabdeckung | Aero | Luftwiderstand, Anströmung Heckflügel | Kühlung (Auslass) | 4 | CFD + Windkanal |
| 7 | Monocoque | Chassis | Steifigkeit ⇒ mech. Grip, Basis-Gewicht | **nur für die nächste Saison entwickelbar** (Crashtest, Homologation) | 45 | Prüfstand + Crashtest |
| 8 | Aufhängung vorne | Chassis | mech. Grip, Reifenschonung | Gewicht, Zuverlässigkeit | 18 | Prüfstand (7-Post-Rig) |
| 9 | Aufhängung hinten | Chassis | mech. Grip, Traktion, Reifenschonung | Gewicht, Zuverlässigkeit | 18 | Prüfstand (7-Post-Rig) |
| 10 | Bremsen | Chassis | Bremsleistung (langsame Kurven, Überholen) | Bremskühlung ↔ Drag; **Verschleißteil** | 14 | Prüfstand (Bremsdyno) |
| 11 | Getriebe | Antrieb | Zuverlässigkeit, Schaltzeit (Beschleunigung) | Gewicht; Laufleistung begrenzt | 40 | Prüfstand (Getriebe-Dyno) |
| 12 | Kühlung | Antrieb | Kühlleistung (Motor, Getriebe) | mehr Kühlung = mehr Drag | 15 | Prüfstand + CFD |
| 13 | Auspuff | Antrieb | etwas Motorleistung, Anströmung Diffusor | Hitze, Zuverlässigkeit | 8 | Prüfstand (Motor-Dyno) |

**Masse:** Teile zusammen ≈ 222 kg. Rest des Autos (Motor R5, Elektronik, Tank, Räder …) ist ein fester Block. Mindestgewicht wie in der F1 **798 kg** (mit Fahrer).

### 1.1 Werte eines Teils
Jede **Version** eines Teils hat:
- **Leistungswerte** (0–100) für die Werte, auf die es wirkt (siehe Gewichtungstabelle 2.1)
- **Masse** (kg)
- **Zuverlässigkeit** (0–100) und ggf. **Laufleistung** (Rennen bis zum Verschleiß)
- **Kühlung** (nur Kühlung, Seitenkästen, Motorabdeckung, Bremsen)
- **Spezifikation**: *Allround* oder *streckenspezifisch* (z. B. „Low-Downforce-Heckflügel“ für Monza/Las Vegas, „High-Downforce-Paket“ für Monaco/Singapur)
- **Name und Version**, z. B. „Frontflügel v4 – Monaco-Spec“

---

## 2. Vom Teil zum Auto

### 2.1 Gewichtung (Anteil jedes Teils am Autowert)

| Autowert | Teile (Anteil) |
|---|---|
| **Abtrieb** | Unterboden 30 % · Frontflügel 20 % · Heckflügel 20 % · Diffusor 15 % · Seitenkästen 8 % · Motorabdeckung 7 % |
| **Luftwiderstand (Effizienz)** | Heckflügel 30 % · Seitenkästen 20 % · Kühlung 15 % · Motorabdeckung 15 % · Frontflügel 10 % · Unterboden 10 % |
| **Mechanischer Grip** | Aufhängung vorne 32 % · Aufhängung hinten 32 % · Monocoque 18 % · Bremsen 10 % · Diffusor 8 % |
| **Reifenschonung** | Aufhängung hinten 25 % · Aufhängung vorne 20 % · Unterboden 20 % · Diffusor 15 % · Monocoque 10 % · Bremsen 10 % |
| **Bremsleistung** (neu) | Bremsen 70 % · Aufhängung vorne 20 % · Monocoque 10 % |
| **Traktion** (neu) | Aufhängung hinten 40 % · Diffusor 30 % · Getriebe 20 % · Auspuff 10 % |
| **Motorleistung** | Motor (fester Teamwert bis R5) + Auspuff (±2 Punkte) + Kühlung (Leistungsverlust bei Überhitzung, 2.3) |

Autowert = gewichteter Durchschnitt der Teilwerte. **Bremsleistung** und **Traktion** gehen in die Simulation ein: Bremsleistung in langsamen Kurven und Überholen beim Anbremsen, Traktion beim Kurvenausgang (bisher über mech. Grip abgedeckt – wird aufgeteilt).

### 2.2 Gewicht
- Masse des Autos = Teile + fester Block + Fahrer.
- **Über dem Mindestgewicht:** +0,03 s pro kg und 90-s-Runde (wie Sprit, `FUEL_S_PER_KG`). 10 kg ≈ 0,3 s ≈ 6 Autopunkte.
- **Unter dem Mindestgewicht:** Ballast bis 798 kg. Kein Zeitgewinn, aber **Ballast frei platzierbar** ⇒ kleiner Bonus auf mech. Grip (bis +1 Punkt) – darum lohnt Gewichtssparen auch bei Untergewicht ein bisschen.
- Startwelt: Topteams 0–3 kg über dem Limit, Hinterbänkler 6–14 kg.
- Gewicht sparen ist ein eigenes Projektziel (Abschnitt 5) und kostet meist etwas Zuverlässigkeit.

### 2.3 Kühlung
- **Kühlleistung** (0–100) aus Kühlung 55 % · Seitenkästen 30 % · Motorabdeckung 15 %.
- **Wärmebedarf** pro Rennen = 45 + (Streckentemperatur − 30 °C) × 0,8 + (Motorleistung − 60) × 0,3 + Verkehr (schmutzige Luft: +3 im Pulk).
- **Reserve** = Kühlleistung − Wärmebedarf.
  - Reserve < 0: **Leistungsverlust** (Motor wird gedrosselt): +0,015 s pro Punkt Defizit und Runde, und Defekt-Risiko für Motor/Getriebe ×(1 + Defizit/10).
  - Reserve > 15: unnötig viel Kühlung kostet Drag (bereits über Luftwiderstand der Kühlteile abgebildet).
- **Kühlöffnungen** wählt der **Renningenieur** selbst für jedes Rennen (keine Entscheidung des Spielers): eng = +0,8 Drag-Punkte, +5 Wärmebedarf; offen = −0,8 Drag-Punkte, −5 Wärmebedarf. Er wählt nach Streckentemperatur und Wettervorhersage – ein schwacher Ingenieur liegt öfter daneben. Die Wahl steht im Rennergebnis.

### 2.4 Zuverlässigkeit und Defekte pro Teil
Statt eines einzigen Defekt-Würfels pro Rennen hat **jedes Teil** sein Risiko:

```
Defekt-Chance pro Rennen (Teil) = Basis(Teil) × (1,5 − Zuverlässigkeit/100) × Personal-Faktor × Verschleiß-Faktor × Hitze-Faktor
```

| Teil | Basis pro Rennen | Defekt (tödlich / teilweise) |
|---|---|---|
| Getriebe | 1,2 % | Getriebeschaden / Gangprobleme |
| Kühlung | 0,6 % | Überhitzung ⇒ Motorschaden / Leistungsverlust |
| Bremsen | 0,5 % | Bremsversagen (Unfall) / Bremsprobleme |
| Aufhängung v/h | je 0,3 % | Aufhängungsbruch / Fahrverhalten |
| Auspuff | 0,3 % | — / Leistungsverlust |
| Monocoque (Hydraulik, Elektrik) | 0,8 % | Hydraulik-/Elektrikdefekt |
| Aero-Teile | je 0,1 % | Teile lösen sich (teilweise) |
| Motor (bis R5 fest) | 1,0 % | Motorschaden / Leistungsverlust |

Summe beim Durchschnittsauto ≈ 5 % pro Fahrer und Rennen (= heutiger Zielwert). **Verschleiß:** Getriebe hält 6 Rennen, danach steigt das Risiko je Rennen um 30 % (später mit R9: Kontingente und Startplatzstrafen). Bremsen sind Verbrauchsteile: **ein Satz pro Rennwochenende** und Auto.

---

## 3. Der Entwicklungsprozess (wie im echten Team)

```
1. Konzept       Technischer Direktor + Chefdesigner legen Ziel und Richtung fest
2. Design (CAD)  Designer zeichnen das Teil                         – Design-Kapazität
3. Simulation &  Aero: CFD-Läufe + Windkanal-Stunden                 – Aero-Testkapazität
   Test          Mechanik: Prüfstand (7-Post-Rig, Dyno, Crashtest)   – Prüfstand-Kapazität
   (Iteration)   ggf. weitere Runde: mehr Gewinn, mehr Zeit
4. Freigabe      Prognose steht fest; Entscheidung: fertigen oder verwerfen
5. Fertigung     Fabrik baut die Stückzahl (Ersatzteile!)            – Fertigungskapazität
6. Qualität      Prüfstand-Abnahme (optional, kostet Zeit, senkt Defekt-Risiko)
7. Auslieferung  Teil ist im Lager, kann zum nächsten Rennen mit
8. Korrelation   Erst auf der Strecke zeigt sich der echte Gewinn
```

### 3.1 Typische Dauer (Durchschnittsteam, ein Projekt allein)
| Teil | Konzept | Design | Test | Fertigung (je Stück) | gesamt bis zum Einsatz (2 Stück) |
|---|---|---|---|---|---|
| Frontflügel | 3 Tage | 20 | 10 | 4 | ~6 Wochen |
| Heckflügel | 3 | 16 | 8 | 3 | ~5 Wochen |
| Unterboden | 5 | 30 | 16 | 6 | ~8–9 Wochen |
| Diffusor | 3 | 20 | 10 | 3 | ~5–6 Wochen |
| Seitenkästen | 4 | 24 | 10 | 4 | ~6 Wochen |
| Motorabdeckung | 2 | 10 | 4 | 2 | ~3 Wochen |
| Monocoque | 10 | 75 | 25 (+Crashtest) | 20 | ~5 Monate (nur Nächstjahr) |
| Aufhängung v/h | 4 | 24 | 10 | 5 | ~6 Wochen |
| Bremsen | 3 | 14 | 8 | 2 | ~4 Wochen |
| Getriebe | 5 | 36 | 14 | 8 | ~9 Wochen |
| Kühlung | 3 | 16 | 8 | 3 | ~4–5 Wochen |
| Auspuff | 2 | 10 | 5 | 2 | ~3 Wochen |

(Tage = Arbeitstage bei Kapazität 1,0. Zwischen zwei Rennen liegen im Spiel ~12 Tage.)

### 3.2 Iteration
Nach dem Test kann man **eine weitere Runde** anhängen (+50 % Design- und Testzeit): Gewinn +25 %, Streuung −20 %. Oder **früh freigeben** (Test abkürzen): schneller, aber Streuung +40 % und Fehlschlag-Risiko +5 Punkte.

---

## 3a. Das Entwicklungslabor – Ideen, CFD, Windkanal, Strecke (Entscheidung 29.10.2026)

Ein Projekt ist kein „Starten und Warten“ mehr, sondern die echte Schleife eines F1-Teams. Der Spieler entscheidet an **Meilensteinen**, dazwischen arbeitet die Abteilung; Ergebnisse kommen per Inbox. Angezeigt wird in **Spielwerten** (0–100 je Autowert) plus Rundenzeit. An jedem Meilenstein: „Aero-Chef / Chassis-Chef entscheiden lassen“.

```
Basis       Das aktuelle Teil (z. B. Frontflügel v3) ist die Referenz: alle Werte = ±0.
1 Ideen     Konzeptphase (Design-Abteilung): das Team entwickelt 3–6 Ideen.
            Anzahl/Qualität: TD-Innovation, Chefdesigner-Kreativität, Kopfzahl Design.
            ▸ Meilenstein 1: bis zu N Ideen für die Simulation auswählen (N nach CFD-/Simulationskapazität)
2 CFD       Aero: CFD-Läufe · Mechanik: Simulation (Kinematik, FEM). Schnell, günstig, ungenau.
            Ergebnis je Idee: Δ-Werte mit Unsicherheit, z. B. Abtrieb +2,1 ±1,4 · Luftwiderstand −0,3 ±0,5
            ▸ Meilenstein 2: welche Ideen (oder Kombinationen) in den Windkanal / auf den Prüfstand
3 Windkanal Aero: Windkanal-Läufe (Modell 60 %) · Mechanik: Prüfstand (7-Post-Rig, Dyno).
  Prüfstand Genauer (Unsicherheit ≈ ⅓ von CFD), aber knapp: Läufe pro Woche nach Windkanal-Stufe.
            Kombinationen A+B: echte Wirkung = Summe × versteckter Wechselwirkungsfaktor (0,7–1,2).
            ▸ Meilenstein 3: **Verfeinern** (eine weitere Runde: +15 % Gewinn, abnehmend, Unsicherheit −20 %)
              · **Freigeben** (Design einfrieren) · **Verwerfen** (alles zurück, Kosten weg)
4 Detail-   Design-Abteilung zeichnet das freigegebene Teil fertig (Dauer nach Komplexität der Ideen).
  konstruktion
5 Werkzeuge Formen/Werkzeuge: feste Vorlaufzeit je Teil (Flügel 6 Tage, Unterboden 10, Getriebe 14 …).
6 Fertigung Stück für Stück; das erste Stück oft nur für ein Auto.
7 Qualität  Prüfstand-Abnahme.
8 Strecke   Training „Neue Teile testen“: alt gegen neu an beiden Autos (Back-to-Back), Flow-Vis, Aero-Rakes.
            Ergebnis: echter Gewinn. ▸ Meilenstein 4: **behalten** oder **zurück zur alten Version**.
            Jede Korrelation lehrt das Team: künftige Prognosen dieses Bereichs werden genauer (Erfahrung).
```

**Ideen** haben einen Namen je Teil (z. B. Frontflügel: „Zusätzliches Flap-Element“, „Überarbeitete Endplatte“, „Dünneres Hauptblatt“, „Outwash-Schlitz“, „Neuer Nasenübergang“), eine Richtung (Abtrieb, Drag, Balance/Reifen, Gewicht …), eine Komplexität (Zeit, Kosten) und eine **versteckte echte Wirkung** – manche sind gut, manche bringen nichts, manche sind Sackgassen (schlechter als die Basis). Gute Leute haben mehr gute Ideen und messen genauer.

**Kosten:** Konzept + CFD-Stunden + Windkanal-Läufe (je Lauf) + Detailkonstruktion + Werkzeuge + Stückkosten. Verwerfen spart den Rest.

**KI-Teams** durchlaufen dieselbe Schleife automatisch (wählen nach geschätztem Gewinn).

Ersetzt den bisherigen Ablauf „Projekt mit festem Ziel“ aus Abschnitt 3/5; Kapazität und Parallelität (Abschnitt 4) bleiben, CFD/Windkanal werden zu eigenen knappen Ressourcen (Stunden/Läufe pro Woche).

**Umsetzung (Stand 30.10.2026, `core/car_development.gd`, `ui/components/dev_lab_card.gd`):**
- Beim Start wählt man statt eines festen Ziels einen **Schwerpunkt** (wo das Designbüro zuerst sucht). Die Ideen werden beim Start gewürfelt (versteckt) und nach der Konzeptphase gezeigt: 3–6 Stück (Können + Konstrukteure), je Idee ≈ 55 % eines alten Ziel-Schritts × Zufall; Sackgassen-Chance 10 / 22 / 35 % (konservativ / normal / aggressiv), weniger mit gutem Chefdesigner (Detailarbeit).
- Eigene Abteilung **Windkanal** (Kapazität aus Aero-Chef, Windkanal-Stufe, Aero-Personal^0,3). CFD = Aero-Abteilung, Mechanik-Teile nutzen Simulation/Prüfstände.
- Pro Durchgang 3–5 Plätze (nach Aero-Kapazität). Arbeit: CFD 2 Tage, Windkanal 3,5 Tage je Variante. Kosten je Variante: CFD 40k (Aero) / 25k (Mechanik), Windkanal 110k / 60k. Konzept 15 % der Designkosten beim Start, Freigabe 45 % + Werkzeuge (2 × Stückkosten).
- Messfehler: CFD ≈ 0,35 + 1,5 × Korrelationsfehler (relativ), Windkanal = Korrelationsfehler × 0,8^Verfeinerungen; angezeigt als Balken mit ±.
- Werkzeugbau läuft in Kalendertagen (Überstunden ×1,4), unabhängig von der Auslastung.
- Meilensteine: Inbox-Nachricht mit Link ins Labor; Werkstatt-Spalte „Deine Entscheidung“. KI und delegiertes Spielerteam entscheiden sofort: Ideen nach Bauchgefühl (Rauschen kleiner mit gutem Personal), die besten zwei CFD-Varianten + ihre Kombination in den Windkanal, die beste Windkanal-Variante freigeben, sonst verwerfen.
- Strecke: nach dem Direktvergleich meldet die Korrelation das Ergebnis; „Zurück zu vX“ in der Übersicht verschrottet die neuen Stücke und fährt wieder die alte Version (Versionsnummern laufen weiter).
- Ergebnis im Test (volle Saison): reiche Teams 21–25 neue Teile, arme 8–11; einzelne Teile sind auf der Strecke langsamer (Sackgassen, Zuverlässigkeits-/Kühlungsrichtungen).

## 4. Kapazität und parallele Projekte

Vier Abteilungen arbeiten unabhängig – ein Projekt belegt immer nur die Abteilung seiner aktuellen Phase. So kann ein Teil gefertigt werden, während das nächste gezeichnet wird.

| Abteilung | Kapazität (Tage Arbeit pro Kalendertag) |
|---|---|
| **Design** | 1,0 × (0,6 × Chefdesigner.Design-Tempo + 0,4 × TD.Organisation) / 65 × (0,8 + 0,1 × Design-Büro-Stufe) |
| **Aero-Test** | 1,0 × Aero-Chef.Aero-Wissen / 65 × (0,7 + 0,1 × Windkanal-Stufe + 0,05 × CFD-Stufe) |
| **Prüfstand** | 1,0 × Chassis-Chef.Mech.-Wissen / 65 × (0,8 + 0,1 × Fabrik-Stufe) *(eigenes Testlabor ab R4)* |
| **Fertigung** | 1,0 × Fabrikleiter.Fertigungstempo / 65 × (0,8 + 0,1 × Fabrik-Stufe) |

Alle Kapazitäten × **Team-Produktivität** (Teamstimmung ±5 %, schon in R1 angekündigt).

**Personalstärke (Stand R3):** Jede Abteilung hat eine Kopfzahl (Durchschnitt: Design 60 · Aero 80 · Prüfstand 30 · Fabrik 120). Bis R4/R6 ergibt sie sich aus dem Budget (doppeltes Geld ≈ 1,7× Leute, jede Saison neu); Kapazität × (Kopfzahl / Durchschnitt)^0,75. **Mehr Geld, bessere Schlüsselpersonen und höhere Gebäudestufen = schnellere Entwicklung.**

**Abteilungsgröße:** Ein Durchschnittsteam schafft in Design 2,5 · Aero-Test 2,0 · Prüfstand 2,0 · Fertigung 3,0 Projekte gleichzeitig im normalen Tempo. **Ein einzelnes Projekt läuft nie schneller als sein normales Tempo** (1 Arbeitstag pro Tag, Eilauftrag 1,4) – Kapazität, die ein Projekt nicht nutzen kann, geht an die anderen.

**Mehrere Projekte in derselben Abteilung** teilen sich die Kapazität nach **Priorität** (niedrig 1 · normal 2 · hoch 3 Anteile). Dazu Reibungsverlust: Gesamtleistung × 1 / (1 + 0,08 × (n − 1)). Drei Projekte gleichzeitig im Design ⇒ jedes läuft gut dreimal so lange, das Team schafft insgesamt ~14 % weniger.

**Maximal gleichzeitige Projekte:** 2 + Design-Büro-Stufe (Stufe 1 ⇒ 3, Stufe 5 ⇒ 7).

**Überstunden (Eilauftrag):** Kapazität für ein Projekt ×1,4, Kosten ×1,5, Teamstimmung/Arbeitslast der Abteilung sinkt, Fehlerquote in der Fertigung +50 %.

---

## 5. Ein Projekt anlegen

| Einstellung | Optionen | Wirkung |
|---|---|---|
| **Teil** | 13 Teile | Monocoque nur fürs nächste Jahr |
| **Ziel** | je Teil 3–5 Ziele (unten) | welcher Wert steigt, welcher evtl. sinkt |
| **Spezifikation** | *(später)* Allround / Strecken-Spec (High-DF, Low-DF, Hitze) | **Kommt nach R3.** Strecken-Spec: +60 % Gewinn auf passenden Strecken, −40 % sonst; pro Rennen wählbar |
| **Ehrgeiz** | Konservativ / Normal / Aggressiv | Gewinn ×0,6 / ×1,0 / ×1,6 · Streuung ×0,6 / ×1,0 / ×1,5 · Fehlschlag 3 % / 10 % / 20 % · Zeit ×0,8 / ×1,0 / ×1,25 |
| **Priorität** | Niedrig / Normal / Hoch | Anteil an der Kapazität |
| **Stückzahl** | 1–6 | 2 = beide Autos, 3–4 = mit Ersatz |
| **Saison** | Dieses Jahr / Nächstes Jahr | siehe Abschnitt 10 |
| **Eilauftrag** | ja / nein | Abschnitt 4 |

**Ziele (Beispiele):**
- *Gewicht sparen*: −0,2 kg pro Gewinnpunkt (zählt nur über dem Mindestgewicht; laufende Gewichtsprojekte werden angerechnet)
- Flügel, Unterboden, Diffusor: *Mehr Abtrieb* (+Abtrieb, −30 % davon als Drag) · *Effizienz* (Abtrieb +60 %, ohne Drag-Nachteil) · *Weniger Luftwiderstand* (+Drag-Effizienz, −30 % davon Abtrieb) · *Gewicht sparen*
- Seitenkästen, Motorabdeckung: *Weniger Luftwiderstand* · *Mehr Kühlung* (+Kühlung, −Drag) · *Gewicht sparen*
- Aufhängung: *Mehr mech. Grip* · *Reifenschonung* · *Traktion* (hinten) · *Gewicht sparen* · *Zuverlässigkeit*
- Bremsen: *Bremsleistung* · *Kühlung* · *Gewicht sparen*
- Getriebe: *Zuverlässigkeit & Laufleistung* · *Schaltzeit (Traktion)* · *Gewicht sparen*
- Kühlung: *Mehr Kühlung* · *Kompakter (weniger Drag)* · *Zuverlässigkeit*
- Auspuff: *Leistung* · *Anströmung (Abtrieb Diffusor)* · *Zuverlässigkeit*
- Monocoque: *Steifigkeit (mech. Grip)* · *Gewicht sparen* · *Packaging (Aero-Bonus nächstes Jahr)*

**Vorschau vor dem Start** (jeder Wert mit Tooltip): Dauer je Phase, Kosten, erwarteter Gewinn mit Spanne, Fehlschlag-Risiko, Einschätzung des Technischen Direktors („Der Unterboden ist unsere größte Baustelle – hier liegt am meisten Zeit.“).

---

## 6. Ergebnis, Prognose und Korrelation

### 6.1 Echter Gewinn (verborgen)
```
Basisgewinn  = Teil-Basis (Punkte) × Können × Ehrgeiz × abnehmender Ertrag
Können       = Mittel aus TD.Innovation, Fachwissen (Aero-Chef.Aero-Wissen bzw. Chassis-Chef.Mech.-Wissen),
               Chefdesigner.Kreativität  ÷ 65
abnehmender  = (100 − aktueller Teilwert) / 40, begrenzt 0,25 … 1,5
Ertrag         (je besser das Teil schon ist, desto schwerer wird der nächste Schritt)
Echter Gewinn = Basisgewinn × (1 + N(0, Streuung))
Fehlschlag    = mit Fehlschlag-Risiko: Gewinn = −(0,2 … 0,8) × Basisgewinn
```
Teil-Basis (Punkte auf dem Teilwert, nach erstem Test ×1,8): Flügel 10,8 · Unterboden 14,4 · Diffusor 10,8 · Seitenkästen 9 · Motorabdeckung 5,4 · Aufhängung 9 · Bremsen 7,2 · Getriebe 7,2 · Kühlung 9 · Auspuff 5,4 · Monocoque 14,4.
**Zielgröße:** ein normales Update bringt **0,05–0,25 s** pro Runde.

### 6.2 Prognose (was das Team glaubt)
```
Prognose = echter Gewinn × (1 + N(0, Korrelations-Fehler))
Korrelations-Fehler Aero = 0,45 × (1 − Aero-Chef.Korrelation/100) × (1,3 − 0,1 × Windkanal-Stufe)
Korrelations-Fehler Mechanik = 0,30 × (1 − Chassis-Chef.Mech.-Wissen/100) × (1,2 − 0,05 × Fabrik-Stufe)
```
Angezeigt wird die Prognose mit Spanne. **Gute Korrelation:** Prognose ≈ Realität. **Schlechte:** Überraschungen in beide Richtungen – bis hin zum „Upgrade, das langsamer ist“.

### 6.3 Wann zeigt sich die Wahrheit?
- **Training „Neue Teile testen“** (neues Trainingsprogramm, Design-Dok. 8.4): nach dem Training ist der echte Gewinn bekannt (±10 %), und das Setup leidet nicht.
- Ohne Test im Training: Wert zeigt sich nach dem Rennen; ungetestete neue Teile kosten im ersten Rennen −3 % Setup.
- Danach: Entscheidung **behalten oder zurück zur alten Version** (alte Teile bleiben im Lager).

---

## 7. Fertigung, Lager, Ersatzteile, Schäden

- **Lager** pro Teil und Version: Stückzahl, Zustand (Laufleistung), welches Auto es trägt.
- **Fertigung:** Stück für Stück; Kosten je Stück (Abschnitt 9). **Qualitätsmängel:** Chance je Stück = 8 % × (1 − Fabrikleiter.Qualitätskontrolle/100) ⇒ Stück mit −15 Zuverlässigkeit; die Prüfstand-Abnahme findet sie zu 80 %.
- **Schäden im Rennen** (bestehende Kontakte/Unfälle der Simulation) zerstören Teile:
  - Kontakt: Frontflügel 60 % · Unterboden 20 % · Aufhängung vorne 15 % · Heckflügel 5 %
  - Unfall (Ausfall): Frontflügel sicher · Aufhängung vorne 50 % · Unterboden 30 % · Heckflügel/Diffusor 25 % · **Monocoque 15 %** (teuer!)
  - Ausritt über Randsteine: Unterboden-Schaden (teilweise reparierbar)
- **Kein Ersatz?** Dann fährt das Auto die **ältere Version** aus dem Lager (Werte sinken sichtbar). Ohne irgendeine Version: Eilfertigung vor dem nächsten Rennen (×2 Kosten) oder das Auto startet nicht.
- **Reparaturkosten** zählen als Kosten (Abschnitt 9).

---

## 8. Teile verteilen – wer bekommt das neue Teil?

- Vor jedem Rennwochenende (Weekend-Hub, neuer Block „Teile“): welches Auto fährt welche Version. **Empfehlung** des Technischen Direktors (Nr.-1-Status, WM-Stand).
- **Moral:** Nr.-1-Fahrer erwartet neue Teile zuerst (sonst −3). Gleichberechtigte Fahrer: der benachteiligte −2. Ein Versprechen „Gleichbehandlung“ (aus dem 1:1-Gespräch) wird hier **geprüft** – das schließt eine offene Lücke aus R2.
- **Strecken-Spec:** pro Rennen wählbar (z. B. Low-DF-Heckflügel für Monza).

---

## 9. Kosten

Erste Größenordnung (wird in R6 mit allen Finanzen verfeinert). Ziel: ein Mittelfeldteam gibt **40–60 Mio. $ pro Saison** für das Auto aus, ein Topteam 80–120 Mio. $.

| Teil | Entwicklung (pro Projekt) | Fertigung (pro Stück) |
|---|---|---|
| Frontflügel | 0,8 Mio. | 120 000 |
| Heckflügel | 0,7 Mio. | 90 000 |
| Unterboden | 1,5 Mio. | 250 000 |
| Diffusor | 0,8 Mio. | 100 000 |
| Seitenkästen | 1,0 Mio. | 150 000 |
| Motorabdeckung | 0,4 Mio. | 40 000 |
| Monocoque | 4,0 Mio. | 1 200 000 |
| Aufhängung v/h | je 1,0 Mio. | 180 000 |
| Bremsen | 0,6 Mio. | 60 000 (Verbrauch: 1 Satz/Auto/Rennen) |
| Getriebe | 2,0 Mio. | 400 000 |
| Kühlung | 0,6 Mio. | 80 000 |
| Auspuff | 0,4 Mio. | 30 000 |

Faktoren: Ehrgeiz Aggressiv ×1,3 · Eilauftrag ×1,5 · Iteration +50 % · Strecken-Spec ×0,8 · Fabrikleiter.Kostenkontrolle −0…15 %.
**Budget:** Kosten werden sofort beim Start (Entwicklung) bzw. pro Stück abgebucht. **Reicht das Budget nicht, kann kein Projekt gestartet und kein Teil gefertigt werden** (der Knopf ist gesperrt, mit Grund). Alles Weitere zu Geld (Besitzer-Vorgaben, Haushalt, Budget Cap) kommt mit R6/R9.

---

## 10. Das Auto fürs nächste Jahr

- **Ressourcen-Aufteilung** (Schieberegler, Technischer Direktor empfiehlt): Anteil der Kapazität, der ins Nächstjahresauto fließt. Typisch: 0 % bis Juni, 30–50 % ab Sommerpause, 70–100 % wenn die Saison gelaufen ist.
- Projekte mit „Nächstes Jahr“ landen im **Konzept des neuen Autos** (z. B. Monocoque, neuer Unterboden).
- **Saisonwechsel** (ersetzt die Platzhalter-Regel aus R2):
  ```
  neuer Teilwert = 50 + Übernahme × (alter Teilwert − 50) + Nächstjahres-Entwicklung (Teil)
  Übernahme      = 0,75 (ohne Regeländerung; R9: betroffene Teile 0,2)
  ```
  Damit holen alle Teams etwas auf (Annäherung ans Mittel), wer früh und gut am neuen Auto arbeitet, startet besser.
- Laufleistung, Lager und Strecken-Specs beginnen neu.

---

## 11. KI-Teams

Gleiche Regeln, Entscheidungen trifft der Technische Direktor:
- hält die Kapazität ausgelastet (Projekte = maximal möglich − 1),
- wählt Teile mit dem besten **erwarteten Gewinn × Bedeutung für die restlichen Strecken**,
- Ehrgeiz nach Lage: Hinterbänkler und Titelkandidaten aggressiver, Mittelfeld normal,
- fertigt 3–4 Stück, verteilt an Nr. 1 zuerst,
- verschiebt ab Juli Kapazität ins nächste Jahr (früher, wenn die Saison verloren ist),
- Ausgaben nach Budget (reiche Teams mehr Projekte und Eilaufträge).

Der Spieler kann die Planung **an den Technischen Direktor delegieren** (Design-Dok. 5.4) – dann gelten dieselben Regeln für das eigene Team.

---

## 12. Wer wirkt worauf? (Personal und Gebäude)

| Wer / was | Wirkung |
|---|---|
| Technischer Direktor | Innovation (Gewinn), Organisation (Design-Kapazität), Aero-/Mech.-Wissen (Gewinn), Empfehlungen, delegierte Planung |
| Chefdesigner | Design-Tempo (Kapazität), Kreativität (Gewinn), Detailarbeit (weniger Fehlschläge −30 %) |
| Aero-Chef | Aero-Wissen (Gewinn, Test-Kapazität), Korrelation (Prognose-Genauigkeit), Innovation |
| Chassis-Chef | Mech. Wissen (Gewinn, Prüfstand), Gewichtssparen (Gewichtsziel ×), Zuverlässigkeit (neue Teile) |
| Fabrikleiter | Fertigungstempo, Qualitätskontrolle (Mängel), Kostenkontrolle |
| Motorenchef | Auspuff-Projekte, Kühlung (Wärmebedarf), Motor bleibt bis R5 fest |
| Renningenieur + Fahrer | Technisches Feedback ⇒ schnellere Korrelation, Strecken-Specs richtig einsetzen |
| Design-Büro (Stufe) | Design-Kapazität, max. parallele Projekte |
| Windkanal / CFD (Stufe) | Aero-Test-Kapazität, Korrelation |
| Fabrik (Stufe) | Fertigung, Prüfstand (bis R4 ein eigenes Testlabor kommt) |
| Teamstimmung | ±5 % auf alle Kapazitäten |

---

## 13. Bildschirme (Menü „Fahrzeugentwicklung“)

1. **Übersicht:** Auto von oben (Platzhalter-Grafik) mit den 13 Teilen als anklickbare Zonen, eingefärbt nach Qualität im Feldvergleich. Daneben die Autowerte (Abtrieb, Drag, mech. Grip, Bremsen, Traktion, Reifenschonung, Kühlung, Gewicht in kg, Zuverlässigkeit) mit Rang im Feld und Verlauf über die Saison. Pro Auto: welche Version ist montiert.
2. **Teil-Detail:** alle Versionen mit Werten, Lagerbestand, Zustand, Geschichte (wann entwickelt, Prognose vs. Realität). Knopf „Neues Projekt“.
3. **Neues Projekt:** Teil, Ziel, Spezifikation, Ehrgeiz, Priorität, Stückzahl, Saison, Eilauftrag – mit Live-Vorschau (Dauer, Kosten, Gewinn-Spanne, Risiko, Kommentar des TD).
4. **Projekte (Werkstatt-Board):** Spalten Konzept · Design · Test · Fertigung · Qualität · Bereit, jedes Projekt als Karte mit Fortschritt und voraussichtlichem Datum. Oben die Auslastung der vier Abteilungen.
5. **Lager & Fertigung:** alle Teile und Versionen, Stückzahl, Zustand, Fertigungs-Warteschlange (Nachbestellen von Ersatzteilen).
6. **Nächstes Jahr:** Ressourcen-Regler, Konzept-Projekte, Prognose für das neue Auto.
7. **Rennwochenende:** neuer Block „Teile“ (welches Auto welche Version / Strecken-Spec), Trainingsprogramm „Neue Teile testen“, Ergebnis der Korrelation nach dem Training.

**Grafiken (Platzhalter):** bis die zweite Person Grafiken liefert, erzeuge ich einfache SVG-Platzhalter mit festen Dateinamen – sie werden später nur ersetzt:
- `assets/car/car_top.svg` (Auto von oben, 13 Zonen mit festen Koordinaten in `ui/car_layout.gd`)
- `assets/parts/<teil>.svg` für jedes Teil (front_wing, rear_wing, floor, diffuser, sidepods, engine_cover, monocoque, suspension_front, suspension_rear, brakes, gearbox, cooling, exhaust)

---

## 14. Zielwerte fürs Sim-Labor

| Messgröße | Ziel |
|---|---|
| Entwicklung eines Durchschnittsteams in einer Saison | +0,6 … 1,0 s gegenüber dem Saisonstart |
| Bestes vs. schlechtestes Technik-Personal | ±0,4 s Unterschied pro Saison |
| Team ohne Entwicklung | verliert ~0,7 s auf den Schnitt über die Saison |
| Normales Update | 0,05 … 0,25 s |
| Fehlschläge (schlechter als vorher) | 8 … 12 % der Projekte |
| Prognosefehler gutes / schwaches Team | ±10 % / ±40 % |
| Ausgaben Mittelfeld / Topteam pro Saison | 40–60 / 80–120 Mio. $ |
| Defekte pro Fahrer und Rennen | weiterhin ~5 % (Summe der Teile) |
| Wechsel an der Spitze über 5 Saisons | mindestens 2 verschiedene Konstrukteursmeister |

---

## 15. Umsetzung in Schritten

| Schritt | Inhalt | spielbar danach |
|---|---|---|
| **R3a** | Teilemodell (13 Teile, Versionen, Lager), Auto aus Teilen berechnet, Gewicht + Kühlung + Defekte pro Teil in der Simulation, KI-Entwicklung, Kosten, Übersichts-Bildschirm mit Platzhalter-Grafik | Autos entwickeln sich während der Saison, Budget wird ausgegeben |
| **R3b** | Eigene Projekte: Neues-Projekt-Dialog, Werkstatt-Board, Kapazität & Parallelität, Prognose & Korrelation, Delegieren an den TD | Spieler entwickelt selbst |
| **R3c** | Fertigung, Ersatzteile, Schäden zerstören Teile, Teileverteilung pro Auto + Moral + Versprechen, Training „Neue Teile testen“ | volle Rennwochenend-Integration |
| **R3d** | Nächstjahresauto (Regler, Konzept-Projekte, Monocoque), neuer Saisonwechsel; Sim-Labor-Szenarien für Entwicklung; Saisonbilanz um Entwicklung erweitert | mehrere Saisons mit echter Entwicklung |

## 16. Entscheidungen (27.10.2026)
- Alle 13 Teile; Gewicht und Kühlung detailliert in der Simulation.
- Geld ab R3: kein Budget ⇒ keine Projekte und keine Fertigung. Mehr zu Finanzen in R6.
- KI-Teams entwickeln nach denselben Regeln.
- Abteilungen und Gebäude vorerst einfach (feste Stufen), Ausbau in R4/R6.
- Kühlöffnungen entscheidet der Renningenieur.
- Strecken-Specs kommen **nach R3**.
- Eigene Projekte über den Dialog „Neues Projekt“; Delegieren an den Technischen Direktor ist abschaltbar (an = er füllt freie Plätze und setzt den Nächstjahres-Anteil).
- Mehr Geld ⇒ mehr Personal in den Abteilungen ⇒ schnellere Entwicklung; dazu Qualität der Schlüsselpersonen und Gebäudestufen (Entscheidung 29.10.2026).
- Platzhalter-Grafiken: Auto von oben + 13 Teile-Symbole, feste Dateinamen.

## 17. Ausbau der Entwicklung – Ideen für später (Entscheidung 30.10.2026)

Alle Ideen sind gewollt. Reihenfolge und Runde stehen dabei; erledigt wird abgehakt im Backlog (`docs/backlog.md`, Abschnitt „Ausbau der Entwicklung“).

### Nötig, damit das Labor rund ist (Vorschlag: als Nächstes, „R3e“, nach dem Playtest)

**17.1 Track-Test als echter Moment.** Bisher: Korrelations-Nachricht + Knopf „Zurück zu vX“. Neu:
- Training mit Programm „Neue Teile testen“ wird ein Direktvergleich: Auto 1 alt, Auto 2 neu (oder ein Auto im Wechsel). Ergebnis-Bildschirm mit Rundenzeit- und Sektor-Unterschied, Flow-Vis / Aero-Rakes als Bild-Platzhalter, Vertrauen in das Ergebnis.
- Danach Entscheidung **„Behalten“ oder „Zurück zur alten Version“** (Meilenstein 4, auch über „Aero-Chef entscheiden lassen“).
- **Technisches Feedback des Fahrers** (Fahrer-Attribut) bestimmt, wie klar das Ergebnis ist: guter Testfahrer = kleines ±, schlechter = Rauschen. Regen und Verkehr machen den Test ungenauer.
- Ohne Test: der echte Effekt zeigt sich erst nach dem Rennen (wie jetzt).

**17.2 Die Gegner sichtbar machen – das Entwicklungsrennen.**
- Fahrerlager-News in der Inbox: „Aurora bringt einen neuen Unterboden nach R12“, „Meridian mit großem Update-Paket“. Genauigkeit nach Scouting-/Technik-Personal (Wissensmodell).
- **Entwicklungs-Grafik**: Rundenzeit-Gewinn pro Team über die Saison (eigene Linie exakt, Gegner geschätzt).
- Rangliste „Wer entwickelt am schnellsten?“ in der Übersicht der Fahrzeugentwicklung.
- Ziel: Druck – „die holen auf, ich muss reagieren“.

**17.3 Korrelationsprobleme als Geschichte.**
- Liegen Windkanal und Strecke mehrmals daneben (gleiche Richtung), meldet der Aero-Chef ein **Korrelationsproblem**: alle Prognosen dieses Bereichs sind verschoben, nicht nur ungenau.
- Gegenmittel: **Projekt „Windkanal-Korrelation“** (kostet Zeit, Windkanal-Kapazität und Geld, bringt kein Teil) – danach sind die Prognosen wieder richtig und genauer.
- Vorbild: Ferrari / McLaren, deren Windkanal jahrelang „gelogen“ hat.

### Damit die Richtung zählt (nach R3, mit den Strecken-Specs)

**17.4 Streckencharakter.** Strecken bekommen Profile (viel Abtrieb wie Monaco, wenig Luftwiderstand wie Monza, Mischung, Bremsen-/Traktions-Strecken, heiß/kalt für die Kühlung). Dann ist der Schwerpunkt eine echte Entscheidung: „Abtrieb für die nächsten drei Strecken oder Effizienz für die zweite Saisonhälfte?“ Später: streckenspezifische Teile (Monza-Heckflügel, Monaco-Paket) – war schon als „später“ vereinbart.

### Macht es spannender

**17.5 Ideen haben einen Kopf (mit R4 Personal/HQ).** Jede Idee nennt ihren Urheber („Idee von Charlie Carter, Aero-Chef“). Verlässt die Person das Team, nimmt sie Wissen mit: der neue Arbeitgeber bekommt passende Ideen, das eigene Team verliert Ideen-Qualität in dem Bereich. Ein Star-Designer bringt eigene Ideen-Listen mit.

**17.6 Risiko-Abkürzungen.** Qualitätsprüfung überspringen → Teil ein Rennen früher, aber höhere Ausfallchance. Ähnlich: nur ein Stück bauen und sofort einsetzen, Werkzeuge im Eilverfahren (teurer).

**17.7 Update-Pakete.** Mehrere Teile (z. B. Unterboden + Diffusor + Seitenkästen) als **Paket** für ein bestimmtes Rennen planen. Teile, die zusammen entwickelt werden, bekommen einen Bonus (Zusammenspiel), sind auf der Strecke aber schwerer zu bewerten – man weiß nicht, welches Teil was bringt. Ein Paket, das nicht rechtzeitig fertig ist, kommt geschlossen später.

**17.8 Kopieren.** Fotos aus der Boxengasse / Startaufstellung zeigen Teile der Gegner. Daraus wird eine **neue Idee** im nächsten Projekt („Aurora-Unterbodenkante“): gute Wirkung, wenn das Konzept zum eigenen Auto passt, sonst wenig. Kosten: Fotograf / Analyse-Personal.

### Große Hebel (spätere Runden)

**17.9 Fahrzeugkonzept fürs nächste Jahr.** Einmal pro Jahr die große Entscheidung (z. B. Seitenkasten-Konzept, Fahrhöhe, Aufhängungsprinzip). Das Konzept setzt die **Obergrenze** der Entwicklung für das ganze Jahr. Falsches Konzept = Sackgasse für eine Saison (Vorbild: Mercedes-„Zeropod“ 2022). Konzeptwechsel während der Saison möglich, aber teuer und es kostet die bisherige Entwicklung. Vorschlag: nach R3e, spätestens mit R9.

**17.10 Regeln: Budget Cap und Windkanal-Zeit nach WM-Platz (R9 Regulierung, Finanzen mit R6).**
- Budget Cap: Obergrenze für Entwicklungs- und Fertigungskosten; mehr Geld hilft dann nur noch bis zur Grenze (Gebäude/Personal außerhalb, wie in der echten F1).
- ATR (Aero Testing Restrictions): Windkanal- und CFD-Stunden pro Halbjahr nach Konstrukteurs-Platz (Weltmeister weniger, Letzter mehr). Hält das Feld zusammen.

**17.11 Regeländerungsjahre (R9).** Große Regeländerung: betroffene Teile werden zurückgesetzt, Nächstjahres-Anteil wird plötzlich entscheidend; wer früh umschaltet, startet vorne (siehe Spieldesign 8.3).
