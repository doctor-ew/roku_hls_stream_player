Sub Main()
    theme = initTheme()
    gridstyle = "four-column-flat-landscape"
    displaystyle = "scale-to-fill"
    posterstyle = "landscape"

    while gridstyle <> "" and displaystyle <> ""
        screen=preShowGridScreen(gridstyle, displaystyle,posterstyle)
        gridstyle = showGridScreen(screen, gridstyle, displaystyle, theme)
    end while

End Sub

Sub initTheme()
    app = CreateObject("roAppManager")
    theme = app.SetTheme(getConfigs("theme"))
    sendOmniture("launch",invalid)
End Sub

Function getConfigs(confKey as string) as Object
    request = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    date = CreateObject("roDateTime")
    request.SetMessagePort(port)
    request.SetUrl("http://www.adultswim.com/gen/roku/config.json?cb=" + date.ToISOString() )
    
    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, port)
            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()
                if (code = 200)
                    themeConfig = CreateObject("roArray", 10, true)
                    confTheme = CreateObject("roAssociativeArray")
                    confStream = CreateObject("roAssociativeArray")
                    json = ParseJSON(msg.GetString())
                    objTheme = {}
                    objStream = {}
                    objNakedFish = {}
                    
                    for each oTheme in json[confKey]
                        for each theme in oTheme
                            confTheme[theme] = oTheme[theme]
                            themeConfig.push(confTheme)
                        end for
                    end for
                    return confTheme
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif
    return invalid
End Function

Function preShowGridScreen(style as string, display as string,poster as string) As Object
    m.port=CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(m.port)
    screen.SetDisplayMode(display)
    screen.SetListPosterStyles(poster)
    screen.SetBreadcrumbEnabled(false)
    screen.SetGridStyle(style)

    return screen
End Function

Function showGridScreen(screen As Object, gridstyle as string, displaystyle as string, theme as Object) As string

    screen.setupLists(1)
    screen.SetDescriptionVisible(true)
    showList = getStreams(getConfigs("streams"))
    full_playlist = get_playlist(getConfigs("streams"))
    naked_fish_stream = getConfigs("other_streams")
     print "|-o-||-o-| naked_fish_stream ";  naked_fish_stream ; naked_fish_stream["naked fish"]
'    screen.SetContentList(0,get_playlist(getConfigs("streams")))
    screen.SetContentList(0,full_playlist)
    screen.Show()

    while true
        msg = wait(0, m.port)
        if type(msg) = "roGridScreenEvent" then
            if msg.isListItemFocused() then
'            sendOmniture("video-focus",showList[msg.GetData()])
            print "|-o-| selected: ";AnyToString(msg.GetData());AnyToString(showList[msg.GetData()])
            else if msg.isListItemSelected() then
                row = msg.GetIndex()
                selection = msg.getData()

                screen.SetBreadcrumbText("Now Playing", showList[msg.GetData()].Title)
                 DisplayVideo(showList[msg.GetData()].streamUri, showList[msg.GetData()].Title)  
            else if msg.isScreenClosed() then
                print "screen closed: "; msg.GetMessage()
                return ""
            else if msg.isRequestFailed()
                print "play failed: "; msg.GetMessage()
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        end If
    end while
End Function

Function displayVideo(fcstream as String, fcTitle as String)
    p = CreateObject("roMessagePort")
    clock = CreateObject("roTimespan")
    player = CreateObject("roVideoPlayer")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)
    bitrates  = [0]    

    date = CreateObject("roDateTime")
    hour = date.getHours()

    qualities = ["HD"]
    streamformat = "hls"
    title = fcTitle
    
    videoclip = CreateObject("roAssociativeArray")
    videoclip.StreamBitrates = bitrates

    videoclip.StreamUrls = fcstream

    videoclip.StreamQualities = qualities
    videoclip.StreamFormat = streamformat
    videoclip.Title = title

    video.SetContent(videoclip)
    video.show()
    print "|-o-| Now Playing: ";videoclip
    sendOmniture("video-start",videoclip)

    lastSavedPos   = 0
    statusInterval = 10 

     while true
        msg = wait(0, video.GetMessagePort())
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 
                print "!!!! isScreenClosed ";AnyToString(msg.isScreenClosed());" :: ";AnyToString(msg)
                exit while
            else if msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
                if nowpos > 10000
                    
                end if
                if nowpos > 0
                    if abs(nowpos - lastSavedPos) > statusInterval
                        lastSavedPos = nowpos
                    end if
                end if
                print "@@@@ PlaybackPosition ";AnyToString(msg.isPlaybackPosition());" :: ";AnyToString(msg)
            else if msg.isRequestFailed()
            print "!!!! request Failed ";AnyToString(msg.isRequestFailed());" :: ";AnyToString(msg)
            else
                print "#### Unknown :: ";AnyToString(msg)
            endif
        end if
    end while
End Function

