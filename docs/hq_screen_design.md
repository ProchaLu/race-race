# R4 — HQ screen design

## Current state (30.10.2026) – this section is authoritative

**Art style (decision):** illustrated tycoon style, not pixel art. Detailed building illustrations seen from a slight 3/4 angle on a top-down campus with roads, smoothly scaled (linear filtering, Lanczos downsampling). Future art – cars, people, animations, new buildings – follows this style: matte, readable silhouettes, team colour on garage doors, transporters and flags. The pixel-art notes in the history below are superseded.

**Code**
- `core/facilities.gd` (`Facilities`, static): the single source for all 15 buildings – name, purpose, base price and build time, upkeep, the round whose system a building feeds (locked until then), levels per team (`TeamData.facilities`, StringName IDs), construction (`facility_projects`, one at a time), daily progress (called from `Season._daily_world_update`), monthly upkeep (with the salaries), AI building, starting campus per team (`seed_for_tier`) and all effects. Replaces `FacilityManager` and the old level fields on TeamData.
- `ui/components/hq_campus.gd` (`HqCampus`): ground layer (own TextureRect behind the buildings, slightly desaturated by a shader) + building layer, re-rendered only when levels or construction stages change; scaled sprites are cached. Hover tag with name and level; building sites show name and price (or "comes with R5"); optional "Show names".
- `ui/screens/hq_screen.gd`: status strip (in operation, construction, upkeep, campus rank), campus card, inspector with the tabs "Building" and "All buildings", and an action bar that is always visible; construction is confirmed inline.
- Checks: `godot --headless --path . res://tools/hq_construction_check.tscn` and `res://tools/hq_visual_check.tscn`.

**Prices (calibrated 30.10.2026):** base price × [1.0, 1.5, 2.3, 3.4, 5.0] for levels 1–5 (largest upgrade: wind tunnel level 5 = $60M). Build time base × (1 + 0.35 × (level − 1)) – wind tunnel level 5 takes 144 days. Upkeep per month = base × 0.6 % × level^1.3 (all buildings at level 5 ≈ $3.1M per month). A second construction crew from 45 campus levels in total.

**Effects** – level 1 → 5 roughly doubles a department (see `Facilities.effect_lines`):

| Building | Effect |
|---|---|
| Design office | design capacity ×(0.6 + 0.2·L), parallel projects 1 + L, room for designers |
| Wind tunnel | wind tunnel capacity ×(0.45 + 0.2·L), aero forecast error ×(1.5 − 0.2·L) |
| CFD centre | CFD capacity ×(0.6 + 0.2·L), room for aerodynamicists |
| Factory | production ×(0.6 + 0.2·L), cost per part ×(1.15 − 0.07·L), room for factory staff |
| Composites | weight saved by new parts ×(0.7 + 0.15·L) |
| Test laboratory | rig capacity ×(0.6 + 0.2·L), mechanical forecast error ×(1.4 − 0.15·L), reliability +3·L, room for rig engineers |
| Simulator | race engineers' setup work +4·L |
| Driver performance centre | physical and mental training +5·L |
| Pit-crew training | pit stop speed and precision +5·L |
| Mission control | race, weather and tyre reading +4·L |
| Staff facilities | team mood 2·L − 4 |
| Engine works / Marketing & hospitality / Academy, Scouting | locked until R5 / R6 / R7 |

**Calibration run** (same team and staff, one full season, every building at level 1 vs level 5): new parts 9 vs 26, lap time gained −0.10 s vs −0.24 s, car vs field P7 vs P4, wind tunnel forecast error 23 % vs 8 %, parallel projects 2 vs 6, pit stop 2.66 s vs 2.24 s, team mood 52 vs 62, upkeep $0.4M vs $3.1M per month.

**Campus life:** unused plots show a storage yard, overflow parking or a garden (cleared when construction starts). With "Animation" on: pit-crew drill at the pit apron, people walking, a transporter on the middle road (switch off for a still image).

Room for staff: the R3 department headcount (from the budget) is capped by the building that houses the department (design office, CFD centre, test laboratory, factory). Without the building (level 0) the department squeezes into other buildings at 45 % of an average team's room – it never drops to zero.

---

## History (superseded proposals and earlier implementation notes)

### Interaction implementation (before the R4 review)

