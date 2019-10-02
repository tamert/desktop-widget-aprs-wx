callsign='LTBL' # WX CALLSING
key='YOUR_API_KEY' # visit http://aprs.fi/page/api
api='https://api.aprs.fi/api/'

style: """
  top: 5%
  left: 50%
  margin: 0 0 0 -100px
  font-family: Berlin, Helvetica Neue
  color: #FFF

  .temp
    font-size: 20px
    text-anchor: middle
    alignment-baseline: baseline

  .outline
    fill: none
    stroke: #fff
    stroke-width: 0.5

  .icon-bg
    fill: rgba(#FFF, 0.8)

  #icon
    fill: rgba(#FFF, 0.8)
    position: absolute
    margin-top: 48px
    margin-left: 55px 

  .summary
    text-align: center
    border-top: 1px solid #FFF
    padding: 12px 0 0 0
    margin-top: -20px
    font-size: 14px
    max-width: 300px
    line-height: 1.4


  .date, .location
    color : #FFF
    stroke: #FFF
    stroke-width: 1px
    font-size: 12px
    text-weight: bold
    text-anchor: middle

  .date.mask
    stroke: #999
    stroke-width: 5px


  .station
    color : #FFF
    stroke: #FFF
    stroke-width: 1px
    font-size: 12px
"""

command: "echo {}"

render: (o) -> """
  <img src="wx.svg" id='icon' width='80px'>
  <svg #{@svgNs} width="200px" height="200px" >
    <defs xmlns="http://www.w3.org/2000/svg">
      <mask id="icon_mask">
        <rect width="100px" height="100px" x="50" y="50" fill="#fff"
              transform="rotate(45 100 100)"/>

        <text class="temp"
              x="50%" y='67%' dx='3px'></text>
      </mask>
      <mask id="text_mask">
        <rect x='0' y="0" width="200px" height="200px" fill='#fff'/>
        <text class="location mask"
            textLength='90px'
            transform="rotate(-45 100 100)"
            x="50%" y='42px'></text>
        <text class="date mask"
            textLength='90px'
            transform="rotate(45 100 100)"
            x="50%" y='42px'></text>
      </mask>
    </defs>


    <rect class='icon-bg' width="200px" height="200px" x="0" y="0"

          mask="url(#icon_mask)"/>

    <text class="location"
          textLength='90px'
          transform="rotate(-45 100 100)"
          x="50%" y='42px'></text>

    <text class="date"
          textLength='90px'
          transform="rotate(45 100 100)"
          x="50%" y='42px'></text>

    <text class="station"
          x="" y='169px'>loading...</text>
  </svg>

  <div class='summary'></div>

"""

svgNs: 'xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"'


command: (callback) ->
  isOnline = window.navigator.onLine
  storage = window.localStorage
  isCache = storage.getItem('isCache')
  if(isCache==null)
    isCache = true
  else
    storage.setItem('isCache', (parseInt(isCache)+1))
    if parseInt(storage.getItem('isCache'))>50
      isCache = true
    else
      isCache = false

  #console.log isCache

  if isOnline && isCache 
    #console.log 'api'
    cmd = "curl -s '"+api+"get?name="+callsign+"&what=wx&apikey="+key+"&format=json'"
    @run cmd, (error, data) ->
      storage.setItem('meteoroloji', data)
      storage.setItem('isCache', 0)

      callback(error, data)

  else
    #console.log 'cache'
    callback(null, storage.getItem('meteoroloji'))

afterRender: (domEl) ->
  geolocation.getCurrentPosition (e) =>
    coords     = e.position.coords
    [lat, lon] = [coords.latitude, coords.longitude]
  
    @refresh()

degToCompass: (num) ->
  val = parseInt((num/22.5)+.5)
  arr = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
  return arr[(val % 16)]

update: (output, domEl) ->
  storage = window.localStorage
  
  now  = JSON.parse(storage.meteoroloji)
  now_arr = now.entries[0]

  #console.log now.entries

  if now_arr

    d = new Date()
    n = d.getDay()

    #console.log now_arr
    $(domEl).find('.temp').prop 'textContent', now_arr.temp+'°'
    $(domEl).find('.station').prop 'textContent', now_arr.name
    $(domEl).find('.location').prop('textContent', 'humidity: '+now_arr.humidity)
    $(domEl).find('.date').prop('textContent',@dayMapping[n])
    $(domEl).find('.summary').prop('textContent', 'Wind : '+  @degToCompass(now_arr.wind_direction) + ' ' + now_arr.wind_speed + ' KM ' )

  return

dayMapping:
  0: "Sunday"
  1: "Monday"
  2: "Tuesday"
  3: "Wednesday"
  4: "Thursday"
  5: "Friday"
  6: "Saturday"

getDate: (utcTime) ->
  date  = new Date(0)
  date.setUTCSeconds(utcTime)
  date
