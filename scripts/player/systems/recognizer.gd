class_name Recognizer extends RefCounted

var templates: Array[GestureTemplate] = []
const SAMPLE_COUNT: int = 32

func load_templates(template_resources: Array[GestureTemplate]) -> void:
	templates.clear()
	for res in template_resources:
		if res: templates.append(res)

func recognize(raw_strokes: Array[PackedVector2Array]) -> String:
	if templates.is_empty() or raw_strokes.is_empty():
		return "None"
		
	var candidate = _process(raw_strokes)
	var best_match: String = "None"
	var lowest_dist: float = INF
	
	for template in templates:
		if candidate.size() != template.strokes.size():
			continue # Stroke count must match
			
		var template_processed = _process(template.strokes)
		var dist = _compare(candidate, template_processed)
		
		if dist < lowest_dist:
			lowest_dist = dist
			best_match = template.spell_name
			
	var score: float = clamp(1.0 - (lowest_dist / 120.0), 0.0, 1.0)
	
	return best_match if score > 0.70 else "None"

func _process(strokes: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for stroke in strokes:
		if stroke.size() < 2: continue
		
		var total_len = 0.0
		for i in range(1, stroke.size()):
			total_len += stroke[i - 1].distance_to(stroke[i])
		if total_len == 0.0: continue
		
		var interval = total_len / float(SAMPLE_COUNT - 1)
		var acc = 0.0
		var resampled = PackedVector2Array([stroke[0]])
		
		for i in range(1, stroke.size()):
			var p1 = stroke[i - 1]; var p2 = stroke[i]
			var d = p1.distance_to(p2)
			while (acc + d) >= interval:
				var t = (interval - acc) / d
				p1 = p1.lerp(p2, t)
				resampled.append(p1)
				d = p1.distance_to(p2)
				acc = 0.0
			acc += d
		while resampled.size() < SAMPLE_COUNT: 
			resampled.append(stroke[stroke.size() - 1])
		
		var min_p = resampled[0]; var max_p = resampled[0]
		for pt in resampled:
			min_p.x = min(min_p.x, pt.x); min_p.y = min(min_p.y, pt.y)
			max_p.x = max(max_p.x, pt.x); max_p.y = max(max_p.y, pt.y)
			
		var center = (min_p + max_p) * 0.5
		var size = max(max_p.x - min_p.x, max_p.y - min_p.y)
		if size == 0: size = 1.0
		
		var normalized = PackedVector2Array()
		for pt in resampled:
			normalized.append((pt - center) / size * 100.0)
		result.append(normalized)
		
	return result

func _compare(a: Array[PackedVector2Array], b: Array[PackedVector2Array]) -> float:
	var total = 0.0
	for i in range(a.size()):
		var s_a = a[i]; var s_b = b[i]
		for j in range(s_a.size()):
			total += s_a[j].distance_to(s_b[j])
	return total / float(a.size() * SAMPLE_COUNT)
