## Makes assets/ui/guide_paw.png, the picture of the hand guide (HandGuide): the bread cat's own right
## front paw (assets/characters/bread_cat.glb, the game's toon material and brown outline) seen from
## the front (2026-10-31 user choice: a cat paw instead of a hand; the painted pink beans were taken
## off the same day, "not like a cat's paw"). Run it again when the bread cat model changes.
## It needs a real renderer (a display): on a machine without one, under a virtual X server, e.g.
##   xvfb-run godot --path apps/lab3d --display-driver x11 -s res://tools/render_guide_paw.gd
extends SceneTree

const OUT := "res://assets/ui/guide_paw.png"
const RENDER := 1024                  # the square render (px); the paw is cut out of it
const HEIGHT := 240                   # the picture's height (px; HandGuide draws it at PAW_SIZE units)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var model: Node3D = load("res://assets/characters/bread_cat.glb").instantiate()
	var body := model.get_node("BreadCat/Body") as MeshInstance3D
	var material := ArtKit.toon_material((body.mesh.surface_get_material(0) as BaseMaterial3D).albedo_texture)
	var arm := body.get_node("ArmR") as MeshInstance3D
	body.remove_child(arm)
	model.free()
	arm.transform = Transform3D.IDENTITY
	arm.material_override = material
	var view := SubViewport.new()
	view.size = Vector2i(RENDER, RENDER)
	view.transparent_bg = true
	view.own_world_3d = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	view.add_child(arm)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	view.add_child(camera)
	var box := arm.mesh.get_aabb()
	camera.size = maxf(box.size.x, box.size.y) * 1.25
	camera.position = box.get_center() + Vector3(0.0, 0.0, 2.0)   # the front: the paw end on
	camera.look_at(box.get_center(), Vector3.UP)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := view.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	image = image.get_region(image.get_used_rect())
	var size := image.get_size()
	image.resize(roundi(float(size.x) * HEIGHT / size.y), HEIGHT, Image.INTERPOLATE_LANCZOS)
	var error := image.save_png(ProjectSettings.globalize_path(OUT))
	print("render_guide_paw: %s %s (%s)" % [OUT, str(image.get_size()), error_string(error)])
	quit(0 if error == OK else 1)
