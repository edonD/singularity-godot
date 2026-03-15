@tool
extends Node

## Generates a 16x16 pixel art player sprite via code.
## Call generate() to get an ImageTexture.

static func generate_player_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# Body (dark jacket)
	var body_color := Color(0.2, 0.25, 0.35)
	var skin_color := Color(0.85, 0.7, 0.55)
	var hair_color := Color(0.15, 0.12, 0.1)
	var boot_color := Color(0.25, 0.2, 0.15)
	var accent := Color(0.4, 0.6, 0.8)

	# Hair (rows 1-3)
	for x in range(5, 11):
		img.set_pixel(x, 1, hair_color)
	for x in range(4, 12):
		img.set_pixel(x, 2, hair_color)
	for x in range(4, 12):
		img.set_pixel(x, 3, hair_color)

	# Face (rows 4-6)
	for x in range(5, 11):
		img.set_pixel(x, 4, skin_color)
	for x in range(5, 11):
		img.set_pixel(x, 5, skin_color)
	# Eyes
	img.set_pixel(6, 5, Color(0.1, 0.1, 0.1))
	img.set_pixel(9, 5, Color(0.1, 0.1, 0.1))
	for x in range(5, 11):
		img.set_pixel(x, 6, skin_color)

	# Body/jacket (rows 7-11)
	for y in range(7, 12):
		for x in range(4, 12):
			img.set_pixel(x, y, body_color)
	# Jacket accent stripe
	for y in range(7, 11):
		img.set_pixel(7, y, accent)
		img.set_pixel(8, y, accent)

	# Arms (rows 7-10)
	for y in range(7, 11):
		img.set_pixel(3, y, body_color)
		img.set_pixel(12, y, body_color)
	# Hands
	img.set_pixel(3, 11, skin_color)
	img.set_pixel(12, 11, skin_color)

	# Legs (rows 12-13)
	for y in range(12, 14):
		for x in range(5, 7):
			img.set_pixel(x, y, Color(0.2, 0.2, 0.3))
		for x in range(9, 11):
			img.set_pixel(x, y, Color(0.2, 0.2, 0.3))

	# Boots (row 14)
	for x in range(4, 7):
		img.set_pixel(x, 14, boot_color)
	for x in range(9, 12):
		img.set_pixel(x, 14, boot_color)

	return ImageTexture.create_from_image(img)


static func generate_attack_effect_texture() -> ImageTexture:
	var img := Image.create(24, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# Swing arc
	var arc_color := Color(0.9, 0.9, 1.0, 0.8)
	for x in range(4, 22):
		var y_off := int(abs(x - 12) * 0.3)
		if y_off < 4:
			img.set_pixel(x, 3 + y_off, arc_color)
			img.set_pixel(x, 4 + y_off, arc_color)

	return ImageTexture.create_from_image(img)