Latest road correction supersedes the v2 runtime access-path approach below: all circulation now uses a single authored asphalt/curb material in `campus_ground_v3.png`. Removed the code-drawn access network, entrance strokes, parking surfaces, road markings and crossing patches. The ground layer is calibrated to world-coordinate road bands with continuous texture resampling; it is not combined with a second road style. Parked cars and transporters were aligned to the painted parking/loading areas.

Each facility family uses a shared source scale capped by the maximum architectural variant's visible footprint. Smaller variants retain their relative size and all levels align to the same entrance baseline. Scouting, mission control, garage and staff reserved bounds were adjusted for traffic clearance. Automated visual checks now test visible sprite alpha against public lanes and parking, not just arbitrary sprite bounding boxes. Current in-game capture: [unified roads](ui_mockups/r4_hq_unified_roads.png). Asset prompts: `assets/hq/UNIFIED_ROADS.md`.

Visual refinement: the runtime uses `campus_ground_v2.png`, which removes baked entrance stubs. Explicit access routes now connect facility entrances to the main footpaths, the bottom facilities to the gate walkway, and the entrance parking/loading area to the service road. No campus or building anchors moved.

Construction is rendered as an actual site: fenced boundary, hazard panels, material stacks, cabin and crane. New facilities show foundations, then structural framing as progress increases. Upgrades retain the operating building under scaffolding and translucent safety netting. A large local status banner and percentage bar replace the old tiny plus/progress marker. The whole fenced area selects the project, including transparent parts of an upgraded building. Completion removes the overlay. Calendar-driven screen refreshes are coalesced so Continue does not rebuild the campus once per skipped day.

Captures: [new building worksite](ui_mockups/r4_hq_construction_refined.png), [upgrade scaffolding](ui_mockups/r4_hq_upgrade_refined.png). Verification now also checks worksite selection, intermediate construction artwork, removal on completion and retention of the operating sprite during an upgrade. Terrain cleanup prompt: `assets/hq/TERRAIN_PATH_CLEANUP.md`.

In-game captures: [facility selection and build proposal](ui_mockups/r4_hq_interactive.png), [construction in progress](ui_mockups/r4_hq_construction.png).

HQ now supports alpha-aware selection of existing buildings, reserved-site selection for missing facilities and keyboard-accessible facility buttons. Picking and overlays follow the same aspect-fit/letterbox transform as the campus image. The side inspector shows purpose, level, current/next art, effects, costs, duration and completion date. Empty plots have compact build markers; active work has an amber outline and progress indicator.

`FacilityManager` owns initialization, validation, spending and calendar-day progress. TeamData holds authoritative levels for all 15 buildings and active construction orders. Existing visual defaults are migrated once, so new buildings are not subsequently reseeded from the design level. One construction project per team; maximum level 5; existing levels remain active during upgrades; payment is taken once on confirmation. Completion synchronizes the five legacy level fields, updates campus art and posts an inbox link to the facility. Remaining days survive the 364-day season rollover.

Design, wind tunnel and factory already influence R3 through the existing formulas. The other facilities can be built/upgraded, but their specialist simulation effects remain planned and are labelled accordingly before purchase. Costs/durations are initial tuning values; upkeep and autonomous AI building are not yet implemented.

Verification: `tools/hq_construction_check.gd` covers spending and duplicate/concurrent rejection, stale quotes, insufficient funds, max level, rollover, completion inbox, legacy R3 sync, letterboxed map picking and selected-facility navigation. `tools/hq_visual_check.gd` continues to cover the 75 architectural sprites.

## Current implementation — detailed campus and architectural levels

The visual-only renderer now composites at 1600×1000. It uses a dedicated terrain layer and 75 independent architectural sprites: five levels for each of the 15 facility families. These replace the previous tiny 640×400 intermediary, same-building scaling and generic annexes. Source rows have measured boundaries, disconnected atlas fringe is isolated, and sprites share a common baseline/source scale. Rendering uses high-quality downsampling to retain refined pixel illustration at the actual viewport size rather than magnifying coarse blocks.

Runtime assets: `assets/hq/campus_ground.png`, `engineering_levels.png`, `development_levels.png`, `operations_levels.png`. Prompts/provenance: `assets/hq/LEVEL_ART_NOTES.md` and `TERRAIN_ART_NOTES.md`. The older `facilities.png` sheet is retained as history and is no longer loaded by the renderer.

