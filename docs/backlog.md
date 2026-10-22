# Backlog – Bugs, Feinschliff, offene Punkte

Regel: **Kaputtes oder Störendes sofort beheben.** Feinschliff wird gesammelt und am Ende jeder Runde abgearbeitet. Erledigtes wird abgehakt und bleibt als Verlauf stehen.

## 🐞 Bugs
- [ ] *(noch keine offenen)*

## ✨ UI-Feinschliff
- [ ] *(noch keine offenen)*

## 📌 Offen aus R1 (später)
- [ ] **Delegieren** an den Sportdirektor (Verträge für Nachwuchs, Ersatzfahrer, Personal) – sinnvoll ab R2/R3 (Design-Dok. 5.4)
- [ ] **Abwerben ohne Ausstiegsklausel**: mit dem anderen Team über eine Ablöse verhandeln
- [ ] **KI-Teams werben eigenes Personal ab** (Interesse anderer → Angebote, Inbox-Meldung)
- [ ] **Vertragsende zum Saisonende**, Altern und Entwicklung von Fahrern und Personal → R2 (Saisonwechsel)

## 📌 Offen aus R2 (Simulation)
- [ ] **2D-Ansicht auf die neue Simulation umstellen** – erst viel später, gemeinsam mit der zweiten Person (alter `RaceSim` bleibt bis dahin unverändert)
- [ ] **Platzhalter-Strecken ersetzen**, sobald die echten Strecken gebaut sind (`sim/weekend/track_layouts.gd`)
- [ ] Feinabstimmung im Sim-Labor laufend (Werte in `sim/weekend/sim_tuning.gd`, Strecken-Werte in `track_layouts.gd`)

## ✅ Erledigt
- [x] Inhalt rechts abgeschnitten: Topbar war nach dem Stimmungs-Block breiter als der Platz und hat den ganzen Inhalt verschoben (Topbar kompakter, Titel wird gekürzt statt zu schieben); Markt-Spalte „Bekannt“ ohne Scrollen sichtbar
- [x] R1-Abschluss: Teamstimmung (Topbar + Startseiten-Karte), Moral-Folgen (Entlassung, gescheiterte/erfolgreiche Verlängerung, Neuverpflichtung, Versprechen), Versprechen aus Verhandlungen werden gespeichert und zur Frist geprüft, Shortlist-Hinweise (Vertrag läuft aus, vertragslos, wechselt woandershin)
- [x] Verzerrtes Fahrerbild im Verhandlungsfenster
- [x] Verwirrende Meldung, wenn ein Rivale vor der Unterschrift dazwischenfunkt (jetzt „Transfer geplatzt“, Risiko sichtbar, mit Handgeld senkbar)
- [x] Personalliste per Klick auf Spalten sortierbar
- [x] Markt-Vorschau: Scouting-Dauer, mehr Details, Button-Anordnung, „Gespräche beginnen“ als Hauptbutton
- [x] Die beiden Renningenieure unterscheidbar („Renningenieur · Hale“)
