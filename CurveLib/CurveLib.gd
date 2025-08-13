class_name CurveLib extends Node

static var Main:CurveLib

@export var ShakeCurveA:Curve
@export var BottleSpinCurve:Curve
@export var EnemyFalloffCurve:Curve
@export var FlashCurve:Curve
@export var SpeedBuildupCurve:Curve

@export var SpinFalloffCurve:Curve
@export var StrikeCurve:Curve
@export var TextPopupCurve:Curve

func _ready() -> void:
	Main = self
