extends GutTest

# Platform: flaga builda mobilnego + czyste funkcje okna/kamery builda pionowego.

func test_platform_is_autoload() -> void:
	assert_true(ProjectSettings.has_setting("autoload/Platform"),
		"Platform zarejestrowany jako autoload (dopasowanie okna przed reszta gry)")

func test_portrait_scale_size_swaps_axes() -> void:
	assert_eq(Platform.portrait_scale_size(Vector2i(1152, 648)), Vector2i(648, 1152),
		"pion = zamiana osi bazowego rozmiaru")

func test_desktop_build_flags_and_zoom() -> void:
	assert_false(Platform.is_mobile_build(), "testy biegna na desktopie -> build niemobilny")
	assert_almost_eq(Platform.camera_zoom(false), 1.0, 0.001, "desktop: zoom kamery 1.0")
	assert_almost_eq(Platform.camera_zoom(true), GameConfig.CAMERA_ZOOM_MOBILE, 0.001,
		"mobile: kamera lekko oddalona (podobny obszar gry w pionie)")