Function getStreams(objStream As Object) As Object
    showList = get_playlist(objStream)
    return showList
End Function
    
Function get_playlist(objStream As Object) as object
    request = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    request.SetUrl(objStream.astv) '"http://www.adultswim.com/videos/app/astv"
    
    print "!@#$ |-o-| "; objStream.astv
    
    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, port)
            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()
                if (code = 200)
                    playlist = CreateObject("roArray", 10, true)
                    json = ParseJSON(msg.GetString())
                           button = {
                                ID: "naked fish",
                                Title: "naked fish",
                                SDSmallIconUrl: json.channels[0].appImageURL,
                                HDSmallIconUrl: json.channels[0].imageURL,
                                HDBackgroundImageUrl: json.channels[0].imageURL,
                                SDBackgroundImageUrl: json.channels[0].appImageURL,            
                                HDPosterUrl: json.channels[0].imageURL,
                                SDPosterUrl: json.channels[0].appImageURL,            
                                ShortDescriptionLine1: json.channels[0].subheading,
                                ShortDescriptionLine2: json.channels[0].description,
                                Description: json.channels[0].description,
                                streamUri: get_stream_uri(getConfigs("other_streams")["naked fish"])
                                ' streamUri: get_stream_uri(objStream.streamURI + channel.video.videoPlaybackID)                         
                               
                            }
                            print "|-x-||-x-| streamUri: ";button.streamUri
                            playlist.push(button)
                    for each channel in json.channels
                        if(channel.type = "live-show" or channel.type = "marathon") 
                            button = {
                                ID: channel.id,
                                Title: channel.title,
                                SDSmallIconUrl: channel.appImageURL,
                                HDSmallIconUrl: channel.appImageURL,
                                HDBackgroundImageUrl: channel.appImageURL,
                                SDBackgroundImageUrl: channel.appImageURL,            
                                HDPosterUrl: channel.appImageURL,
                                SDPosterUrl: channel.appImageURL,            
                                ShortDescriptionLine1: channel.description,
                                ShortDescriptionLine2: channel.description,
                                Description: channel.description,
                                streamUri: get_stream_uri(objStream.streamURI + channel.video.videoPlaybackID)             
                               
                            }
                            playlist.push(button)
                        endif
                    end for
                    return playlist
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif
    return invalid
End Function

Function get_stream_uri(stream_uri as String) as object
    request = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    request.SetUrl(stream_uri)
    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, port)
            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()
                if (code = 200)
                    video = CreateObject("roXMLElement")
                    if video.Parse(msg)
                        vidlist = CreateObject("roArray", 10, true)
                        vid_uri = ""
                        for each file in video.files.file
                            if(file@bitrate = "ipad")
                                vidlist.push(file.GetText())
                                vid_uri = file.GetText()
                            endif 
                        end for
                        return vid_uri
                    end if
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif
    return invalid
End Function

Function showSpringboardScreen(item as object) As Boolean
    port = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")

    screen.SetMessagePort(port)
    screen.AllowUpdates(false)
    if item <> invalid and type(item) = "roAssociativeArray"
        screen.SetContent(item)
    endif

    screen.SetDescriptionStyle("generic") 
    screen.ClearButtons()
    screen.AddButton(1,"Play")
    screen.AddButton(2,"Go Back")
    screen.SetStaticRatingEnabled(false)
    screen.AllowUpdates(true)
    screen.Show()

    downKey=3
    selectKey=6
    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roSpringboardScreenEvent"
            if msg.isScreenClosed()
                exit while
            else if msg.isButtonPressed()
                if msg.GetIndex() = 1
                    date = CreateObject("roDateTime")
                    DisplayVideo(fcstream)          
                else if msg.GetIndex() = 2
                     return true
                endif
            else
            endif
        else 
        endif
    end while
    return true
End Function

Sub sendOmniture(eventType as string,videoclip as object)
    m.omniture = NWM_Omniture("http://stats.adultswim.com/b/ss/adultswimdevelopment/")
    
    strStreamName = ""


    if(videoclip <> invalid)
        if(videoclip.title <> invalid)
         strStreamName = ":" + videoclip.title
        endif

    endif
    params = { ' a set of params unique to this event
        pageName: "roku:adultswimstreams:" + eventType + strStreamName
        ch: "roku:adultswimstreams"
        v2: "D=pageName"
        sv:       "roku"
        c6:       "roku:adultswimstreams"
        v6:       "D=c6"
        c7:       "roku:adultswimstreams:" + eventType
        v7:       "D=c7"
        c8:       "roku:adultswimstreams" + strStreamName
        v8:       "D=c8"
        c9:       "roku:adultswimstreams" + eventType + strStreamName
        v9:       "D=c9"
        v2:       "D=ass_landing"
        h1:       "D=ass_landing"
        h3:       "video:roku:adultswimstreams:" + eventType + strStreamName
        events:       "event9,event2,event12"
    }
    
    m.omniture.LogEvent(params)
end Sub