Same land and anchors across teams; missing buildings leave grounds visible. Existing TeamData levels are read for five facilities; the remaining availability/levels still use the documented visual-only policy derived from design level. No upgrades, clicks or financial/simulation effects are implemented. Crew, race cars and transporters remain static decoration. Final visual approval and a real facility-state model remain open.

Verification: `tools/hq_visual_check.gd` checks 75 nonempty/distinct adjacent-level sprites, exports five full-campus renders and opens HQ through AppShell. Running with a real rendering driver also captures the actual game screen. Technical checks do not constitute approval of art quality.

## R4a implementation started

Visual revision after v1 feedback: replace generic rectangle buildings with individually identifiable facility sprites from `assets/hq/facilities.png`. Generated transparent atlas, 5 columns × 3 rows; native scene still 640×400 with nearest-neighbour scaling. Added roof shapes, glazing, manufacturing details, landscaped edges, parking, curbs, entry treatment and a framed screen presentation. Empty sites receive natural planting. Runtime sprites preserve aspect ratio; atlas slicing is cached. The five full authored level variants per facility remain future art work: current levels vary sprite footprint and add engineering wings at levels 3/5. This is not a claim that final five-level architecture is complete. Art generation prompt/provenance: `assets/hq/ART_NOTES.md`.

The HQ sidebar now opens `ui/screens/hq_screen.gd`. Its read-only `ui/components/hq_campus.gd` draws a native 640×400 pixel campus with nearest-neighbour sampling. Grounds and 15 anchors stay fixed; numbered buildings correspond to a noninteractive facility legend. Team colour appears on walls, cars, transporters and flags. Levels add physical extensions, glazing, equipment and footprint changes inside reserved bounds. People and vehicles are currently static pixel decorations.

The five existing TeamData facility levels are read directly. Other facility occupancy and levels are visual placeholders derived from the design-office level, without modifying TeamData or giving simulation benefits. A real facility model will replace that policy. No clicks, inspector, upgrades, construction, spending or animation are implemented in this visual-first task. The generated concept screenshots are references; the screen uses code-drawn pixel art rather than embedding a generated screenshot and its UI.

Current review: multiple style alternatives using the attached v5 campus as reference. See [HQ style options](hq_style_options.md) and the [comparison page](ui_mockups/r4_hq_style_options.html). No final style selected. Heritage, modern and retro options retain shared campus and building-level requirements.

## Current art direction — pixel art

Refinement of the promising v9 screen: [v10 refined HQ screen](ui_mockups/r4_hq_concept_v10_refined_screen.png). Built-in imagegen edit of v9; [prompt](ui_mockups/r4_hq_prompt_v10_refined_screen.md). Removes marked future plots, adds a distinct design office and refines campus sprites while preserving screen composition. Remaining limitations: simulator is not explicitly shown, complete 15-facility anchor plan still needs verification, and the inspector does not yet show a sufficiently strong next-level structural difference. This is a static design proposal, not an implemented screen.

User review: v9 is the first promising screen direction. Refine it rather than restarting the design. Preserve its campus viewport, working garage focus, dark game shell and building inspector. Improve the scene through quieter lawns, fewer repetitive trees, less rigid paths, distinct functional building silhouettes and smaller labels. Remove future-plot markers. Match inspector previews to campus sprites and make the next level's architectural change clear. This positive direction does not approve every v9 detail or its illustrative balance values.

Screen exploration: [HQ game screen v9](ui_mockups/r4_hq_concept_v9_game_screen.png), built-in imagegen; [prompt](ui_mockups/r4_hq_prompt_v9_game_screen.md). This brings the concept into a game-screen composition. It remains unapproved: the generated image reintroduced dashed empty plots and regular arrangement despite the brief, omitted a clearly identified design office, and does not establish all 15 facility anchors. Remove those dashed plot outlines, verify the complete layout and strengthen architectural level differences in a production pass. Numbers shown are illustrative.

Latest screen refinement: stop presenting polished architectural art sheets as the HQ design. Show a single usable game screen with the existing dark shell, the campus viewport and selected-building information. Simplify campus sprites at gameplay scale: broad flat pixel clusters, minimal shading, plain lawns, sparse vegetation, restrained roof detail and tiny activity sprites. Keep racing identity, natural layout, shared campus size and structural level differences. Pixel scene art and sharp UI typography are separate layers. A developing-team screen may leave future facilities unbuilt; a separate top-team layout must still account for all 15. Generated images remain visual exploration, not evidence that production pixel grids or click interactions are implemented.

