pako = require 'pako'

getElementValue = (id) ->
  dropdown = document.getElementById(id)
  return dropdown.value
setElementValue = (id, val) ->
  dropdown = document.getElementById(id)
  dropdown.value = val
setElementText = (id, text) ->
  dropdown = document.getElementById(id)
  dropdown.innerHTML = text

class CubeArt
  constructor: ->
    console.log "CubeArt constructed"

    @canvas = document.getElementById('cubeart')
    @w = @canvas.width
    @h = @canvas.height
    @ctx = @canvas.getContext("2d")

    @imageURL = ""
    pixelCanvas = document.createElement('canvas')
    pixelCanvas.width = 16
    pixelCanvas.height = 16
    @pixels = pixelCanvas.getContext('2d')

    document.getElementById("u").addEventListener('change', (event) =>
      @upload()
      # console.log "onchange u: '#{filename}'"
      # @save()
    )
    document.getElementById("b").addEventListener('change', (event) =>
      console.log "onchange b"
      @save()
    )
    for i in [0...6]
      document.getElementById("c#{i}").addEventListener('change', (event) =>
        console.log "onchange c#{i}"
        @save()
      )

    window.addEventListener('hashchange', (event) =>
      @load()
    )
    @load()

  upload: ->
    @data.u = null
    f = document.getElementById("u").files[0]
    if f.size > 1024
      alert("File is too big!")
      setElementValue("u", "")
      return

    @data.u = ""
    @data.n = f.name
    reader = new FileReader()
    reader.onloadend = =>
      console.log reader.result
      @data.u = reader.result
      @save()
    reader.readAsDataURL(f)

  load: ->
    hash = decodeURIComponent(window.location.hash.replace(/^#\/?|\/$/g, ''))
    console.log "load: #{hash}"
    data = null
    try
      @data = JSON.parse(pako.inflate(atob(hash), { to: 'string' }))
    catch
      console.log "failed to parse stuff"

    if not @data
      @data = {}
    if not @data.b?
      @data.b = "b"
    if not @data.p?
      @data.p = "rgbyow"
    if not @data.n?
      @data.n = ""
    if not @data.u?
      @data.u = ""

    console.log @data

    setElementText('n', @data.n)
    setElementValue('b', @data.b)
    for i in [0...6]
      color = @data.p.charAt(i)
      # console.log "color #{i}: #{color}"
      setElementValue("c#{i}", color)

    @update()

  save: ->
    @data.b = getElementValue("b")
    @data.p = ""
    for i in [0...6]
      @data.p += getElementValue("c#{i}")
    @update()

  update: ->
    newHash = btoa(pako.deflate(JSON.stringify(@data), { to: 'string' }))
    window.location.hash = newHash

    if @imageURL != @data.u
      @imageURL = @data.u
      if @imageURL.length > 0
        image = new Image()
        image.crossOrigin = "anonymous"
        image.onload = =>
          console.log "load finished, redrawing"
          @pixels.beginPath()
          @pixels.rect(0, 0, 16, 16)
          @pixels.fillStyle = "#000000"
          @pixels.fill()
          @pixels.drawImage(image, 0, 0, 16, 16)
          @draw()
        image.src = @data.u

    @draw()

  charToColor: (char) ->
    switch char
      when 'r' then '#B71234'
      when 'g' then '#009B48'
      when 'b' then '#0046AD'
      when 'y' then '#FFD500'
      when 'o' then '#FF5800'
      when 'w' then '#ffffff'
      else '#000000'

  draw: ->
    if @image == null
      @drawFill(0, 0, @w, @h, "#333333")
      @drawTextCentered("Provide a 16x16 image URL.", @w / 2, @h / 10, "#555555")
      return

    @drawFill(0, 0, @w, @h, "#000000")

    # Canvas must be: (cubieSize * 16) + (outerBorder * 5)
    cubieSize = 32
    innerBorder = 1
    outerBorder = 5

    nextColorIndex = 0
    palette = {}
    for j in [0...18]
      for i in [0...18]

        if (i < 1) or (j < 1) or (i > 16) or (j > 16)
          # innerBorder
          color = @charToColor(@data.b)
        else
          pixel = @pixels.getImageData(i-1, j-1, 1, 1).data
          color = "rgba(#{pixel[0]}, #{pixel[1]}, #{pixel[2]}, #{pixel[3]})"
          if not palette[color]?
            colorIndex = Math.min(nextColorIndex, 5)
            nextColorIndex += 1
            palette[color] = @charToColor(@data.p.charAt(colorIndex))
          color = palette[color]

        x = (i * cubieSize) + innerBorder
        y = (j * cubieSize) + innerBorder
        w = cubieSize - (innerBorder * 2)
        h = cubieSize - (innerBorder * 2)

        outerBorderLocations = [2, 5, 8, 11, 14]
        for l in outerBorderLocations
          if i > l then x += outerBorder
          if j > l then y += outerBorder

        @drawFill(x, y, w, h, color)

    console.log "Image has #{nextColorIndex} colors"

  drawFill: (x, y, w, h, color) ->
    @ctx.beginPath()
    @ctx.rect(x, y, w, h)
    @ctx.fillStyle = color
    @ctx.fill()

  drawTextCentered: (text, cx, cy, color, size = @h / 20) ->
    @ctx.font = "#{Math.floor(size)}px monospace"
    @ctx.fillStyle = color
    @ctx.textAlign = "center"
    @ctx.fillText(text, cx, cy + (size / 2))

window.cubeArtInit = ->
  console.log "cubeArtInit()"
  window.cubeart = new CubeArt
