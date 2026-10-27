# Motormodell & Motorentwicklung (R5)

> Ziel: Der Motor (Power Unit) ist ein eigenes, tiefes System – Hersteller, Verträge, fünf Komponenten, Motoreinheiten mit Laufleistung, Modi am Rennwochenende und ein eigenes Motoren-Labor. **Jede Zahl ist erklärbar**, alles läuft für KI-Teams und KI-Hersteller nach denselben Regeln.
> Verwandt: Design-Dokument Kapitel 9, `docs/car_model.md` (Auto, Labor), `docs/hq_screen_design.md` (Motorenwerk), Personal-Rolle Motorenchef (`core/staff_roles.gd`).
> Alle Zahlen sind **Startwerte**; Feinabstimmung kommt mit dem Playtest. Strafen und Kontingent-Regeln kommen mit **R9 (Regulierung)**.

Entscheidungen (31.10.2026): 4 erfundene Hersteller · volle Tiefe schon in R5 · eigenes Motoren-Labor · Spieler startet als Kunde eines Werksteams, eigener Hersteller ist ein Langzeitziel · Motoreinheiten und Laufleistung in R5 (Strafen R9) · Motor-Modi und neue Schlüsselmomente.

---

## 0. Grundprinzipien

1. **Der Motor ist die Summe seiner Komponenten.** Fünf Komponenten ergeben fünf Motorwerte; die Simulation liest diese Werte (bisher nur ein fester Wert „Motorleistung“ pro Team).
2. **Werte sind relativ** (0–100, 50 = Durchschnitt zu Saisonbeginn), wie bei den Autowerten.
3. **Wer den Motor baut, bestimmt.** Kunden bekommen, was der Hersteller liefert – Updates kommen zuerst zum Werksteam. Eigene Entwicklung braucht Lizenz oder eigenes Werk.
4. **Ein Motor ist ein Bauteil mit Laufleistung.** Jede Einheit verschleißt; wann man eine frische einsetzt, ist eine Entscheidung.
5. **Mehr Leistung kostet etwas:** Haltbarkeit, Hitze, Sprit oder Geld.

---

## 1. Hersteller (Startwelt)

| Hersteller | Werksteam | Charakter | Kunden zu Beginn |
|---|---|---|---|
| **Corsa Alta Motori** | Scuderia Corsa Alta | stärkste Leistung, Zuverlässigkeit unterdurchschnittlich | Halcyon, Tundra |
| **Aurum Powertrains** | Aurum Motorsport | stark und ausgewogen, sehr teuer | Kestrel |
| **Meridian High Performance** | Meridian F1 Team | beste Effizienz und Zuverlässigkeit | **Vortex (Spieler)**, Nordline, Brightwater |
| **Valkyr Power Systems** | – (unabhängig) | etwas schwächer, gute Fahrbarkeit, günstig, behandelt alle Kunden gleich | Solace, Ironbridge |

- Höchstens **4 Teams pro Hersteller** (inkl. Werksteam) – Kapazität der Fertigung.
- Hersteller haben eigenes Motoren-Personal (Werksteam: dessen Motorenchef + Motorenwerk; Valkyr: feste Werte) und entwickeln über die Saison (Abschnitt 6).
- Kunden fahren **dieselbe Spezifikation**, bekommen neue Specs aber **1–3 Rennen später** als das Werksteam (Fertigungsreihenfolge).
- Werksteam-Vorteil: **Integration** – Auto und Motor passen zusammen (+2 Kühlung, −2 kg Einbaugewicht). Kunden: 0; im ersten Jahr nach einem Wechsel: −3 Kühlung, +3 kg (Auto muss angepasst werden).

---

## 2. Die Power Unit: 5 Komponenten → 5 Motorwerte

| Komponente | Leistung | Effizienz | Zuverlässigkeit | Gewicht | Fahrbarkeit |
|---|---|---|---|---|---|
| Verbrennungsmotor (ICE) | 45 % | 35 % | 30 % | 35 % | 25 % |
| Turbolader | 25 % | 15 % | 15 % | 10 % | 25 % |
| Energierückgewinnung (ERS, MGU-K/H) | 20 % | 25 % | 20 % | 20 % | 10 % |
| Batterie (Energiespeicher) | 10 % | 10 % | 15 % | 30 % | 10 % |
| Steuerelektronik | – | 15 % | 20 % | 5 % | 30 % |

Jede Komponente hat Werte 0–100 für die Motorwerte, auf die sie wirkt (wie die Autoteile). Der Motorwert ist der gewichtete Durchschnitt.

**Was die Motorwerte in der Simulation bewirken:**