### Fixed campus, different occupancy and building levels

### Racing identity and campus life

Atmosphere/layout proposal: [racing campus v8](ui_mockups/r4_hq_concept_v8_racing_life.png), generated with built-in imagegen; [prompt](ui_mockups/r4_hq_prompt_v8_racing_life.md). Shows garages, loading, pit practice and natural undeveloped land instead of plot tiles. This board explores atmosphere; it does not yet prove all 15 facilities, exact shared anchors or every building's level progression. The central garage also needs stronger low/high-level differences. Preserve those requirements in the next layout pass rather than treating the concept as a complete asset specification.

The v7 occupancy comparison improves the direction, but the regular grid reads like a puzzle. Keep identical campus size and stable facility anchors across teams while arranging facilities naturally around a race-operations apron. Reserved spaces are internal layout data, not drawn square plots. Empty sites read as lawns, landscaping or spare service yards. Avoid permanent numbered plot labels and rigid rows.

Make racing activity the focal point: open race-garage doors, open-wheel cars, pit-stop practice, tyre trolleys, flight cases, transporters loading parts and mechanics moving between production and the garage. Connect manufacturing to loading access, engineering to testing, and people facilities to quieter paths. Team colours appear consistently on garage doors, transporters, workwear and entrance flags. Do not add a race circuit merely to communicate motorsport.

For implementation, add restrained looping pixel animations after the static composition is approved: a pit crew practice loop, a trolley journey, a few pedestrian routes, pennant movement and occasional loading activity. Routes must follow valid ground paths and avoid buildings. Building anchors and click targets stay stable. Use sparse distributed activity so inspection remains easy; activity sprites do not intercept facility clicks. Honour reduced-motion preferences by freezing decorative loops. Transporter presence and preparation intensity can later reflect race-week timing, if supported by the game state.

Concept art can communicate activity but is not an animated deliverable. Pixel people, cars and equipment require separate sprite assets and animation frames in production.

Comparison proposal: [fixed-size campus v7](ui_mockups/r4_hq_concept_v7_fixed_campus.png), generated with built-in imagegen; [prompt](ui_mockups/r4_hq_prompt_v7_fixed_campus.md). The three equal campus footprints show occupancy progression, with a separate wind tunnel architectural progression. Concept only: the generated bottom strip does not maintain exact parcel scale, and some campus buildings need stronger level differences before production. Production sprites must use identical reserved parcel bounds and explicit level variants.

User clarification: every team uses the **same campus size and reserved plot layout**. Do not represent a smaller team with a smaller parcel. The comparison must use identical camera, world scale, boundary, paths and plot anchors. Smaller teams have missing facilities shown as empty reserved plots and modest low-level buildings on occupied plots. Developing teams have more facilities at mixed levels. The biggest teams have all 15 facilities at level 5. Growth changes occupancy and the architecture inside each plot, not campus size. This supersedes the previous v6 parcel-size study and any proposal for differently sized team grounds in this screen design.

The five levels must produce recognisably different building structures: added functional wings, floors, workshop bays, equipment and annexes. Preserve the facility's architectural identity and reserved parcel. A badge or recolour alone is insufficient. The upgrade panel compares actual current/next appearances at the same scale. Wind tunnel levels 1–5 provide the first explicit visual progression study.

For an initial team comparison, keep all 15 plot positions fixed. A small-team example occupies only design, wind tunnel, factory, pit training and staff facilities at level 1. A developing-team example adds facilities and mixes levels, leaving some plots empty. The top-team example fills every plot with its level-5 variant. These are art-review examples; starting-world availability and costs still require balancing. Earlier references to buying land remain a future mechanic and are not part of this fixed-size comparison.

Latest style study: [clean pixel HQ variants v6](ui_mockups/r4_hq_concept_v6_clean_pixel.png). Small, growing and works-team grounds shown without UI to review the buildings and visual density. Generated using built-in imagegen; [prompt](ui_mockups/r4_hq_prompt_v6_clean_pixel.md). This is an unapproved concept, not production sprites or a verified facility layout.

