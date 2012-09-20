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
    @drawVideo()

  resize: ->
    @el.height = @video.height * 3
    @el.width = @video.width * 3

  drawVideo:  ->
    drawingInterval = setInterval(@getFrameData, 50)

  getFrameData: =>
    @drawFrame()
    @collectPixelData()
    @manipulatePixels()

  drawFrame:  ->
    @context.drawImage(@video, 0, 0, @video.height * 3, @video.width * 3)

  collectPixelData: ->
    @pixels = @context.getImageData(0,0,@el.width, @el.height)

  manipulatePixels: ->
    for pixel, i in @pixels.data by 4
      @pixels.data[i] = pixel + 100
      @pixels.data[i + 1] = @pixels.data[i + 1] - 50
      @pixels.data[i + 2] = @pixels.data[i + 2] + 50
      @pixels.data[i + 3] = @pixels.data[i + 3] * 0.5

class window.Instrument
  constructor: ->
    @audioContext = new webkitAudioContext()
    @audioContext.destination = document.querySelector("#audioOutput")
    @oscillators = []

  createOscillator: (frequency, detune, type) ->
    oscNode = @audioContext.createOscillator()
    @oscillators.push(oscNode)
    oscNode.frequency.value = frequency
    oscNode.detune.value = detune
    switch type
      when "SINE" then set_type = oscNode.SINE
      when "SAW" then set_type = oscNode.SAW
      else set_type = oscNode.SINE

    oscNode.type = set_type
    oscNode.connect(@audioContext.destination)
    oscNode.noteOn(0)

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

  makeNoise: ->
    freq = Math.floor(Math.random()*8001)
    detune = Math.floor(Math.random()*1201)
    @instrument.createOscillator(freq, detune, 'SINE')

  stopNoise: ->
    @instrument.quiet()