| Motorwert | Wirkung |
|---|---|
| **Leistung** | wie bisher `engine_power` (Gerade, Überholen) + Auspuff-Bonus aus R3 |
| **Effizienz** | Spritverbrauch ×(1,15 − 0,3 · Effizienz/100) → weniger Startgewicht; Spritsparen kostet weniger Zeit |
| **Zuverlässigkeit** | Motorschaden-Chance ×(1,6 − Zuverlässigkeit/100) × Verschleiß der Einheit |
| **Gewicht** | Masse der Power Unit 140–165 kg (50 = 152 kg) im festen Block des Autos (798-kg-Modell aus R3) |
| **Fahrbarkeit** | Traktion +(Fahrbarkeit − 50) × 0,1, Reifenverschleiß hinten, weniger Fahrfehler bei Regen |

**Hitze:** Leistung erhöht den Wärmebedarf weiter wie in R3 (`COOLING_PER_POWER`); Modus „Push“ zusätzlich +4.

---

## 3. Motorverträge

| Modell | Kosten (Startwerte) | Was man bekommt | Voraussetzung |
|---|---|---|---|
| **Kundenmotor** | $14–22M pro Jahr je nach Hersteller | Motor + Einheiten (4 pro Auto und Saison) + Updates des Herstellers | Platz beim Hersteller |
| **Lizenzmotor mit Entwicklungsrechten** | $30–40M pro Jahr + eigene Entwicklung | Basis-Motor des Herstellers, **eigene Specs nur fürs eigene Team**; keine Updates vom Hersteller | Motorenwerk ≥ 1, Motorenchef |
| **Werksmotor** | Programm ≈ $150M über 2 Saisons, danach Entwicklung + Fertigung | eigener Motor, volle Kontrolle, **Verkauf an Kunden** ($14–22M pro Kunde und Jahr, Betreuung kostet) | Motorenwerk ≥ 3, Motorenabteilung |

- Laufzeit 1–3 Jahre. **Verhandlungsfenster:** 1. Juli bis Saisonende (Inbox: „Ihr Motorvertrag läuft aus“).
- Der Hersteller entscheidet nach **Kapazität** (max. 4 Teams), **Ruf/WM-Platz** des Teams und **Preis**. Werksteams nehmen ungern direkte Rivalen.
- Vorzeitiger Ausstieg: Restlaufzeit × 50 % als Ablöse.
- **Eigener Hersteller werden** (Langzeitziel): Projekt „Power-Unit-Programm“ im Motoren-Labor, alle 5 Komponenten von Grund auf (Abschnitt 5), Dauer ~1,5–2 Saisons; der erste eigene Motor ersetzt zur nächsten Saison den Kundenmotor.
- KI-Teams wählen nach denselben Regeln (bestes Paket für ihr Budget).

---

## 4. Motoreinheiten & Laufleistung

- Pro Auto und Saison **4 Einheiten** im Vertrag (mehr kosten $1,5M pro Stück; **Startplatzstrafen erst mit R9**).
- Jede Einheit hat eine **Spec** (die beim Bau aktuelle Version) und eine **Laufleistung** in km.
- **Lebensdauer** nach Zuverlässigkeit: 3 500 km (Zuverlässigkeit 20) bis 5 200 km (Zuverlässigkeit 90) – etwa 5–7 Wochenenden. Ein Rennwochenende ≈ 700 km auf der Einheit (Training 250, Qualifying-Runden mit Verschleiß ×4, Rennen × Modus). 4 Einheiten reichen für eine Saison knapp; schwache Motoren brauchen zusätzliche.
- **Verschleiß:** ab 70 % der Lebensdauer −0,5 Leistung je 10 % (bis −2), Ausfallrisiko ×1 → ×2,5 bei 100 %, darüber steil.
- **Pool:** Einheiten sind pro Fahrer; gebrauchte Einheiten können im Training wieder eingesetzt werden („Freitags-Motor“).
- **Entscheidung im Wochenend-Block „Motor“:** welche Einheit (neu / gebraucht), Empfehlung des Motorenchefs (z. B. „neue Einheit in Monteverde – lange Gerade“). Eine neue Spec kommt nur mit neuen Einheiten ins Auto.
- Defekt im Rennen: die Einheit ist ganz oder teilweise beschädigt (Schaden 30–100 %).

---

## 5. Das Motoren-Labor (nur Lizenz- oder Werksmotor)

Anders als beim Auto ist der Prüfstand das Herz: **Leistung messen ist leicht, Haltbarkeit herausfinden kostet Zeit.**

