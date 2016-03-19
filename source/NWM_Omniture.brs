' ******************************************************
' Copyright Roku 2011,2012,2013.
' All Rights Reserved
' ******************************************************
'
' An Omniture client
'
' USAGE
'   omniture = NWM_Omniture("http://www.example.com/omniture_suite_name/")
'   ' persistent params will be added to every event
'   omniture.persistentParams.ce = "UTF-8" 
'
'   params = { ' a set of params unique to this event
'     pageName: "roku:mychannel:launch"
'     ch: "roku:mychannel"
'     v2: "D=pageName"
'     sv:       "roku"
'     c6:       "roku:mychannel"
'     v6:       "D=c6"
'     c7:       "roku:mychannel"
'     v7:       "D=c7"
'     c8:       "roku:mychannel"
'     v8:       "D=c8"
'     c9:       "roku:mychannel"
'     v9:       "D=c9"
'     v2:       "D=pageName"
'     h1:       "D=pageName"
'     h3:       "entertainment:roku:mychannel:launch"
'     events:       "event2,event12"
'   }
'   omniture.LogEvent(params)
'

function NWM_Omniture(baseURL, sendVID = false)
 '   print "|-o-||-o-|" baseURL
  this = {
    debug: true
'    debug: false
    baseURL:    baseURL
    sendVID: sendVID
    xfers: []
    port: CreateObject("roMessagePort")
    
    ' params that should be sent with every call
    persistentParams: {}
    
    ' Omniture is case-sensitive
    ' any params that are not all lowercase should be mapped
    ' to their correct capitalization here
    caseMap: {
      pagename: "pageName"
    }
    
    LogEvent: NWM_OMNITURE_LogEvent
    ProcessMessages: NWM_OMNITURE_ProcessMessages
  }
  
  ' the vid parameter is a visitor ID that some Omniture setups need for accurate visitor metrics 
  if this.sendVID
    di = CreateObject("roDeviceInfo")
    ba = CreateObject("roByteArray")
    ba.FromASCIIString(di.GetDeviceUniqueId())
    digest = CreateObject("roEVPDigest") 
    digest.Setup("sha1")
    this.vid = digest.Process(ba)
  end if
  
  return this
end function

function NWM_OMNITURE_LogEvent(params)
  if m.debug then ? "NWM_Omniture: new request"
  if m.debug
    PrintAA(m.persistentParams)
    PrintAA(params)
  end if
  
  m.ProcessMessages()

  xfer = CreateObject("roURLTransfer")
  xfer.SetPort(m.port)
  
  if m.cookie <> invalid and m.cookie <> ""
    if m.debug then ? "NWM_Omniture: Setting cookie: " + m.cookie
    xfer.AddHeader("cookie", m.cookie)
  end if
  
  timestamp = CreateObject("roDateTime").asSeconds().ToStr()
  url = m.baseURL + timestamp + "?"
  
  if m.sendVID
    url = url + "vid=" + m.vid + "&"
  end if

  for each param in m.persistentParams
    if m.caseMap.DoesExist(param)
      param = m.caseMap.Lookup(param)
    end if
    url = url + param + "=" + xfer.Escape(m.persistentParams.Lookup(param)) + "&"
  next
  for each param in params
    if m.caseMap.DoesExist(param)
      param = m.caseMap.Lookup(param)
    end if
    url = url + param + "=" + xfer.Escape(params.Lookup(param)) + "&"
  next
  url = url.Left(url.Len() - 1)
  
  xfer.SetURL(url)
  if m.debug then ? "NWM_Omniture: Sending request: " + xfer.GetURL()
  
  result = xfer.AsyncGetToString()
    
  if m.xfers.Count() > 9
    m.xfers.Shift() ' get rid of the oldest xfer
  end if
  m.xfers.Push(xfer)
  
  if m.debug then ? "NWM_Omniture: xfer array count " + m.xfers.Count().ToStr()
  
  return result
end function

sub NWM_OMNITURE_ProcessMessages()
  while true
    msg = m.port.GetMessage()
    if msg = invalid
      exit while
    end if
    if m.debug then ? "NWM_Omniture: got " + type(msg)
    
    if type(msg) = "roUrlEvent" ' should always be true
      headers = msg.GetResponseHeadersArray()
      for each header in headers
        if header.DoesExist("set-cookie")
          cookies = ValidStr(header.Lookup("set-cookie"))
          rx = Createobject("roRegEx", "(s_vi=.*?);", "")
          matches = rx.Match(cookies)
          if matches.Count() > 1
            m.cookie = matches[1]
            if m.debug then ? "NWM_Omniture: found cookie " + m.cookie
            exit for
          end if
        end if
      next
    end if
  end while
end sub