Latest user refinement: **clean pixel art across different team HQs**. A dimensional/isometric view is allowed; the strict top-down constraint from the previous attempt is no longer mandatory. Prioritise simple silhouettes, visible coherent pixel clusters, limited colours, restrained shading and generous spacing. Avoid noisy scenery, excessive roof details and crowded labels. First judge architecture and pixel treatment on a clean art sheet without screen chrome. Explore small, growing and works-team campuses in one consistent art family. Smaller teams may have fewer built facilities; the full works-campus design must show all 15. These are scale studies, not a replacement for the five individual building-level appearances. Team-specific layouts should not imply teams must start at those three fixed tiers.

Latest proposal: [new top-down pixel campus v5](ui_mockups/r4_hq_concept_v5_topdown_pixel.png). Generated from scratch with built-in imagegen, without previous image references. All 15 buildings are numbered. [Generation prompt](ui_mockups/r4_hq_prompt_v5_topdown_pixel.md). This is concept art; production sprites still need consistent native pixel grids and separate exports.

Latest correction: **strict top-down 2D pixel art**, with a vertical 90-degree camera, flat roof footprints and ground sprites. No isometric projection, perspective façades or pre-rendered 3D buildings. The v4 board is rejected: it retained the old perspective and excessive rendered detail. Start the composition from scratch. Use large, visible square pixels, a small shared palette and deliberately simplified shapes. The full campus and all 15 facilities remain required. This correction supersedes all references below to isometric cameras and architectural rendering.

Pixel-art concept: [full campus v4](ui_mockups/r4_hq_concept_v4_pixel.png). Generated with built-in imagegen; [prompt](ui_mockups/r4_hq_prompt_v4_pixel.md). All 15 facilities appear in this visual proposal. The flattened image is not a playable screen or production sprite sheet.

User direction: pixel art. This replaces all prior photorealistic, low-poly and illustrated rendering proposals below. Previous boards are rejected visual explorations, not style references for production.

Use crisp, deliberately visible pixel clusters, a limited shared palette and coherent isometric projection. Buildings, scenery, construction overlays and vehicles must share one pixel scale. No smooth photographic textures, soft rendered gradients or antialiasing in the campus art. Use nearest-neighbour sampling and integer scaling for pixel assets; settle the native resolution with an in-game-size prototype. UI typography must remain readable and localisable independently of architectural sprites.

Keep the full-campus requirement: all 15 facility families visible, distinct silhouettes, selectable buildings, compact information card, detailed upgrade panel and five structurally different appearances per building. The wind tunnel's external duct stays a recognisable landmark at every level. Each asset must be individually authored/exported for implementation; a generated flattened concept is a visual reference only.

## Superseding visual brief — full campus

New composition proposal: [full-campus concept v3](ui_mockups/r4_hq_concept_v3.png). All 15 facilities are numbered and keyed in the legend. This explores a different layout and architectural vocabulary; it is not an approved final style or a playable screen. Generated with built-in imagegen; prompt in [v3 prompt](ui_mockups/r4_hq_prompt_v3.md).

The first two boards are rejected directions: the second changed surface styling without sufficiently changing the composition or architecture. Neither establishes the intended identity. The next proposal must start from a new composition rather than edit those boards.

Show the entire campus with all 15 building families from the game design, not a technical-building sample. Every facility needs a distinct silhouette, a visible entrance and a selectable parcel. No grounds or buildings may be cropped in the default overview. A numbered legend provides names without covering the architecture with 15 large labels.

Explore a crafted illustrated architectural diorama: deliberate graphic shapes, matte shading, subtle drawn edges, industrial heritage mixed with distinctive contemporary engineering architecture. Avoid photorealism and a grid of interchangeable white factory blocks. Seek an authored visual identity; originality must be assessed during review rather than assumed from a generated image.

Compose the grounds around a curved pedestrian spine and shared courtyard, with engineering, production and people districts. Keep service traffic at the edges. Include design office, wind tunnel, CFD, factory, composites, engine works, test laboratory, simulator, driver performance centre, academy, scouting, pit-crew training, mission control, marketing/hospitality and staff facilities. Later-game facilities can appear as reserved or locked sites in gameplay, but the design board must demonstrate the complete campus.

Replace the previous permanent wide inspector with a compact floating selection card. The full-campus overview is the priority. Clicking opens purpose, level and status in the card; “Details / Upgrade” expands a closable panel with the complete information specified below. Closing restores the unobstructed overview and selection. Reserve screen space for the card without hiding a building. Keyboard-accessible facilities navigation remains required.

All five architectural level variants remain required for every building. Level comparison belongs in the upgrade panel, not a permanent strip taking space away from the campus. A production slice can follow only after the complete campus composition is reviewed.

