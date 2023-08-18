Namespace('Sequencer').Engine = do ->
	_qset             = null
	_$board           = null
	_$tile            = null
	_tiles            = []    # Array of tile object information
	_tilesInVertOrder = []    # Array of tiles in top to bottom visual order
	_numTiles         = 0     # Total number of tiles in the qset
	_ids              = []    # Array which holds random numbers for the tile Id's
	_tilesInSequence  = 0     # Count for the number of tiles in the OrderArea div
	_sequence         = [-1]  # Order of the submitted tiles
	_attempts         = 0     # Number of tries the current user has made
	_playDemo         = true  # Boolean for demo on/off
	_insertAfter      = 0     # Number to where to drop tile inbetween other tiles
	_ORDERHEIGHT      = 70    # Specifies the height for translation offset
	_freeAttempts	  = 0     # Number of attempts before the penalty kicks in
	_practiceMode     = false # true = practice mode, false = assessment mode
	currentPenalty    = 0

	_keyboardInstructions = 'Use the Tab key to navigate through the terms from top to bottom, left to right. ' +
		'Hold the Shift key when pressing the Tab key to navigate in reverse. ' +
		'You will reach the sequenced terms after navigating through all of the unsorted terms. ' +
		'Press the Right Arrow key when an unsorted term is selected to move it to the end of the sequence. ' +
		'Press the Left Arrow key when a sequenced term is selected to remove it from the sequence. ' +
		'Press the Up Arrow or Down Arrow keys when a sequenced term is selected to move it up or down in the sequence.'

	# The current dragging term and its position info
	_curterm      = null
	_relativeX    = 0
	_relativeY    = 0
	_deltaX       = 0
	_deltaY       = 0
	_curXstart    = 0
	_curYstart    = 0
	_addedTempNum = false  # Boolean for determining whether or not to add a number to the numberBar
	_zIndex       = 11000

	highestScore = 0
	_highestSequence = []

	# Called by Materia.Engine when your widget Engine should start the user experience.
	start = (instance, qset, version = '1') ->
		if qset.items[0].items
			qset.items = qset.items[0].items
		_qset = qset

		_freeAttempts = _qset.options.freeAttempts or 10

		# Determine the play modes
		_practiceMode = _qset.options.practiceMode if _qset.options.practiceMode?

		if _playDemo
			_startDemo()
		else
			$('.fade').removeClass 'active'

		# Attach document listeners
		document.addEventListener('touchend', _mouseUpEvent, false)
		document.addEventListener('mouseup', _mouseUpEvent, false)
		document.addEventListener('MSPointerUp', _mouseUpEvent, false)
		document.addEventListener('mouseup', _mouseUpEvent, false)
		document.addEventListener('touchmove', _mouseMoveEvent, false)
		document.addEventListener('MSPointerMove', _mouseMoveEvent, false)
		document.addEventListener('mousemove', _mouseMoveEvent, false)

		_drawBoard(instance.name)

		# Set player height.
		Materia.Engine.setHeight()

	# When a term is mouse downed
	_mouseDownEvent = (e) ->
		e = window.event if not e?

		# If it's not a mouse move, it's probably touch
		if not e.clientX
			if not e.changedTouches
				e.clientX = e.originalEvent.changedTouches[0].clientX
				e.clientY = e.originalEvent.changedTouches[0].clientY
			else
				e.clientX = e.changedTouches[0].clientX
				e.clientY = e.changedTouches[0].clientY

		# Set current dragging term
		_curterm = e.target

		if _curterm.className == "clue"
			_curterm = _curterm.parentNode
		_curterm.style.zIndex = ++_zIndex
		_curterm.style.position = 'fixed'
		_curterm.style.transition = 'none'

		_relativeX = (e.clientX - $('#'+_curterm.id).offset().left)
		_relativeY = (e.clientY - $('#'+_curterm.id).offset().top + 15)

		_curXstart = (e.clientX)
		_curYstart = (e.clientY-10)

		moveX = (_curXstart + _deltaX - _relativeX)
		moveY = (_curYstart + _deltaY - _relativeY)

		# Adjust for scrolling
		if (_curXstart - _relativeX) > 420
			_relativeY += $('#dragContainer').scrollTop()
			_curYstart += $('#dragContainer').scrollTop()
			_addedTempNum = true
		else
			# Move the current term
			_curterm.style.transform =
			_curterm.style.msTransform =
			_curterm.style.webkitTransform = 'translate(' + moveX + 'px,' + moveY + 'px)'

		# If its been placed, pull it out of the sequence array
		if (i = _sequence.indexOf(~~_curterm.id)) != -1
			_sequence.splice(i,1)
			_tilesInSequence--

		_insertAfter = -1
		_mouseMoveEvent(e)

	# When the widget area has a cursor or finger move
	_mouseMoveEvent = (e) ->
		# If no term is being dragged, we don't care
		return if not _curterm?

		e = window.event if not e?

		# If it's not a mouse move, it's probably touch
		if not e.clientX
			if not e.changedTouches
				e.clientX = e.originalEvent.changedTouches[0].clientX
				e.clientY = e.originalEvent.changedTouches[0].clientY
			else
				e.clientX = e.changedTouches[0].clientX
				e.clientY = e.changedTouches[0].clientY

		_deltaX = (e.clientX - _curXstart)
		moveX = (_curXstart + _deltaX - _relativeX)

		# X boundaries
		moveX = 20 if moveX < 20
		moveX = 565 if moveX > 565

		_deltaY = (e.clientY - _curYstart - 10)
		moveY = (_curYstart + _deltaY - _relativeY)

		# Y boundaries
		if moveY > 400
			document.getElementById('dragContainer').scrollTop += 10
		if moveY < 5
			document.getElementById('dragContainer').scrollTop -= 10
		moveY = 5 if moveY < 5
		moveY = 480 if moveY > 480

		for i in [0..._sequence.length]
			if _sequence[i] is -1
				_sequence.splice(i, 1)
				i--

		# Move the current term
		_curterm.style.transform =
		_curterm.style.msTransform =
		_curterm.style.webkitTransform = 'translate(' + moveX + 'px,' + moveY + 'px)'

		# Drag tile into the order area
		if moveX > 420
			_insertAfter = 0

			# Add an extra number unless already added
			unless _addedTempNum
				$('#numberBar :last-child').addClass 'highlight'
				$('#numberBar :last-child').addClass 'show'
				newNumbers = _.template $('#numberBar-numbers').html()
				number = $(newNumbers number: $('#numberBar').children().size()+1)
				$('#numberBar').append number
				_addedTempNum = true

			_curterm.style.webkitTransform += ' rotate(' + 0 + 'deg)'

			for i in [0..._sequence.length]
				if moveY > ((_ORDERHEIGHT * i) + 50) - $('#dragContainer').scrollTop()
					_insertAfter = _sequence[i]
			if _insertAfter is -1
			else if _insertAfter == 0
				_sequence.splice(0, -1, -1)
			else if _insertAfter
				_sequence.splice(_sequence.indexOf(_insertAfter) + 1, 0, -1)

			# Highlight the numbers when hover in order spot
			numSpot = $('#numberBar').children()[_sequence.indexOf(-1)]
			$('.highlight').removeClass 'highlight'
			$(numSpot).addClass 'highlight'
			$(numSpot).addClass 'show'

		else
			if _addedTempNum
				if $('#numberBar').children().length > _tilesInSequence+1
					$('#numberBar :last-child').remove()
				$('.highlight').removeClass 'highlight'
				$('#numberBar :last-child').removeClass 'show'
				_addedTempNum = false

			for i in [0..._sequence.length]
				if _sequence[i] is -1
					_sequence.splice(i, 1)
			# Rotate the tile back to the current tile object's stored angle
			_curterm.style.webkitTransform += ' rotate(' + _tiles[_curterm.id].angle + 'deg)'

		_repositionOrderedTiles()

	# When we let go of a term
	_mouseUpEvent = (e, moveY, moveX) ->
		# We don't care if nothing is selected
		return if not _curterm?
		# _addTempNum = true
		moveX = (_curXstart + _deltaX - _relativeX)
		moveY = (_curYstart + _deltaY - _relativeY)

		# Remove the empty slots
		for i in [0..._sequence.length]
			if _sequence[i] is -1
				_sequence.splice(i, 1)

		if not e.clientX
			e.clientX = e.changedTouches[0].clientX
			e.clientY = e.changedTouches[0].clientY

		if moveX > 420
			_curterm.style.position = 'absolute'

			if _numTiles is 0
				$('#orderInstructions').addClass 'show'

			_tilesInSequence++

			$('#message').remove()
			if _tilesInSequence == _numTiles
				_tilesSequenced()
			if _numTiles > 0
				$('#orderInstructions').addClass 'hide'
			if _insertAfter == 0
				# Insert at beginning
				_sequence.splice(0, 0, ~~_curterm.id)
			else if _insertAfter and _insertAfter != -1 and _insertAfter != _sequence[_sequence.length-1]
				_sequence.splice(_sequence.indexOf(_insertAfter)+1, 0, ~~_curterm.id)
			else
				for i in [0..._sequence.length]
					if _sequence[i] is ~~_curterm.id
						_sequence.splice(i, 1)
				_sequence.push ~~_curterm.id

		# Drop in tile section
		else
			# Prevent unwanted tile drops...and out of board movements
			if moveX < 20
				moveX = 20
			if moveX < 420 and moveY < 90
				moveY = 95
				changed = true
			if moveY > 420
				moveY = 420
				changed = true

			if changed
				_curterm.style.transform =
				_curterm.style.msTransform =
				_curterm.style.webkitTransform = "translate(#{moveX}px,#{moveY}px) rotate(#{_tiles[_curterm.id].angle}deg)"

			$('#message').remove()
			$('#tileSection').removeClass 'fade'
			$('#submit').removeClass 'enabled'

		if _numTiles is 0
			$('#numberBar').empty()
			$('#orderInstructions').addClass 'show'

		_repositionOrderedTiles()
		_updateTileNums()

		_curterm.style.transition = '0ms'
		_clearStyle = _curterm
		_curterm = null
		_addedTempNum = false

		setTimeout ->
			_clearStyle.style.transition = '120ms'
		, 0

	_locateNextTile = (currentTile, backwards = false) ->
		currentId = ~~currentTile.id
		targetTile = null

		# keep track of which tiles are still unordered to traverse them more easily
		unorderedTiles = _tilesInVertOrder.filter (t) ->
			return false unless t
			_sequence.indexOf(t.id) < 0

		# figure out if the current tile is ordered or not
		indexInOrder = _sequence.indexOf(currentId)

		# current tile is ordered
		if indexInOrder > -1
			if backwards
				# current tile is not the first ordered tile
				if indexInOrder > 0
					# move to the previous ordered tile
					targetTile = _tiles[_sequence[indexInOrder-1]]
				else
					# if there are remaining unordered tiles
					if unorderedTiles.length
						# move to the lowest unordered tile
						targetTile = unorderedTiles[unorderedTiles.length-1]
			else
				# current tile is not the last ordered tile
				if indexInOrder + 1 < _sequence.length
					# move to the next ordered tile
					targetTile = _tiles[_sequence[indexInOrder+1]]

		else
			# check all of the unordered tiles until we find the current one
			for tile, index in unorderedTiles
				# now get the next one based on the direction we're looking in
				if tile.id == currentId
					if backwards
						# current tile is not the highest unordered tile
						if index > 0
							targetTile = unorderedTiles[index-1]
					else
						# current tile is the highest unordered tile
						if index + 1 == unorderedTiles.length
							# select the first organized tile instead, if there are any
							if _sequence.length
								targetTile = _tiles[_sequence[0]]
						else
							# select the next lowest unordered tile
							targetTile = unorderedTiles[index+1]
					break

		unless targetTile
			return false
		return document.getElementById(targetTile.id)

	_keyDownEvent = (e) ->
		_curterm = e.target

		switch e.key

			when 'Tab' # select the next tile depending on position and sort status
				e.stopPropagation()
				e.preventDefault()

				nextTile = _locateNextTile(_curterm, e.shiftKey)
				if nextTile
					nextTile.focus()
					# also bring it up to the top of the pile so we can actually see it
					nextTile.style.zIndex = ++_zIndex
				else
					# we're on the highest tile and have pressed shift+tab
					if e.shiftKey
						document.getElementById('keyboard-instructions').focus()
					# we're on the lowest tile and have pressed tab
					else
						# if all tiles have been ordered, select the submit button
						if _tilesInSequence == _numTiles
							document.getElementById('submit').focus()
						# otherwise select the wraparound button
						else
							document.getElementById('wraparound').focus()

			when 'Enter' # reveal clue if the tile has one
				if _tiles[_curterm.id].clue.length > 0
					$('header').addClass 'slideUp'
					_revealClue _curterm.id

			when 'ArrowLeft' # put it back in the tile pile
				if (i = _sequence.indexOf(~~_curterm.id)) != -1
					_sequence.splice(i,1)
					_tilesInSequence--

					_curterm.style.transform =
					_curterm.style.msTransform =
					_curterm.style.webkitTransform = "translate(#{_tiles[_curterm.id].xpos}px,#{_tiles[_curterm.id].ypos}px) rotate(#{_tiles[_curterm.id].angle}deg)"

					_curterm.style.position = 'fixed'

					$('#message').remove()
					$('#tileSection').removeClass 'fade'
					$('#submit').prop('disabled', true)
					$('#submit').removeClass 'enabled'

					_setAriaLabelForTile(_curterm.id)

					_assistiveStatusUpdate(_tiles[_curterm.id].name + ' unsorted. ' + _tilesInSequence + ' of ' + _numTiles + ' tiles sorted.')

			when 'ArrowRight' # put it in the ordered list (at the bottom)
				if _sequence.indexOf(~~_curterm.id) is -1
					_sequence.push ~~_curterm.id
					_tilesInSequence++

					_curterm.style.position = 'absolute'

					if _numTiles is 0 then $('#orderInstructions').addClass 'show'
					else $('#orderInstructions').addClass 'hide'

					$('#message').remove()
					if _tilesInSequence == _numTiles
						_tilesSequenced()

					_setAriaLabelForTile(_curterm.id)

					_assistiveStatusUpdate(_tiles[_curterm.id].name + ' sorted. '  + _tilesInSequence + ' of ' + _numTiles + ' tiles sorted.')
					# approximate the y position of this tile within the drag area then scroll to that so it remains visible
					# math: position in sequence * tile height + padding between tiles
					sequencedYPos = _sequence.indexOf(~~_curterm.id) * 61 + 10
					document.getElementById('dragContainer').scrollTop = sequencedYPos

			when 'ArrowUp' # sort upwards
				if (i = _sequence.indexOf(~~_curterm.id)) != -1 and i != 0
					[_sequence[i - 1], _sequence[i]] = [_sequence[i], _sequence[i - 1]]

					_setAriaLabelForTile(_curterm.id)

					_assistiveStatusUpdate(_tiles[_curterm.id].name + ' moved to position   ' + i + ' of ' + _tilesInSequence)

			when 'ArrowDown' # sort downwards
				if (i = _sequence.indexOf(~~_curterm.id)) != -1 and i != _sequence.length - 1
					[_sequence[i + 1], _sequence[i]] = [_sequence[i], _sequence[i + 1]]

					_setAriaLabelForTile(_curterm.id)

					_assistiveStatusUpdate(_tiles[_curterm.id].name + ' moved to position   ' + (i + 2) + ' of ' + _tilesInSequence)


		# Remove the empty slots
		for i in [0..._sequence.length]
			if _sequence[i] is -1
				_sequence.splice(i, 1)

		_curterm = null
		_repositionOrderedTiles()
		_updateTileNums()

	_startDemo = ->
		demoScreen = _.template $('#demo-window').html()

		if _practiceMode == true
			_freeAttempts = 'unlimited'
			_qset.options.penalty = 0

		_introInstructions = 'Welcome to the ' + _qset.name + ' Sequencer widget. ' +
			'You will be presented with a number of terms. ' +
			'Your objective is to order all of the terms correctly in the sequence list. ' +
			'You have ' + _freeAttempts + ' attempts to find the correct order. ' +
			'Your highest score will be saved. ' +
			_keyboardInstructions + ' ' +
			'Press the Space or Enter key to begin.'

		_$demo = $ demoScreen
			demoTitle: ''
			freeAttempts: _freeAttempts or "unlimited"
			introInstructions: _introInstructions
		$('body').append _$demo
		$('.demoButton').offset()
		$('.demoButton').addClass('show').focus()

		# Exit demo
		# two listeners so we can handle mouse activation and keyboard activation separately
		$('.demoButton').on 'mousedown', _closeDemo
		# in the case of the keyboard, we want to auto-focus the highest tile after closing the demo
		$('.demoButton').on 'keydown', (e) ->
			if e.key == ' ' or e.key == 'Enter'
				_closeDemo()
				document.getElementById(_tilesInVertOrder[0].id).focus()

	_closeDemo = () ->
		$('#demo').remove()
		$('.fade').removeClass 'active'
		$('.board').removeAttr 'inert'

	_makeRandomIdForTiles = (needed) ->
		idArray = []
		i = 0
		while i <= needed
			newNum = Math.floor (Math.random() * 200) + 1
			if idArray.indexOf(newNum) is -1 then idArray[i] = newNum else i--
			i++
		idArray

	_makeTiles = (items) ->
		_ids = _makeRandomIdForTiles items.length
		i = 0

		for tile in items

			_numTiles++
			_tiles[_ids[i]] =
				id: _ids[i]
				qid: tile.id
				name: tile.questions[0].text
				clue: tile.options.description
				xpos: 200
				ypos: 200
				zInd: 0
				angle: 0
				dropOrder: 0
				order: i
			i++

		_tiles

	# Draw the main board
	_drawBoard = (title) ->
		theTiles = _makeTiles _qset.items
		tBoard = _.template $('#t-board').html()

		# Color each word in the title individually
		colorTitle = _colorWordsInTitle title

		_$board = $ tBoard
			title: colorTitle
			tiles: theTiles
			score: "0%"
			penalty: ~~_qset.options.penalty
			freeAttempts: _freeAttempts
			keyboardInstructions: 'Keyboard instructions: ' + _keyboardInstructions + ' Press the Tab key to return to the nearest tile.'

		cWidth = 250
		cHeight = 280

		$('body').append _$board

		if _practiceMode
			$('#attempts-info').addClass 'hidden'

		else if _freeAttempts?
			$('#practiceMode-info').addClass 'hidden'
		else
			$('#attempts-info').addClass 'hidden'
			$('#practiceMode-info').addClass 'hidden'

		# Resize the title if needed.
		_resizeTitle _qset.name.length

		# Set the positions for each tile.
		_setInitialTilePosition cWidth, cHeight

		$('.tile').on 'touchstart', _mouseDownEvent
		$('.tile').on 'MSPointerDown', _mouseDownEvent
		$('.tile').on 'mousedown', _mouseDownEvent
		$('.tile').on 'keydown', _keyDownEvent

		# Reveal the clue for clicked tile
		$('#dragContainer').on 'mousedown', '.clue', ->
			$('header').addClass 'slideUp'
			_revealClue $(this).data('id')

		# Scroll the numberBar with the orderArea
		$('#dragContainer').on 'scroll', ->
			$('#numberBar').scrollTop $('#dragContainer').scrollTop()

		# On submit sequence clicked
		$('#submit').on 'click', ->
			_submitSequence()

		$('.board').on 'click', '#clueHeader', ->
			$('header').removeClass 'slideUp'
			$('#clueHeader').transition({height: 0}, 500);

		$('#keyboard-instructions').on 'click', _openKeyboardInstructions

		$('#keyboard-close').on 'mousedown', _closeKeyboardInstructions
		$('#keyboard-close').on 'keypress', (e) ->
			if e.key == ' ' or e.key == 'Enter'
				_closeKeyboardInstructions()
				document.getElementById('keyboard-instructions').focus()

		$('#keyboard-instructions').on 'keydown', (e) ->
			if e.key == 'Tab' and not e.shiftKey
				e.preventDefault()
				e.stopPropagation()
				unorderedTiles = _tilesInVertOrder.filter (t) ->
					return false unless t
					_sequence.indexOf(t.id) < 0
				if unorderedTiles.length
					document.getElementById(unorderedTiles[0].id).focus()
				else
					document.getElementById(_sequence[0]).focus()

		$('#wraparound').on 'click', ->
			unorderedTiles = _tilesInVertOrder.filter (t) ->
				return false unless t
				_sequence.indexOf(t.id) < 0
			document.getElementById(unorderedTiles[0].id).focus()
		$('#wraparound').on 'keydown', (e) ->
			if e.key == 'Tab' and e.shiftKey
				e.preventDefault()
				e.stopPropagation()
				if _sequence.length
					document.getElementById(_sequence[_sequence.length-1]).focus()
				else
					# this array has a lot of empty space in it, the last element isn't necessarily the last tile
					# we have to traverse it backwards to find the last tile
					highestTile = null
					for i in [_tilesInVertOrder.length..0]
						if _tilesInVertOrder[i] and not _sequence.includes[_tilesInVertOrder[i].id]
							highestTile = _tilesInVertOrder[i]
							break
					if highestTile
						document.getElementById(highestTile.id).focus()

	_openKeyboardInstructions = () ->
		$('#keyboard-instructions-window').show()
		$('.fade').addClass 'active'
		$('.board').attr 'inert', 'true'
		document.getElementById('keyboard-close').focus()
	_closeKeyboardInstructions = () ->
		$('#keyboard-instructions-window').hide()
		$('.fade').removeClass 'active'
		$('.board').removeAttr 'inert'

	_resizeTitle = (length) ->
		if length < 20
			$('.words').css
				'font-size': 30+'px'
		else if length < 25
			$('.words').css
				'font-size': 23+'px'
		else if length < 32
			$('.words').css
				'font-size': 21+'px'
		else if length < 40
			$('.words').css
				'font-size': 19+'px'
		else if length < 45
			$('.words').css
				'font-size': 17+'px'
		else
			$('.words').css
				'font-size': 14+'px'

	# Sets each word in the title to a different color
	_colorWordsInTitle = (title) ->
		if title is undefined or null
			title = 'Widget Title Goes Here'
		titleWords = title.split ' '
		colorTitle = []
		index = 0;
		for i in titleWords
			rem = index % 3
			unless index is 0
				colorTitle += " "
			if rem is 0
				colorTitle += '<span h1 class="words color0">'+i+'</h1>'
			else if rem is 1
				colorTitle += '<span h1 class="words color1">'+i+'</h1>'
			else if rem is 2
				colorTitle += '<span h1 class="words color2">'+i+'</h1>'
			index++
		return colorTitle

	# Reposition the tiles in the order area
	_repositionOrderedTiles = () ->
		i = 0
		for id in _sequence
			if id is -1
				i++
				continue
			curterm = document.getElementById id
			curterm.style.transform =
			curterm.style.msTransform =
			curterm.style.webkitTransform = 'translate(555px,' + (_ORDERHEIGHT * i + 10) + 'px)'
			i++

		transform = 'translate(0px,' + (_ORDERHEIGHT * i + 10) + 'px)'
		s = document.getElementById('tileFiller').style
		s.webkitTransform = transform
		s.mozTransform = transform
		s.transform = transform

	_setAriaLabelForTile = (tileId) ->
		tileLabel = _tiles[tileId].name + '.'
		if _tiles[tileId].clue is ''
			$('#'+tileId).children('.clue').remove()
		else
			tileLabel = tileLabel + ' This tile has a clue, press enter to review it.'
		if _sequence.indexOf(~~tileId) >= 0
			tileLabel = tileLabel + ' This tile has been added to the sequence.'
		else
			tileLabel = tileLabel + ' This tile has not been added to the sequence.'
		$('#'+tileId).attr('aria-label', tileLabel)

	# Set random tile position, angle, and z-index
	_setInitialTilePosition = (maxWidth, maxHeight) ->

		for tile in $('.tile')
			textLength = _tiles[tile.id].name.length
			tries = 1

			_tiles[tile.id].xpos = Math.floor (Math.random() * maxWidth) + 30
			_tiles[tile.id].ypos =  Math.floor (Math.random() * maxHeight) + 120
			_tiles[tile.id].zInd = Math.floor (Math.random() * 4) + 8
			_tiles[tile.id].dropOrder = _tiles[tile.id].zInd
			_tiles[tile.id].angle = Math.floor (Math.random() * 14) - 7

			$('#'+tile.id).css
				'transform': 'rotate('+_tiles[tile.id].angle+'deg) translate(' + _tiles[tile.id].xpos + 'px,' + _tiles[tile.id].ypos+ 'px)'
				'z-index': ++_zIndex
				'position': 'fixed'

			# Resize text to fit if needed
			if textLength >= 20
				$('#'+tile.id).css
					'font-size': 18+'px'
			if textLength >= 30
				$('#'+tile.id).css
					'font-size': 16+'px'
			if textLength >= 40
				$('#'+tile.id).css
					'font-size': 13+'px'
			# Remove the clue symbol if there is no hint available
			_setAriaLabelForTile tile.id

		_tilesInVertOrder = _tiles.toSorted (a,b) ->
			if a.ypos < b.ypos
				return -1
			if a.ypos == b.ypos
				if a.xpos < b.xpos
					return -1
				return 0
			return 1

	# Show the clue from the id of the tile clicked
	_revealClue = (id) ->

		# Get data for new clue
		tileClue = _.template $('#tile-clue-window').html()
		$tileC = $ tileClue
			name: _tiles[id].name,
			clue: _tiles[id].clue

		# Remove old clue
		clueBox = $('#clueHeader')
		clueBox.animate({height: 0}, 200)

		$('#clueHeader').remove()
		$('.board').append $tileC

		# Animate auto height
		clueBox = $('#clueHeader')
		autoHeight = clueBox.css('height', 'auto').height();
		clueBox.height('0px').transition({height: autoHeight}, 300);

	# Updates the numbers in the number bar when a tile is dropped or dragged in/out
	_updateTileNums = () ->
		$('#numberBar').empty()
		if _tilesInSequence > 0
			for i in [1.._tilesInSequence+1]
				newNumbers = _.template $('#numberBar-numbers').html()
				number = $(newNumbers number: i)
				$('#numberBar').append number
				number.addClass 'show'

			$('#numberBar :last-child').addClass 'numberFiller'
			$('#numberBar :last-child').removeClass 'show'

	# All tiles have been moved to the orderArea. No tiles left on the board
	_tilesSequenced = ->
		newMessage = _.template $('#message-window').html()
		message = $(newMessage title: 'Submit Your Sequence', messageText: 'Make sure you have the right sequence and press the \"Submit Sequence\" button.')
		$('#tileSection').append message
		message.addClass 'show'
		$('#tileSection').addClass 'fade'
		$('#submit').prop('disabled', false)
		$('#submit').addClass 'enabled'

	# Answer submitted by user
	_submitSequence = () ->
		$('.fade').addClass 'active'
		# Get order of the tiles for grading and grade the sequence based on order of tiles
		correct = _determineNumCorrect _sequence
		_showResults correct

	# Compare the order of the submitted sequence to the correct ordering
	_determineNumCorrect = (submitted) ->
		numCorrect = 0
		correctOrder = 0
		for i in submitted
			if _tiles[i].order is correctOrder
				numCorrect++
			correctOrder++
		return numCorrect

	# Displays the results template after user has submitted a sequence
	_showResults = (results) ->
		# Results template window
		tResults = _.template $('#results-popup').html()
		$results = $ tResults
			total: _numTiles
			penalty: ~~_qset.options.penalty
			freeAttempts: --_freeAttempts

		$('body').append $results
		# Only if score is not 100%
		unless results == _numTiles

			if _freeAttempts > 0 or _practiceMode
				$('#attemptsLeft').html _freeAttempts
				if _freeAttempts is 0
					$('#attempts-info').addClass 'hidden'
			_attempts++

		# Restore Free Attempts counter
		else
			_freeAttempts++

		# Update the score based on the new results
		score = Math.round((results / _numTiles) * 100)

		# Tell Materia they had it wrong and their score should be docked
		#Materia.Score.submitInteractionForScoring(null, "score", score)

		if score > highestScore
			highestScore = score
			_saveHighestScores()
		scoreString = highestScore + "%"
		$('#score').html scoreString


		# If 10 or more tiles in qset use the double-digit flipper
		if _numTiles >= 10
			_doubleDigitFlipCorrect 1, results

		# If less than 10 tiles in qset use the single-digit flipper
		else
			_singleDigitFlipCorrect 1, results

		$('#resultsButton').focus()
		$('.board').attr 'inert', 'true'
		$('#submit').prop('disabled', true)

	_showScoreMessage = (results) ->
		# Correct sequence submitted
		if results is _numTiles
			# Change button function for end
			_sendScores()
			_end(no)
			$('#resultsButton').html "Visit Score Screen"
			$('#resultsButton').addClass 'show'
			$('#correctMessage').addClass 'show'
			$('#resultsButton').on 'click', ->
				$('.fade').removeClass 'active'
				$('#resultsOuter').remove()
				$('.board').removeClass 'dim'
				$('.board').removeAttr 'inert'
				_end()

		# Incorrect sequence
		else
			$("#bestcircle").html highestScore + "%"
			$("#circle").html Math.round((results / _numTiles) * 100) + "%"

			$('#submitScoreButton').html "Or finish with your best score of " + highestScore + "%"
			$('#submitScoreButton').addClass "show"
			$('#submitScoreButton').on 'click', ->
				$('#resultsOuter').remove()
				$('.bestscore').html highestScore + "%"
				$('.confirmDialog').addClass 'show'
				$('.confirmDialog').removeAttr 'inert'
				$('.confirmDialog').children('button').attr('tabindex', 0)
				$('#confirmBestScoreButton').on 'click', ->
					_sendScores()
					_end(yes)
				$('#cancelBestScoreButton').on 'click', ->
					$('#resultsOuter').remove()
					$('.board').removeClass 'dim'
					$('.fade').removeClass 'active'
					$('.confirmDialog').removeClass 'show'
					$('.confirmDialog').attr 'inert', 'true'
					$('.board').removeAttr 'inert'
					$('#submit').prop('disabled', false)
					$('.confirmDialog').children('button').attr('tabindex', -1)

			# Still have more attempts
			if _freeAttempts > 0 or _practiceMode
				# Change button function for retry
				if _practiceMode
					$('#resultsButton').html "Try Again!"
				else
					$('#resultsButton').html "Try Again!<div>(" + (_freeAttempts) + " more guesses)</div>"

				$('#resultsButton').addClass 'show'
				$('#lostPointsMessage').addClass 'show'
				$('#bestScoreMessage').addClass 'show'
				$('#resultsButton').on 'click', ->
					$('#resultsOuter').remove()
					$('.board').removeClass 'dim'
					$('.fade').removeClass 'active'
					$('#submit').prop('disabled', false)
					$('.confirmDialog').children('button').attr('tabindex', -1)

			# Used last attempt
			else
				_sendScores()
				_end(no)
				# Change button function for end
				$('#resultsButton').html "Visit Score Screen"
				$('#submitScoreButton').hide()
				$('#attempts-info').hide()
				$('#resultsButton').addClass 'show'
				$('#allAttemptsMessage').addClass 'show'
				$('#resultsButton').on 'click', ->
					$('#resultsOuter').remove()
					$('.board').removeClass 'dim'
					$('.fade').removeClass 'active'
					_end()

	# Flip the numbers until flip to number correct
	_singleDigitFlipCorrect = (ctr, results) ->
		if ctr is 1
			$('#leftDigit').remove()

			# Shift the numbers over since using 2 digits
			$('#rightDigit').css
				'margin-left': 0+'px'

		setTimeout ->
			if ctr is results+1 or results is 0
				_showScoreMessage results
				return
			else
				# Check if number has already been flipped
				if $('.flipResultNumberBottom').hasClass 'flip'
					$('.flipResultNumberTop').removeClass 'flip'
					$('.flipResultNumberBottom').removeClass 'flip'

					# Magic to make the animation repeat
					$('.flipResultNumberTop').outerWidth $('.flipResultNumberTop').outerWidth
					$('.flipResultNumberBottom').outerWidth $('.flipResultNumberBottom').outerWidth

				# Put correct numbers into the flip pages
				$('#numberTop').html ctr - 1
				$('#numberTopUnder').html ctr
				$('#numberBottom').html ctr
				$('#numberBottomUnder').html ctr - 1

				$('.flipResultNumberTop').addClass 'flip'
				$('.flipResultNumberBottom').addClass 'flip'

				_singleDigitFlipCorrect ++ctr, results
		, 200

	# Flip the numbers until flip to number correct
	_doubleDigitFlipCorrect = (ctr, results) ->
		if ctr is 1
			# Shift the numbers over since using 2 digits
			$('#flipNumberContainer').css
				'margin-left': 10+'px'

		digits = ctr.toString().split ''
		if digits.length is 1
			digits = 0 + digits
		leftDigit = digits[0]
		rightDigit = digits[1]

		setTimeout ->
			if ctr is results+1 or results is 0
				_showScoreMessage results
				return
			else
				# Check if number has already been flipped
				if $('.flipResultNumberBottom').hasClass 'flip'
					$('.flipResultNumberTop').removeClass 'flip'
					$('.flipResultNumberBottom').removeClass 'flip'

					# Magic to make the animation repeat
					$('.flipResultNumberTop').outerWidth $('.flipResultNumberTop').outerWidth
					$('.flipResultNumberBottom').outerWidth $('.flipResultNumberBottom').outerWidth

				# Put correct numbers into the flip pages
				$('#numberTop').html if rightDigit is 0 then 0 else rightDigit-1
				$('#numberTopUnder').html rightDigit
				$('#numberBottom').html rightDigit
				$('#numberBottomUnder').html if rightDigit is 0 then 0 else rightDigit-1

				$('.flipResultNumberTop').addClass 'flip'
				$('.flipResultNumberBottom').addClass 'flip'

				# Flip the left digit only on multiples of 10
				if ctr % 10 is 0 and ctr isnt 0
					if $('.flipResultNumberBottomDouble').hasClass 'flip'
						$('.flipResultNumberTopDouble').removeClass 'flip'
						$('.flipResultNumberBottomDouble').removeClass 'flip'

						# Magic to make the animation repeat
						$('.flipResultNumberTopDouble').outerWidth $('.flipResultNumberTopDouble').outerWidth
						$('.flipResultNumberBottomDouble').outerWidth $('.flipResultNumberBottomDouble').outerWidth

					$('#numberTopDouble').html leftDigit - 1
					$('#numberTopUnderDouble').html leftDigit
					$('#numberBottomDouble').html leftDigit
					$('#numberBottomUnderDouble').html leftDigit - 1

					$('.flipResultNumberTopDouble').addClass 'flip'
					$('.flipResultNumberBottomDouble').addClass 'flip'

				_doubleDigitFlipCorrect ++ctr, results
		, 120

	_assistiveStatusUpdate = (status) ->
		$('.ariaLiveStatus').html status

	_sendScores = () ->
		answer = 0
		j = 1
		for i in _highestSequence
			Materia.Score.submitQuestionForScoring _tiles[i].qid, j, 100
			j++

	_saveHighestScores = ->
		_highestSequence = []
		for i in _sequence
			_highestSequence.push i

	_end = (gotoScoreScreen = yes) ->
		Materia.Engine.end gotoScoreScreen
		# Go to Materia score page

	#public
	manualResize: true
	start: start
