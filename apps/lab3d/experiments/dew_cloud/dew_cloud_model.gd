## The 구름과 이슬 spot's model (#92, 2026-11-07; docs/islands/hutton-missions.md 5): the dew point of
## the air by the sea and what cools below it. Two things cool in the lab:
## - a glass cup the child drops ice into (stages 1 and 2): every cube cools the cup COOL_PER_ICE
##   (the cup glides there at CUP_RATE, the lab shows it cool), and dew forms on the glass once the
##   cup is at or below the air's dew point;
## - a parcel of air the child drags up the mountain (stage 3): it cools DRY_LAPSE per km as it rises
##   and its dew point falls DEW_LAPSE per km, so it meets its dew point at the cloud base,
##   125 m × (temperature − dew point); above it the vapour condenses into a cloud.
## The condition ("air": humid or dry day) is the air's relative humidity at the same temperature:
## the humid day's air holds more water vapour, so its dew point is higher (a cup needs less ice, a
## parcel makes its cloud lower).
##
## The textbook relations (tests/earth_textbook_values.json "dew_point", tests/dew_cloud_checks.gd):
## - saturation vapour pressure over water, Magnus form with the WMO coefficients (WMO-No. 8, 2008,
##   Annex 4.B): e_s(t) = 6.112 hPa × exp(17.62 t / (243.12 + t)), t in °C;
## - the saturation water vapour amount (포화 수증기량, g of vapour per kg of dry air at sea level):
##   w_s = 622 × e_s / (P − e_s), P = 1013.25 hPa (0 °C 3.8, 10 °C 7.6, 20 °C 14.7, 30 °C 27.1);
## - relative humidity (상대 습도) = vapour amount / saturation amount × 100;
## - the dew point (이슬점) is the temperature whose saturation amount is the air's vapour amount;
## - a rising parcel: 건조 단열 감률 about 10 °C/km, 이슬점 감률 about 2 °C/km, so the cloud base
##   (상승 응결 고도) is H = 125 m × (T − Td). Above it the cloud's air cools at about MOIST_LAPSE.
##
## Status (what the stages judge; the lab draws the rest):
## - "ready": nothing cooled yet (no ice in the cup, the parcel at the mountain's foot);
## - the cup (no parcel lifted): "dew" at or below the dew point, else "clear";
## - the parcel lifted (it takes over): "cloud" at or above the cloud base, else "rising".
## No number of degrees is shown: the lab draws the cup's cold, the dew and the cloud.
class_name DewCloudModel
extends EarthModel

## The air by the sea (°C): a summer day.
const AIR_TEMP := 25.0
## The two days' relative humidity (%) at AIR_TEMP: humid (dew point about 20.4 °C) and dry (about
## 10.7 °C).
const HUMID := 75.0
const DRY := 40.0
## Every ice cube cools the cup this much (°C) from the air's temperature; the cup takes at most
## ICE_MAX cubes. The humid day's dew needs 2 cubes (one leaves the cup at 21 °C, over its 20.4 °C),
## the dry day's 4 (three leave it at 13 °C, over its 10.7 °C).
const COOL_PER_ICE := 4.0
const ICE_MAX := 5
## The cup's temperature glides at this rate (°C/s): a cube cools it in under a second.
const CUP_RATE := 5.0
## The mountain's summit above the sea (m). The humid parcel's cloud base is about 577 m (72% of the
## way up), the dry one's about 1780 m (over the summit: no cloud on a dry day).
const SUMMIT_M := 800.0
## Magnus coefficients (WMO-No. 8, 2008: over water, -45..60 °C).
const MAGNUS_E0 := 6.112
const MAGNUS_B := 17.62
const MAGNUS_C := 243.12
## Sea-level pressure (hPa) and the ratio of the molar masses of water and dry air (× 1000: g/kg).
const SEA_PRESSURE := 1013.25
const VAPOUR_RATIO := 622.0
## Lapse rates (°C per km): dry air, its dew point, and saturated (cloud) air.
const DRY_LAPSE := 10.0
const DEW_LAPSE := 2.0
const MOIST_LAPSE := 5.0
## The cup's dew is "full" this far (°C) below the dew point (the lab's drops and their size).
const DEW_FULL := 6.0
## The cloud is full grown this far (m) over its base.
const CLOUD_FULL_M := 150.0


func _init() -> void:
	define_input("air", AIR_TEMP)            # °C, the air by the sea
	define_input("humidity", HUMID)          # %, relative humidity at the air's temperature
	define_input("ice", 0.0)                 # cubes in the cup
	define_input("cup", AIR_TEMP, CUP_RATE)  # °C, the cup (glides to the ice's)
	define_input("lift", 0.0)                # 0..1 of the way from the mountain's foot to its summit


# --- the textbook relations (pure) ----------------------------------------------------------------

## Saturation vapour pressure over water at `t` °C (hPa).
static func saturation_pressure(t: float) -> float:
	return MAGNUS_E0 * exp(MAGNUS_B * t / (MAGNUS_C + t))


