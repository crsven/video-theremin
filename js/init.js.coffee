$ ->
  exports = window
  exports.theTheremin = new Theremin
  $('#noiseButton').click ->
    window.theTheremin.makeNoise()
  $('#noNoiseButton').click ->
    window.theTheremin.stopNoise()
