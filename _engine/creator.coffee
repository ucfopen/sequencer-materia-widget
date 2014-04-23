Namespace('Sequencer').Creator = do ->
	_widget  = null # Holds widget data
	_qset    = null # Keep tack of the current qset
	_title   = null # Hold on to this instance's title
	_version = null # Holds the qset version, allows you to change your widget to support old versions of your own code
	
	# variables to contain templates for various page elements
	_qTemplate 			= null
	_qWindowTemplate 	= null
	_aTemplate 			= null
	_numTiles			= 0
	_maxTiles			= 20

	# strings containing tutorial texts, boolean for tutorial mode
	_tutorial_help 	= false
	_openQ 			= null
	_openQWindow	= null
	
	# creating the tutorial from HTML classes		
	tutorial1 = $('.tutorial.step1')
	tutorial2 = $('.tutorial.step2')
	tutorial3 = $('.tutorial.step3')

	_defaultTileString =  ''
	_defaultClickString = 'Click to add tile'
	_defaultClueString = 'Enter optional information here'

	initNewWidget = (widget, baseUrl) ->
		_buildDisplay 'My Sequencer Widget', widget

	initExistingWidget = (title, widget, qset, version, baseUrl) -> 
		_buildDisplay title, widget, qset, version

	onSaveClicked = (mode = 'save') ->
		if _buildSaveData()
			Materia.CreatorCore.save _title, _qset
		else
			Materia.CreatorCore.cancelSave 'Widget not ready to save.'

	onSaveComplete = (title, widget, qset, version) -> 
		true

	onQuestionImportComplete = (questions) -> 
		for question in questions
			_addQuestion question 

	# This basic widget does not support media
	onMediaImportComplete = (media) -> 
		null
	
	# Set up page and listen
	_buildDisplay = (title = 'Default test Title', widget, qset, version) ->
		_version = version
		_qset    = qset
		_widget  = widget
		_title   = title

		$('#title').val _title

		# Fill the template objects
		unless _qTemplate
			_qTemplate = $('.template.question')
			$('.template.question').remove()
			_qTemplate.removeClass('template')
		unless _qWindowTemplate
			_qWindowTemplate = $('.template.question_window')
			$('.template.question_window').remove()
			_qWindowTemplate.removeClass('template')
		unless _aTemplate
			_aTemplate = $('.template.answer')
			$('.template.answer').remove()
			_aTemplate.removeClass('template')

		# initial window
		$('#startPopup').addClass 'show'
		$('#fader').addClass 'dim'

		# Sortable TileInfoSliders
		$('#creatorArea').sortable
		 	helper: 'clone'
		 	cursor: 'move'
		 	containment: '#creatorArea' 
		 	cancel: '.nondraggable'
		 	axis: 'y'
		 	stop: _updateTileNums

		$('#addSliderButton').on 'click', -> 
			$('#columnSection').removeClass 'hidden'
			$('#arrow').removeClass 'show'
			_addNewTileSlider()

		# Add a slider between two tiles
		$('body').delegate '.addInbetween', 'click', ->
				_addNewTileSlider($(this).parent().parent())
				_updateTileNums()
				$(this).removeClass 'show'
				$(this).parent().parent().children('.peak').removeClass 'show'

		# Remove Slider
		$('body').delegate '.icon-close', 'click', -> 
			_numTiles--
			$(this).parent().removeClass 'appear'	
			Elem = this
			setTimeout -> 
				$(Elem).parent().remove()
				_updateTileNums()
			, 200
		
		$('body').delegate '.addInbetween', 'mouseover', ->
				$(this).addClass 'show'
				$(this).parent().parent().children('.peak').addClass 'show'

		$('body').delegate '.addInbetween', 'mouseout', ->
				$(this).removeClass 'show'
				$(this).parent().parent().children('.peak').removeClass 'show'

		$('#options').on 'click', ->
			$('#optionsPopup').addClass 'show'
			$('#fader').addClass 'dim'

		$('.closeWindow').on 'click', ->
			$(this).parent().removeClass 'show'
			$('#fader').removeClass 'dim'

			# Set the title
			if $(this).parent().attr('id') is 'startPopup'
				$('#title').val($('#inputTitle').val())
				$('#arrow').addClass 'show'
			# #Set the penalty amount
			else if $('#assessmentOptions').hasClass 'show'
				$('#numTries').html($('#numTriesInput').val() + ' Free Tries')
				$('#penalty').html($('#penaltyInput').val() + 'pt Penalty')

		$('#inputTitle').on 'keyup', (e) ->
		    if e.which == 13 
		    	$('.closeWindow').click()
	
		$('#modeContainer').on 'click', ->
			$('#modeSlider').toggleClass 'slide'
			$('#assessmentOptions').toggleClass 'active'
			$('#mode').html('Assessment Mode')
			$('#practiceMode').toggleClass 'active'
			$('#assessmentMode').toggleClass 'active'
			$('#assessmentOptions').toggleClass 'show'
			$('#practiceDetails').toggleClass 'show'
			$('#assessmentDetails').toggleClass 'show'

		# Some set of questions already exists
		if _qset?
			questions = _qset.items
			_addQuestion question for question in questions
	
	_addQuestion = (question) ->
		$('#arrow').removeClass 'show'
		$('#startPopup').removeClass 'show'
		$('#fader').removeClass 'dim'

		_addNewTileSlider(null, question.questions[0].text, question.options.description)

	# Change radio game modes
	_updateGameMode = ->
		if $('#assessmentRadio').is ':checked'
			$('#penaltyBox').addClass 'show'
			$('#freeBox').addClass 'show'
		else
			$('#penaltyBox').removeClass 'show'
			$('#freeBox').removeClass 'show'

	# Add new slider
	_addNewTileSlider = (position, tileString = '', clueString = '') ->
		if _numTiles is _maxTiles 
			Materia.CreatorCore.alert 'Maximum Tiles', 'You may only have up to '+ _maxTiles + ' tiles in this widget.'
			return
		_numTiles++

		$('#addSliderButton').addClass 'slide'
		
		# Add a new Slider
		newTileSlot = _.template $('#t-slide-info').html()
		tileSlot = $(newTileSlot tileNum: _numTiles, tileText: tileString, clueText: clueString)
		
		if position?
			$(tileSlot).insertBefore (position)
		else
			$(tileSlot).insertBefore ($('#addSliderButton'))
		$(tileSlot).offset()
		$(tileSlot).addClass 'appear'

	# Change the number on the sliders 
	_updateTileNums = () ->
		i = 1
		for slider in $('.tileInfoSlider')
			$(slider).children('.block').children('.number').html(i)
			i++ 

	# On preview/publish/save click
	_buildSaveData = ->
		okToSave = false

		# Create new qset object if we don't already have one, set default values regardless.
		unless _qset?
			_qset = {}
		_qset.options = {}
		_qset.assets = []
		_qset.rand = false
		console.log $('#penaltyAttempts').val()

		_qset.options.penalty = $('#penaltyInput').val() 
		_qset.options.freeAttempts = $('#numTriesInput').val() 
		_qset.name = 'test'

		# update our values
		_title = $('#title').val()
		okToSave = true if _title? && _title != ''

		tList = _loadingItemsForSave()
		if tList is -1
			okToSave = false
		tList.assets = []
		tList.options = {cid: 0}

		_qset.items = tList.items
		console.log _qset
		okToSave

	# Get each Tile's data from the appropriate info
	_loadingItemsForSave = -> 
		tileList = {items: []}
		
		i = 0

		# Organize all tile names and tile clues
		for t in $('.tileInfoSlider')
			tileName = _validateTileString 'tile-text', $(t).find('.title').val() #.$('.tile-text').val()
			tileClue = _validateTileString 'clue-text', $(t).find('.cluetext').val()

			item = {
				id: ''
				type: 'QA'
				materiaType: 'question'
				questions: [{
					id: ''
					text: tileName
				}]
				answers: [{
					id: ''
					value: 100
					text: i++
				}]
				options:
					description: tileClue
			}
			tileList.items.push item

		tileList

	# Returns the tile if valid or null if not changed
	_validateTileString = (type, text) ->
		# Tile text
		if type is 'tile-text'
			if text is _defaultTileString
				Materia.CreatorCore.alert 'Unnamed Tile', 'You must enter a name for all tiles.'
				text = null
		
		# Clue text
		else 
			if text is _defaultClueString
				text = null
		text

	#public
	initNewWidget: initNewWidget
	initExistingWidget: initExistingWidget
	onSaveClicked:onSaveClicked
	onMediaImportComplete:onMediaImportComplete
	onQuestionImportComplete:onQuestionImportComplete
	onSaveComplete:onSaveComplete