```
Basis       Die aktuelle Spec der Komponente (z. B. Turbolader Spec 2) – alle Werte ±0.
1 Konzept   Motorenkonstruktion: 3–5 Ideen pro Komponente (z. B. Turbo: „Größere Verdichterstufe“,
            „Neue Lagerung“, „Leichteres Gehäuse“, „Elektrisches Anfahren“, „Wärmedämmung“).
            ▸ Meilenstein 1: Ideen für den Einzylinder-/Komponenten-Prüfstand wählen
2 Einzel-   Einzylinder-Motor bzw. Komponenten-Prüfstand: schnell, misst Leistung/Effizienz grob (±).
  prüfstand ▸ Meilenstein 2: welche Varianten auf den Vollmotor-Prüfstand
3 Leistungs- Vollmotor-Dyno: Leistung, Effizienz, Fahrbarkeit genau (±klein).
  lauf
4 Dauerlauf Dyno-Dauerlauf: X Renndistanzen simulieren → **Zuverlässigkeit** wird sichtbar.
            Kurz (1 Renndistanz, ±groß) · Mittel (3, ±mittel) · Lang (6, ±klein, kostet Zeit).
            Ausfälle im Dauerlauf zeigen Schwächen: „Lager versagt nach 1 400 km“.
            ▸ Meilenstein 3: **Entschärfen** (−Leistung, +Zuverlässigkeit, eine Runde) · **Freigeben** ·
              **Verwerfen** · weiterer Dauerlauf
5 Homologation & Produktion: neue Spec, Fertigung der Einheiten im Motorenwerk (Vorlauf je Komponente
            20–40 Tage). Werksteam bekommt sie zuerst, Kunden später.
6 Strecke   Erste Rennen mit der neuen Spec; Korrelation Dyno ↔ Strecke (Leistung meist genau,
            Zuverlässigkeit zeigt sich erst mit Kilometern).
```

- **Abteilungen:** Motorenkonstruktion (Motoreningenieure), Prüfstände (Einzylinder + Dyno, Kapazität aus Motorenwerk-Stufe), Motorenfertigung. Personalstärke wie in R3 aus dem Budget, begrenzt durch den Platz im Motorenwerk.
- **Können:** Motorenchef (Leistungsentwicklung → Ideen für Leistung, Effizienz → Effizienz-Ideen, Zuverlässigkeitsfokus → genauere Dauerläufe, weniger Sackgassen), Technischer Direktor, Motorenwerk-Stufe.
- **Spec-Regel (vor R9 frei):** höchstens **3 neue Specs pro Komponente und Saison** (Fertigung); ab R9 Entwicklungseinfrierung/Token.
- **Zielkonflikt** wie in echt: aggressive Leistungsideen haben öfter Haltbarkeitsprobleme; Dauerläufe finden sie, kosten aber Wochen.
- KI-Hersteller durchlaufen dieselbe Schleife automatisch (1–3 Specs pro Saison je nach Stärke).

---

## 6. Hersteller-Updates (Kundenmotor)

- Jeder Hersteller plant 1–3 Updates pro Saison (Inbox: „Meridian bringt Spec 2 zum R9 – Kunden ab R11“).
- Der Spieler als Kunde entscheidet nur, **wann** er die neue Spec einsetzt (neue Einheit = neue Spec, kostet eine Einheit aus dem Pool).
- Beziehung zum Hersteller (0–100): gute Ergebnisse, pünktliche Zahlung, keine öffentliche Kritik → frühere Lieferung; schlechte → spätere Lieferung, schlechtere Verlängerung.

---

## 7. Rennwochenende

**Block „Motor“ in der Planung** (neben „Teile“): Einheit pro Auto (neu/gebraucht, Laufleistung, Spec), Empfehlung.

**Motor-Modi** (Strategie-Bildschirm, pro Fahrer, vom Renningenieur empfohlen):

| Modus | Leistung | Verschleiß | Hitze | Sprit |
|---|---|---|---|---|
| Qualifying (nur Quali, eine Runde) | +3 | ×4 | +6 | – |
| Push | +1,5 | ×1,6 | +4 | +4 % |
| Normal | 0 | ×1 | 0 | 0 |
| Schonen | −1,5 | ×0,7 | −4 | −4 % |

**Neue Schlüsselmomente:**
- *„Motortemperatur steigt“* – Modus runter (Zeitverlust) oder weiter pushen (Risiko).
- *„ERS-Fehler: Leistungsverlust“* – Reset über das Lenkrad versuchen (Chance nach Fahrer/Ingenieur) oder an die Box zur Reparatur.
- *„Motor klingt nicht gut“ (Training)* – Einheit wechseln (kostet eine Einheit) oder riskieren.
- *„Sprit wird knapp“* – Lift & Coast (Zeitverlust je Runde) oder Risiko, vor dem Ziel stehen zu bleiben.

---

## 8. Personal & Gebäude