## The temperature (°C) whose saturation vapour pressure is `e` hPa.
static func temperature_of_pressure(e: float) -> float:
	var k := log(e / MAGNUS_E0)
	return MAGNUS_C * k / (MAGNUS_B - k)


## The saturation water vapour amount at `t` °C (g of vapour per kg of dry air, at sea level).
static func saturation_amount(t: float) -> float:
	var e := saturation_pressure(t)
	return VAPOUR_RATIO * e / (SEA_PRESSURE - e)


## The dew point (°C) of air holding `amount` g/kg of vapour: the temperature it saturates at.
static func dew_point_of_amount(amount: float) -> float:
	return temperature_of_pressure(amount * SEA_PRESSURE / (VAPOUR_RATIO + amount))


## Relative humidity (%) of air at `t` °C holding `amount` g/kg.
static func relative_humidity(t: float, amount: float) -> float:
	return amount / saturation_amount(t) * 100.0


## The dew point (°C) of air at `t` °C and `humidity` % relative humidity.
static func dew_point(t: float, humidity: float) -> float:
	return dew_point_of_amount(saturation_amount(t) * humidity / 100.0)


## The cloud base (m above where the parcel starts) of air at `t` °C with dew point `td`: where the
## rising air's temperature (DRY_LAPSE) meets its dew point (DEW_LAPSE), 125 m per °C.
static func cloud_base(t: float, td: float) -> float:
	return maxf(0.0, t - td) / (DRY_LAPSE - DEW_LAPSE) * 1000.0


## A parcel from the ground at `t` °C (dew point `td`) at `height` m: its temperature (°C), DRY_LAPSE
## up to its cloud base and MOIST_LAPSE above.
static func parcel_temperature(t: float, td: float, height: float) -> float:
	var base := cloud_base(t, td)
	if height <= base:
		return t - DRY_LAPSE * height / 1000.0
	return t - DRY_LAPSE * base / 1000.0 - MOIST_LAPSE * (height - base) / 1000.0


## The parcel's dew point at `height` m: DEW_LAPSE up to its cloud base, then its temperature (its
## air is saturated in the cloud).
static func parcel_dew_point(t: float, td: float, height: float) -> float:
	return minf(td - DEW_LAPSE * height / 1000.0, parcel_temperature(t, td, height))


# --- the lab's state ------------------------------------------------------------------------------

## The air's dew point now (°C).
func air_dew_point() -> float:
	return dew_point(input("air"), input("humidity"))


## A humid day (the condition 눅눅한 날).
func humid() -> bool:
	return input("humidity") >= (HUMID + DRY) * 0.5


## The cup's temperature the ice in it brings it to (°C).
func cup_target() -> float:
	return input("air") - COOL_PER_ICE * input("ice")


## One more ice cube into the cup (none past ICE_MAX): the cup glides to its new temperature.
## Returns whether it went in.
func add_ice() -> bool:
	if input("ice") >= ICE_MAX:
		return false
	set_input("ice", input("ice") + 1.0)
	glide_to("cup", cup_target())
	return true


func ice_count() -> int:
	return int(input("ice"))


## The cup is at or below the dew point: dew on the glass.
func cup_dewy() -> bool:
	return input("cup") <= air_dew_point()


## How much dew (0..1): none above the dew point, full DEW_FULL below it.
func dew_share() -> float:
	return clampf((air_dew_point() - input("cup")) / DEW_FULL, 0.0, 1.0)


## How cold the cup is (0 at the air's temperature .. 1 with ICE_MAX cubes in).
func cold_share() -> float:
	return clampf((input("air") - input("cup")) / (COOL_PER_ICE * ICE_MAX), 0.0, 1.0)


## The parcel's height above the sea (m).
func parcel_height() -> float:
	return clampf(input("lift"), 0.0, 1.0) * SUMMIT_M


## The parcel's cloud base above the sea (m) and as a share of the way up (may be over 1: no cloud
## below the summit).
func parcel_base() -> float:
	return cloud_base(input("air"), air_dew_point())


func base_share() -> float:
	return parcel_base() / SUMMIT_M


## The parcel's temperature and dew point now (°C).
func parcel_temp() -> float:
	return parcel_temperature(input("air"), air_dew_point(), parcel_height())


func parcel_dew() -> float:
	return parcel_dew_point(input("air"), air_dew_point(), parcel_height())


## The parcel is at or over its cloud base: its vapour has condensed.
func cloudy() -> bool:
	return input("lift") > 0.0 and parcel_height() >= parcel_base()


## How grown the cloud is (0..1): CLOUD_FULL_M over its base is full.
func cloud_share() -> float:
	if not cloudy():
		return 0.0
	return clampf((parcel_height() - parcel_base()) / CLOUD_FULL_M, 0.0, 1.0) * 0.6 + 0.4


## How cool the rising parcel is (0 at the foot .. 1 at the summit).
func parcel_cool_share() -> float:
	return clampf(input("lift"), 0.0, 1.0)


func status() -> String:
	if input("lift") > 0.0:
		return "cloud" if cloudy() else "rising"
	if input("ice") > 0.0:
		return "dew" if cup_dewy() else "clear"
	return "ready"
