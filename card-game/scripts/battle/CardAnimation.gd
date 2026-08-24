## 这个文件是废案。
## This script is abondoned.
extends RefCounted;
class_name CardAnimation;

static func fly_to(card: Control,target: Vector2,duration: float=0.3) -> Tween:
	var tween = card.create_tween();
	tween.set_ease(Tween.EASE_OUT);
	tween.set_trans(Tween.TRANS_QUINT);
	tween.tween_property(card,"global_position",target,duration);
	return tween;
static func play_card_sequence(card: Control,target:Vector2,callback:Callable=Callable()):
	# 飞向目标
	var tween=fly_to(card,target,0.3);
	# 停留
	tween.tween_interval(0.8);
	# 向右下角消失
	tween.tween_property(card, "global_position",Vector2(1280+100,720+100),0.15);
	tween.tween_callback(card.queue_free);
	if callback!=Callable():
		tween.tween_callback(callback);
