class KDInputViewWithPreview extends KDInputView

  constructor:(options,data)->

    options.preview               or= {}
    options.preview.autoUpdate    ?= yes
    options.preview.language      or= "markdown"
    options.preview.showInitially ?= yes
    options.preview.mirrorScroll  ?= yes
    options.allowMaximized        ?= yes
    options.showHelperModal       ?= yes

    options.keyup ?= (event)=>
      if @options.preview.autoUpdate
        @generatePreview()
      yes

    options.focus ?= (event)=>
      if @options.preview.autoUpdate
        @generatePreview()
      yes

    super options,data

    @setClass "kdinputwithpreview"

    @showPreview = options.preview.showInitially or no

    @previewOnOffLabel = new KDLabelView
      cssClass      : "preview_switch_label"
      title         : "Preview"
      tooltip       :
        title       : "Show/hide the Text Preview Box"
    @previewOnOffSwitch = new KDOnOffSwitch
      label         : @previewOnOffLabel
      size          : "tiny"
      defaultValue  : if @showPreview then on else off
      callback      : (state)=>
        if state
          @showPreview = yes
          @generatePreview()
          @$("div.preview_content").removeClass "hidden"
          @$("div.preview_switch").removeClass "content-hidden"
          @$().removeClass "content-hidden"
          @emit "PreviewShown"
        else
          @$("div.preview_content").addClass "hidden"
          @$("div.preview_switch").addClass "content-hidden"
          @$().addClass "content-hidden"
          @emit "PreviewHidden"

    @previewOnOffContainer = new KDView
      cssClass : "preview_switch"

    if @options.showHelperModal

      @markdownLink = new KDCustomHTMLView
        tagName     : 'a'
        name        : "markdownLink"
        value       : "markdown is enabled"
        attributes  :
          href      : '#'
          value     : "markdown syntax is enabled"
        cssClass    : 'markdown-link'
        partial     : "What is Markdown?<span></span>"
        tooltip     :
          title     : "Show available Markdown formatting syntax"
        click       : (event)=>
          if $(event.target).is 'span'
            link.hide()
          else
            markdownText = new KDMarkdownModalText
            modal = new KDModalView
              title       : "How to use the <em>Markdown</em> syntax."
              cssClass    : "what-you-should-know-modal markdown-cheatsheet"
              height      : "auto"
              width       : 500
              content     : markdownText.markdownText()
              buttons     :
                Close     :
                  title   : 'Close'
                  style   : 'modal-clean-gray'
                  callback: -> modal.destroy()

      @previewOnOffContainer.addSubView @markdownLink

    if @options.allowMaximized
      @fullScreenBtn = new KDButtonView
        style           : "clean-gray small"
        cssClass        : "fullscreen-button"
        title           : "Fullscreen Edit"
        icon            : no
        tooltip         :
          title         : "Open a Fullscreen Editor"
        callback: =>
          @textContainer = new KDView
            cssClass:"modal-fullscreen-text"

          @text = new KDInputViewWithPreview
            type : "textarea"
            cssClass : "fullscreen-data kdinput text"
            allowMaximized : no
            defaultValue : @getValue()

          @textContainer.addSubView @text

          modal = new KDModalView
            title       : "Please enter your content here."
            cssClass    : "modal-fullscreen"
            width       : $(window).width()-110
            height      : $(window).height()-120
            view        : @textContainer
            position:
              top       : 55
              left      : 55
            overlay     : yes
            buttons     :
              Cancel    :
                title   : "Discard changes"
                style   : "modal-clean-gray"
                callback:=>
                  modal.destroy()
              Apply     :
                title   : "Apply changes"
                style   : "modal-clean-gray"
                callback:=>
                  @setValue @text.getValue()
                  @generatePreview()
                  modal.destroy()

          modal.$(".kdmodal-content").height modal.$(".kdmodal-inner").height()-modal.$(".kdmodal-buttons").height()-modal.$(".kdmodal-title").height() # minus the margin, border pixels too..
          modal.$(".fullscreen-data").height modal.$(".kdmodal-content").height()-30-23+10
          modal.$(".input_preview").height   modal.$(".kdmodal-content").height()-0-21+10
          modal.$(".input_preview").css maxHeight:  modal.$(".kdmodal-content").height()-0-21+10
          modal.$(".input_preview div.preview_content").css maxHeight:  modal.$(".kdmodal-content").height()-0-21
          contentWidth = modal.$(".kdmodal-content").width()-40
          halfWidth  = contentWidth / 2

          @text.on "PreviewHidden", =>
            modal.$(".fullscreen-data").width contentWidth #-(modal.$("div.preview_switch").width()+20)-10
            # modal.$(".input_preview").width (modal.$("div.preview_switch").width()+20)

          @text.on "PreviewShown", =>
            modal.$(".fullscreen-data").width contentWidth-halfWidth-5
            # modal.$(".input_preview").width halfWidth-5

          modal.$(".fullscreen-data").width contentWidth-halfWidth-5
          modal.$(".input_preview").width halfWidth-5

      @previewOnOffContainer.addSubView @fullScreenBtn

    @previewOnOffContainer.addSubView @previewOnOffLabel
    @previewOnOffContainer.addSubView @previewOnOffSwitch

    @addSubView @previewOnOffContainer

  getEditScrollPercentage:->
      scrollPosition = @$().scrollTop()
      scrollHeight = @$().height()
      scrollMaxheight = @getDomElement()[0].scrollHeight

      scrollPosition / (scrollMaxheight - scrollHeight) * 100

  setPreviewScrollPercentage:(percentage)->
    s = @$("div.preview_content")
    s.animate
     scrollTop : ((s[0].scrollHeight - s.height())*percentage/100)
    , 50, "linear"

  setDomElement:(CssClass="")->
    super CssClass

    # basically, here we can add aynthing like modals, overlays and the liek

    @$().after """
      <div class='input_preview preview-#{@options.preview.language}'>
        <div class="preview_content"></div>
      </div>"""

  viewAppended:->
    super

    unless @showPreview
      @$("div.preview_content").addClass "hidden"
      @$("div.preview_switch").addClass "content-hidden"
      @$().addClass "content-hidden"
      @previewOnOffSwitch.setValue off
    else
      @generatePreview()
      @previewOnOffSwitch.setValue on

    @$("label").on "click",=>
      @$("input.checkbox").get(0).click()

    @$("div.preview_content").addClass("has-"+@options.preview.language)

    if @options.preview.mirrorScroll then @$().scroll (event)=>
      @setPreviewScrollPercentage @getEditScrollPercentage()

  setValue:(value)->
    super value
    @generatePreview()

  generatePreview:=>
    if @showPreview
      if @options.preview.language is "markdown"
        @$("div.preview_content").html @utils.applyMarkdown @getValue()
        @$("div.preview_content pre").addClass("prettyprint").each (i,element)=>
          hljs.highlightBlock element