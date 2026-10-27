# Campus terrain path cleanup

Tool: built-in imagegen, edit of campus_ground.png. Output: campus_ground_v2.png.
Only the continuous network is baked into this layer. Building entrance routes, entrance parking access and the bottom pedestrian connection are painted by the campus renderer to match actual facility anchors.

## Prompt

Precise cleanup of this existing game terrain background, NOT a redesign. Preserve the exact canvas aspect ratio, top-down pixel illustration style, main roads, main continuous footpaths, grass, trees, fences, benches and all main route coordinates.
REMOVE ONLY the short dead-end pale paving spurs which stick perpendicularly into the lawns: four above the upper horizontal path/road, four above the middle horizontal path/road, isolated short paving segment in lower-left lawn, the two above the lower horizontal path, and the three paving stubs against the bottom fence. Replace each short spur with matching grass. Keep the long horizontal footpaths, the long vertical path on the left, the garage apron, service road loop and entry road intact.
These building entrance connectors are drawn dynamically by the game and must not be baked into the base artwork. Do not add any new spurs, roads, structures, labels or building pads. Do not move or reshape the main streets or paths. Everything outside the removed short paving spurs stays as close to the supplied image as possible. No change in art direction or lighting. Result is the same complete ground layer with clean uninterrupted lawn edges and no dangling building entrance stubs.