Rejected concept history: [v2](ui_mockups/r4_hq_concept_v2.png) changed styling without sufficiently changing the design. Generated using built-in imagegen; revision prompt is recorded in [the prompt file](ui_mockups/r4_hq_prompt.md).

Concept board: [HQ campus and wind tunnel progression](ui_mockups/r4_hq_concept.png). Generated with the built-in image generation tool; [generation prompt](ui_mockups/r4_hq_prompt.md). The board illustrates visual direction, not final navigation, balance values or engineering specifications. The level comparison strip is a design-review element, not a permanent part of the game screen. In-game comparisons belong in the selected building's inspector. Follow the written specification where image details differ.

## Direction

The HQ is a place the player recognises and develops: a believable motorsport campus shown from a fixed elevated isometric camera, with individually selectable buildings. The reference is the legibility and sense of ownership of a static city-builder view. Use stylized industrial architecture, landscaped grounds, access roads, parking and subtle team branding.

Art direction correction: the first concept was too photorealistic. Aim for a polished tycoon-game miniature: chunky low-poly forms, softly hand-painted matte surfaces, simplified vegetation and vehicles, and slightly exaggerated building silhouettes. Keep real-world functions recognisable while simplifying their visual representation. Avoid photographic textures, cinematic lighting, highly reflective materials and tiny architectural noise. The campus should immediately look like a game. Use consistent stylized rendering for every building level.

Keep the existing dark Pit Wall shell and amber selection colour. The campus itself uses warm daylight, a controlled palette and broad material colours so the architecture remains readable. Buildings are the main content, rather than decorative images above a list.

## Screen composition

At the game's 1920 × 1080 target, retain the existing sidebar and topbar. Below the HQ title, show a compact summary: operating facilities, active construction, recurring upkeep and available land. The complete campus dominates the available area. Reserve a small peripheral space for the floating selection card so it never covers a building. Detailed information opens in a closable overlay without moving the campus.

The campus is framed to show the whole owned site initially. A small toolbar provides zoom, reset view and label visibility. Restrained pan/zoom supports inspection; rotation is unnecessary for the first version. Keep major entrances and identifying features visible from the fixed camera. Foreground buildings must not hide selectable buildings behind them.

Place technical buildings together, manufacturing near service roads, and driver/staff buildings around greener pedestrian areas. Empty expansion parcels sit at the edge of the grounds. Roads, trees and parked vehicles establish scale without obscuring buildings.

## Selecting and inspecting

- Hover: a thin ground outline plus building name, level and operating/construction status.
- Click: persistent amber ground outline and the building's information in the inspector. Avoid tinting the whole architectural image.
- Default inspector: campus overview, construction queue and facilities needing attention.
- Selected inspector: building name, level, status, larger image, purpose, current effects, upkeep and relevant staffing/capacity information. Only show staffing mechanics that exist.
- Provide links to affected systems, such as car development, with a clear explanation of where the benefit applies.
- Next-level section: current and next appearance side by side, exact effect changes, price, build duration, upkeep change and prerequisites. Numbers in concept art are illustrative.
- Upgrade action: open a review panel with the actual cost and completion date before committing. Unavailable actions explain their reason beside the button.
- Construction inspector: progress, estimated completion, target-level preview and current operating effects.
- Maximum level: show “Fully upgraded” and the completed building's benefits.

Building labels use a short name and “Lv 2”, with a text/icon status indicator. Level and status must remain understandable without colour. A compact facilities list provides an alternate way to select any building, including keyboard navigation. Clicking a list entry highlights the same building on the campus. Selection persists when switching between map and list.

## Every level changes the architecture

Each facility has five authored appearances, one per level. A level is a different building design, not a recolour, scaled sprite or changed badge. Keep the building's defining silhouette, entrance orientation and architectural family consistent so the player recognises it after an upgrade.

Each campus parcel reserves enough room for its facility at level 5. Lower levels use less of that parcel, leaving service yards or landscaping. Later levels add halls, annexes, floors and equipment within the reservation. This avoids rebuilding the whole campus layout whenever one building levels up. Every team has the same campus with one fixed plot per building; there is no land purchase, free placement or relocation (decision 30.10.2026).

