ilName='İzmir' #default
refreshFrequency: 60000
istNo = '15000'

style: """
  top: 5%
  left: 50%
  margin: 0 0 0 -100px
  font-family: Berlin, Helvetica Neue
  color: #FFF

  @font-face
    font-family Weather
    src url(icons.svg) format('svg')

  .icon
    font-family: Weather
    font-size: 40px
    text-anchor: middle
    alignment-baseline: middle

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
"""

command: "echo {}"

render: (o) -> """
  <svg #{@svgNs} width="200px" height="200px" >
    <defs xmlns="http://www.w3.org/2000/svg">
      <mask id="icon_mask">
        <rect width="100px" height="100px" x="50" y="50" fill="#fff"
              transform="rotate(45 100 100)"/>
        <text class="icon"
              x="50%" y='45%'></text>

        <text class="temp"
              x="50%" y='65%' dx='3px'></text>
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
  </svg>
  <div class='summary'></div>
"""

svgNs: 'xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"'


command: (callback) ->
  isOnline = window.navigator.onLine
  console.log isOnline
  storage = window.localStorage

  storage.setItem('online', false)

  if isOnline
    cmd = "curl -s 'http://212.175.180.28/api/merkezler?il="+ilName+"'"
    @run cmd, (error, data) ->
      arr = JSON.parse(data)
      sondurumIstNo =  arr[0].sondurumIstNo
      storage.setItem('sondurumIstNo', sondurumIstNo)

    cmd = "curl -s 'http://212.175.180.28/api/sondurumlar?istno="+storage.sondurumIstNo+"'"
    @run cmd, (error, data) ->
      storage.setItem('meteoroloji', data)

      callback(error, data)

  else
    callback(null, storage.getItem('meteoroloji'))

afterRender: (domEl) ->
  geolocation.getCurrentPosition (e) =>
    coords     = e.position.coords
    [lat, lon] = [coords.latitude, coords.longitude]
  
    @refresh()
    
iconMapping:
  "A": "\uf00d"
  "AB": "\uf00d"
  "PB": "\uf013"
  "CB": "\uf013"
  "HY": "\uf019"
  "Y": "\uf019"
  "KY": "\uf019"
  "KKY": "\uf01b"
  "HKY": "\uf01b"
  "K": "\uf01b"
  "KYK": "\uf01b"
  "HSY": "\uf019"
  "SY": "\uf019"
  "KSY": "\uf019"
  "MSY": "\uf019"
  "DY": "\uf019"
  "GSY": "\uf019"
  "KGSY": "\uf019"
  "SIS": "\uf014"
  "PUS": "\uf014"
  "DNM": "\uf014"
  "KF": "\uf021"
  "R": "\uf021"
  "GKR": "\uf021"
  "KKR": "\uf021"
  "SCK": "\uf00c"
  "SGK": "\uf019"

degToCompass: (num) ->
  val = parseInt((num/22.5)+.5)

  arr = ["Kuzey'den","Kuzeydoğu'dan","Kuzeydoğu'dan","Kuzeydoğu'dan","Doğu'dan","Güneydoğu'dan", "Güneydoğu'dan", "Güneydoğu'dan","Güney'den","Güneybatı'dan","Güneybatı'dan","Güneybatı'dan","Batı'dan","Kuzeybatı'dan","Kuzeybatı'dan","Kuzeybatı'dan"]
  return arr[(val % 16)]

update: (output, domEl) ->
  storage = window.localStorage
  
  now  = JSON.parse(storage.meteoroloji)
  now_arr = now[0]

  console.log now

  if now_arr

    d = new Date()
    n = d.getDay()

    $(domEl).find('.temp').prop 'textContent', now_arr.sicaklik+'°'
    $(domEl).find('.location').prop('textContent', 'Nem: '+now_arr.nem)
    $(domEl).find('.icon')[0]?.textContent = @iconMapping[now_arr.hadiseKodu]
    $(domEl).find('.date').prop('textContent',@dayMapping[n])
    $(domEl).find('.summary').prop('textContent', 'Rüzgar : '+  @degToCompass(now_arr.ruzgarYon) + ' ' + now_arr.ruzgarHiz.toFixed(0) + ' KM ' )

  return

  
dayMapping:
  0: 'Pazar'
  1: 'Pazartesi'
  2: 'Salı'
  3: 'Çarşamba'
  4: 'Perşembe'
  5: 'Cuma'
  6: 'Cumartesi'


getIcon: (data) ->
  return @iconMapping['unknown'] unless data

  if data.icon.indexOf('cloudy') > -1
    if data.cloudCover < 0.25
      @iconMapping["clear-day"]
    else if data.cloudCover < 0.5
      @iconMapping["mostly-clear-day"]
    else if data.cloudCover < 0.75
      @iconMapping["partly-cloudy-day"]
    else
      @iconMapping["cloudy"]
  else
    @iconMapping[data.icon]

getDate: (utcTime) ->
  date  = new Date(0)
  date.setUTCSeconds(utcTime)
  date

