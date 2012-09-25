class window.IncomingVideo
  constructor: (element) ->
    @el = document.querySelector(element)

  setupCam: ->
    getUserMedia = (t, onsuccess, onerror) ->
      if (navigator.getUserMedia)
        return navigator.getUserMedia(t, onsuccess, onerror)
      else if (navigator.webkitGetUserMedia)
        return navigator.webkitGetUserMedia(t, onsuccess, onerror)
      else if (navigator.mozGetUserMedia)
        return navigator.mozGetUserMedia(t, onsuccess, onerror)
      else if (navigator.msGetUserMedia)
        return navigator.msGetUserMedia(t, onsuccess, onerror)
      else
        alert('no getUserMedia implementation')

    URL = window.URL || window.webkitURL
    createObjectURL = URL.createObjectURL || webkitURL.createObjectURL
    if (!createObjectURL)
      alert('no createObjectURL implementation')

    getUserMedia {audio:true, video:true},
        (stream) =>
          url = createObjectURL(stream)
          @el.src = url
        ,(error) ->
          alert('Cannot access webcam.')

class window.VideoCanvas
  constructor: (element) ->
    @el = document.querySelector(element)
    @context =  @el.getContext('2d')

  attachToVideo: (video) ->
    @video = video
    @resize()
    @getFrameData()

  resize: ->
    @el.height = @video.height * 3
    @el.width = @video.width * 3

  getFrameData: =>
    @drawFrame()
    @collectPixelData()

  drawFrame:  ->
    @context.drawImage(@video, 0, 0, @video.height * 3, @video.width * 3)

  collectPixelData: ->
    @pixels = @context.getImageData(0,0,@el.width, @el.height)

  calculateFrequency: ->
    # 118800 pixesl - 29700 per quadrant - 22,720,500 possible total per quad
    # 8000 freq - 14.85 pixels per
    #
    # Column 200 - Row 50
    # imageData.data[((50*(imageData.width*4)) + (200*4)) + 2];
    quad1 = 0

    row = @pixels.width*4
    half_width = (@pixels.width*4)/2
    half_height = (@pixels.height)/2
    for x in [0..half_height]
      for y in [0..half_width] by 4
        current = (x*row)+y
        quad1 += @pixels.data[current]
        quad1 += @pixels.data[current + 1]
        quad1 += @pixels.data[current + 2]

    freq_ratio = quad1 / 22720500
    freq = 8000 * freq_ratio

  calculateDetune: ->
    # 118800 pixels - 29700 per quadrant - 22,720,500 possible total per quad
    # 2400 detune - 49.5 pixels per
    quad2 = 0

    row = @pixels.width*4
    half_width = (@pixels.width*4)/2
    half_height = (@pixels.height)/2
    for x in [0..half_height]
      for y in [half_width..row] by 4
        current = (x*row)+y
        quad2 += @pixels.data[current]
        quad2 += @pixels.data[current + 1]
        quad2 += @pixels.data[current + 2]

    detune_ratio = quad2 / 22720500
    if quad2 < 11360250
      detune_ratio *= -1

    detune = 1200 * detune_ratio

class window.Instrument
  constructor: ->
    @audioContext = new webkitAudioContext()
    @audioContext.destination = document.querySelector("#audioOutput")
    @oscillators = []
    @oscillators = []

  createOscillator: (frequency, detune, type) ->
    oscNode = @audioContext.createOscillator()
    oscNode.frequency.value = frequency
    oscNode.detune.value = detune
    switch type
      when "SINE" then set_type = oscNode.SINE
      when "SAW" then set_type = oscNode.SAW
      else set_type = oscNode.SINE

    oscNode.type = set_type
    oscNode.connect(@audioContext.destination)
    oscNode.noteOn(0)
    @oscillators.push(oscNode)

  updateOscillator: (frequency, detune, type, oscNode) ->
    oscNode.frequency.value = frequency
    oscNode.detune.value = detune
    switch type
      when "SINE" then set_type = oscNode.SINE
      when "SAW" then set_type = oscNode.SAW
      else set_type = oscNode.type
    oscNode.type = set_type

  quiet: ->
    @stopOscillators()

  stopOscillators: ->
    for oscillator in @oscillators
      oscillator.noteOff(0)

class window.Theremin
  constructor: ->
    @video = new IncomingVideo('#videoOutput')
    @video.setupCam()
    @canvas = new VideoCanvas('#canvasOutput')
    @canvas.attachToVideo(@video.el)
    @instrument = new Instrument
    @initOscillators()
    drawingInterval = setInterval(@canvas.getFrameData, 50)
    noiseInterval = setInterval(@makeNoise, 50)

  initOscillators: ->
    freq = @canvas.calculateFrequency()
    detune = @canvas.calculateDetune()
    @instrument.createOscillator(freq, detune, 'SAW')
    freq = @canvas.calculateFrequency()
    detune = @canvas.calculateDetune()
    @instrument.createOscillator(freq, detune, 'SINE')

  makeNoise: =>
    for oscillator in @instrument.oscillators
      freq = @canvas.calculateFrequency()
      detune = @canvas.calculateDetune()
      @instrument.updateOscillator(freq, detune, '', oscillator)

  stopNoise: ->
    @instrument.quiet()