| Level | Architectural reading |
|---|---|
| 1 | Modest specialist facility; small footprint and basic equipment |
| 2 | Clear extension, dedicated control/office space, additional equipment |
| 3 | Established professional complex with connected functional wings |
| 4 | Large integrated facility with more specialised infrastructure |
| 5 | World-class campus landmark; refined architecture and substantial technical equipment |

### Wind tunnel example

| Level | Visible design |
|---|---|
| 1 | Compact industrial test hall with a small visible external return duct and utility entrance |
| 2 | Extended hall, larger enclosed return loop and attached control room |
| 3 | Purpose-built tunnel complex with preparation bay and two-storey engineering annex |
| 4 | Integrated aero centre with upgraded loop housing, instrumentation wing and additional service plant |
| 5 | Flagship aero research complex with a refined large tunnel enclosure, model-preparation wing and glazed control offices |

These are visual cues for increasing capability, not claims that higher levels necessarily add a second tunnel or represent a particular real-world tunnel specification. Simulation benefits must be defined separately.

### Distinct building identities

| Facility | Recognisable architecture and progression |
|---|---|
| Design office | Glazed office block → connected engineering wings and larger design studio |
| Wind tunnel | Test hall and return duct → integrated aerodynamic research complex |
| CFD centre | Secure server building with cooling plant → larger data halls and equipment yards |
| Factory | Workshop with loading doors → multiple connected production halls |
| Test laboratory | Instrumented workshop → dedicated test cells and laboratory annexes |
| Composites | Clean industrial hall → larger controlled-production and autoclave buildings |
| Simulator | Compact simulator studio → dedicated simulator and preparation centre |
| Driver performance | Training pavilion → integrated gym, recovery and sports-science centre |
| Academy | Small teaching/training building → residential and training wings |
| Scouting | Small office → expanded analysis and recruitment offices |
| Pit-crew training | Covered practice bay → dedicated pit-stop training hall and apron |
| Mission control | Operations office with communications equipment → substantial race-support centre |
| Marketing/hospitality | Visitor pavilion → event, presentation and hospitality complex |
| Staff facilities | Canteen and terrace → larger social, dining and wellbeing facilities |
| Engine works | Engine workshop → specialised manufacturing, assembly and dyno complex |

## Construction appearance

During an upgrade retain the operating building and add barriers, scaffolding, construction materials and an extension under construction. Show a small progress badge; details belong in the inspector. A new facility begins as a clearly bounded construction site. Completion swaps to the next authored appearance, removes construction elements and sends an inbox message linking back to the building.

Proposed operating rule: the previous level remains active during upgrades and the next level's benefits begin on completion. Gameplay balancing must confirm this rule before implementation.

## Art and implementation plan

Use a Godot 2D campus with pre-rendered architectural building sprites, a shared ground environment and separate UI overlays. This delivers the proposed fixed-camera appearance without requiring a fully navigable 3D environment. Final rendering choice can change after a small visual prototype.

Each building asset needs a transparent background, consistent camera and lighting, shared ground scale, a stable parcel anchor and a click polygon matching its visible shape. Draw buildings in depth order. Labels, selection outlines and progress indicators are rendered by the game so they remain sharp and localisable.

Separate ground, buildings, construction overlays and labels. A single flattened campus image cannot reliably support independent upgrades. Roofs, materials and team-colour accents should share an art guide across every level. Team identity may vary through signage, colours and a few layout templates without requiring unique art for every team.

The full 15-building design implies 75 level appearances, plus construction overlays and environment assets. First review the entire campus with all 15 building families visible. After that composition is accepted, validate a production slice with wind tunnel levels 1–5 and a construction state at actual game size before producing the remaining level variants.

## Design review checklist

- Campus reads as a real racing-team HQ at the normal screen zoom.
- Wind tunnel levels 1–5 can be distinguished without reading the level badge.
- Clicking each building exposes its purpose, current benefits and upgrade path.
- Preview shows the physical change alongside cost, duration and benefit changes.
- Construction is visible on the campus and understandable in the inspector.
- All buildings remain selectable by map and keyboard-accessible list.
- Selection, labels and inspector remain readable at smaller supported window sizes; collapse the inspector into an overlay if required.
- No real team branding, baked-in UI text or final balance numbers in architectural assets.

## Next deliverable

Review the concept image and this interaction proposal, then build a clickable screen mockup with selectable buildings, a level-preview control and a construction example. This is screen design work; the facility simulation and economy remain a separate implementation step.
