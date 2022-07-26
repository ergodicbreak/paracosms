-- paracosms[boros]
--
--
-- llllllll.co/t/?
--
--
--
--    ▼ instructions below ▼
-- K3 start/stops sample
-- (hold length = fade)
-- K1+K3 primes recording
-- (when primed, starts)
--
-- E1 select sample
-- K1+E1 select running sample
--
-- K2/K1+K2 selects parameters
-- E2/E3 modulate parameter
-- K1+E2/E3 modulate more
--
--
--
--

style=function()

end

blocks={
  {folder="/home/we/dust/audio/paracosms/row1",params={amp_strength=0.2,amp=0.5,pan_strength=0.3,send1=1,send2=0}},
  {folder="/home/we/dust/audio/paracosms/row2",params={amp=1.0,send1=0,send2=1}},
  {folder="/home/we/dust/audio/paracosms/row3"},
  {folder="/home/we/dust/audio/paracosms/row4"},
  {folder="/home/we/dust/audio/paracosms/row5"},
  {folder="/home/we/dust/audio/paracosms/row6"},
  {folder="/home/we/dust/audio/paracosms/row7"},
}

substance=function()

end

-- do not edit this
include("lib/paracosms")