class_name Palette
extends RefCounted
## Gråboxens färger. Ersätts av riktig grafik i fas 2 — men kontrastkravet i
## docs/ACCESSIBILITY.md gäller redan nu: RB och allt farligt ska läsa som
## silhuetter, och bakgrunden ska aldrig ha samma kontrastnivå som spelbara ytor.

const INK := Color(0.09, 0.08, 0.11)
const SHELL := Color(0.96, 0.96, 0.97)
const PINK := Color(0.88, 0.07, 0.41)
const BLUE := Color(0.18, 0.31, 0.84)
const GROUND := Color(0.78, 0.79, 0.83)
const GROUND_EDGE := Color(0.35, 0.35, 0.42)
const BACKDROP := Color(0.93, 0.94, 0.96)
const CRATE := Color(0.85, 0.88, 0.95)