| Wer/was | Wirkung |
|---|---|
| Motorenchef | Ideen/Specs (Leistung, Effizienz, Zuverlässigkeit), Empfehlungen Einheit/Modus, Verhandlungen mit dem Hersteller |
| Motorenwerk (HQ, ab R5 frei) | Stufe 1: Lizenz möglich, kleiner Prüfstand · Stufe 3: Werksmotor möglich · Prüfstand-Kapazität ×(0,6 + 0,2·Stufe), Dauerlauf-Genauigkeit, Platz für Motoreningenieure |
| Motoreningenieure (Abteilung) | Kapazität Motorenkonstruktion, Kopfzahl aus Budget, begrenzt durch Motorenwerk |
| Renningenieur | Modus-Empfehlung, Reaktion auf Schlüsselmomente |
| Fahrer | Spritsparen, Umgang mit Fahrbarkeit (Regen) |

---

## 9. Kosten (Startwerte)

| Posten | Kosten |
|---|---|
| Kundenmotor | Corsa Alta $22M · Aurum $21M · Meridian $18M · Valkyr $14M pro Jahr |
| Zusätzliche Einheit | $1,5M |
| Lizenz | Hersteller-Preis × 1,8 |
| Motoren-Labor | je Idee/Prüfstand/Dauerlauf wie beim Auto-Labor, Dauerlauf $0,3M je Renndistanz |
| Power-Unit-Programm (eigener Hersteller) | ≈ $150M über ~2 Saisons |
| Kunden beliefern (als Hersteller) | +Preis pro Kunde, −$4M Betreuung pro Kunde |

---

## 10. Bildschirme (Menü „Motor“)

1. **Übersicht:** Power Unit als Grafik mit 5 Komponenten (anklickbar, Rang im Feld), 5 Motorwerte gegen das Feld, Hersteller & Vertrag, nächste Spec des Herstellers.
2. **Einheiten:** pro Fahrer die Einheiten (Spec, Laufleistung als Balken, Zustand), Pool der Saison, Plan „frische Einheit wann?“.
3. **Labor** (nur Lizenz/Werk): wie das Auto-Labor, mit Dyno-Ergebnissen (Leistung ±, Dauerlauf-Kilometer, Ausfälle).
4. **Verträge:** aktueller Vertrag, Angebote der Hersteller im Vergleich (Werte, Preis, Platz), Verhandeln; als Hersteller: eigene Kunden.

Mockup: `docs/ui_mockups/r5_engine.html`.

---

## 11. Umsetzung (Stand 31.10.2026 – R5 komplett)

| Datei | Inhalt |
|---|---|
| `core/power_unit.gd` | 5 Komponenten, Gewichtung, Ideen, Modi, Formeln (Masse, Sprit, Lebensdauer, Verschleiß, Fahrbarkeit) |
| `core/engines.gd` | Hersteller der Startwelt, Specs (Werksteam sofort, Kunden 1–3 Rennen später), Einheiten, Motor im Auto, Monatsgebühr (an das Werksteam), Anfragen/Angebote/Verträge, KI-Verträge, Saisonwechsel, Lizenz-Kopie, eigener Hersteller |
| `core/engine_lab.gd` | Motoren-Labor (Konzept → Einzylinder → Dyno → Dauerlauf → Homologation), versteckte Schwächen, Entschärfen, KI-Hersteller, Power-Unit-Programm |
| `data/classes/manufacturer_data.gd`, `engine_unit.gd`, `engine_project.gd` | Daten |
| `ui/screens/engine_screen.gd`, `ui/components/pu_diagram.gd`, `engine_lab_card.gd` | Menü „Motor“: Übersicht, Einheiten, Labor, Verträge |
| Wochenende | Block „Motor“ (neue Einheit), „Motor klingt nicht gut“ nach dem Training, Motormodus im Strategie-Schritt, Schlüsselmomente Motortemperatur / ERS-Fehler / Sprit knapp |

Weitere Details: Motorenwerk ist ab R5 frei (Werksteams starten mit Stufe 3–4), neue Abteilung „Motoreningenieure“ (Platz im Motorenwerk), Motorgebühr mit den Gehältern, Saisonbilanz zeigt Motor, Leistungsrang, benutzte Einheiten. Zahlen sind Startwerte – Feinabstimmung im Playtest.

## 12. Umsetzung in Schritten (Plan)

| Schritt | Inhalt |
|---|---|
| **R5a** | Daten: Hersteller, Komponenten, Specs, Verträge; Motorwerte in der Simulation (5 Werte); Startwelt; Übersicht-Bildschirm |
| **R5b** | Einheiten & Laufleistung, Wochenend-Block „Motor“, Motor-Modi, Schlüsselmomente |
| **R5c** | Hersteller-Entwicklung & Updates (KI), Verträge & Verhandlung, Saisonwechsel |
| **R5d** | Motoren-Labor (Lizenz/Werk), Motorenwerk freischalten, Power-Unit-Programm, Kunden beliefern; Saisonbilanz |
