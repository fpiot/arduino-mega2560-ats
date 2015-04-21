#include "config.hats"
#include "{$TOP}/avr_prelude/kernel_staload.hats"

staload "{$TOP}/SATS/arduino.sats"
staload UN = "prelude/SATS/unsafe.sats"

#define LED 9
#define BUTTON 7
#define DELAY_MS 10.0

typedef state_dat = @{ state= natLt(2), brightness= natLt(256), start_time= ulint }
#define STATE_LEDOFF 0
#define STATE_LEDON  1

fun state_transition (sd:state_dat):state_dat = @{ state= state, brightness= br, start_time= start } where {
  val state = case+ sd.state of
              | STATE_LEDOFF => STATE_LEDON
              | STATE_LEDON  => STATE_LEDOFF
  val br = sd.brightness
  val start = millis ()
}

fun state_helddown (sd:state_dat):state_dat = @{ state= state, brightness= br, start_time= start } where {
  val state = sd.state
  val start = sd.start_time
  val t = if (state = STATE_LEDON) && (millis () - sd.start_time > $UN.cast 500)
            then sd.brightness + 1
            else sd.brightness
  val br = if gt_g0int_int (t, 255) then 0 else $UN.cast t
}

fun do_state (b: natLt(2), old_b:natLt(2), sd:state_dat): state_dat =
  if b = HIGH && old_b = LOW then state_transition sd
  else if b = HIGH && old_b = HIGH then state_helddown sd
       else sd

fun do_action (sd:state_dat): void =
  case+ sd.state of
  | STATE_LEDON  => analogWrite(LED, sd.brightness)
  | STATE_LEDOFF => analogWrite(LED, 0)

implement main () = {
  fun loop (old_b:natLt(2), sd:state_dat) = {
    val b = digitalRead (BUTTON)
    val nsd = do_state (b, old_b, sd)
    val () = delay_ms (DELAY_MS)
    val () = do_action nsd
    val () = loop (b, nsd)
  }
  val () = pinMode (LED, OUTPUT)
  val () = pinMode (BUTTON, INPUT)
  val () = loop (LOW, @{ state= STATE_LEDOFF, brightness= 128, start_time= $UN.cast 0 })
}