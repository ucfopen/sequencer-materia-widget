Namespace('Sequencer').Engine = do ->
	_qset             = null
	_$board           = null
	_$tile            = null
	_tiles            = []    # Array of tile object information
	_numTiles         = 0     # Total number of tiles in the qset
	_ids              = []    # Array which holds random numbers for the tile Id's
	_tilesInSequence  = 0     # Count for the number of tiles in the OrderArea div
	_sequence         = [-1]  # Order of the submitted tiles
	_attempts         = 0     # Number of tries the current user has made
	_playDemo         = true  # Boolean for demo on/off
	_insertAfter      = 0     # Number to where to drop tile inbetween other tiles
	_ORDERHEIGHT      = 70    # Specifies the height for translation offset
	_freeAttemptsLeft = 0     # Number of attempts before the penalty kicks in
	_practiceMode     = false # true = practice mode, false = assessment mode
	currentPenalty    = 0

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

		_freeAttemptsLeft = _qset.options.freeAttempts or 10

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
		_relativeY = (e.clientY - $('#'+_curterm.id).offset().top)

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
			# Prevent unwanted tile drops
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

	_startDemo = ->
		demoScreen = _.template $('#demo-window').html()

		if _practiceMode == true
			_freeAttemptsLeft = 'unlimited'
			_qset.options.penalty = 0

		_$demo = $ demoScreen
			demoTitle: ''
			freeAttempts : _freeAttemptsLeft or "unlimited"
		$('body').append _$demo
		$('.demoButton').offset()
		$('.demoButton').addClass 'show'

		# Exit demo
		$('.demoButton').on 'click', ->
			$('#demo').remove()
			$('.fade').removeClass 'active'

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
			freeAttempts: _qset.options.freeAttempts

		cWidth = 250
		cHeight = 280

		$('body').append _$board

		if _practiceMode
			$('#attempts-info').addClass 'hidden'

		else if _qset.options.freeAttempts?
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
			if _tiles[tile.id].clue is ''
				$('#'+tile.id).children('.clue').remove()

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
			freeAttemptsLeft: --_freeAttemptsLeft

		$('body').append $results
		# Only if score is not 100%
		unless results == _numTiles

			if _freeAttemptsLeft > 0 or _practiceMode
				$('#attemptsLeft').html _freeAttemptsLeft
				if _freeAttemptsLeft is 0
					$('#attempts-info').addClass 'hidden'
			_attempts++

		# Restore Free Attempts counter
		else
			_freeAttemptsLeft++

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
				_end()

		# Incorrect sequence
		else
			$("#bestcircle").html highestScore + "%"
			$("#circle").html Math.round((results / _numTiles) * 100) + "%"

			$('#submitScoreButton').html "Or finish with your best score of " + highestScore + "%"
			$('#submitScoreButton').addClass "show"
			$('#submitScoreButton').on 'click', ->
				_sendScores()
				_end(yes)

			# Still have more attempts
			if _freeAttemptsLeft > 0 or _practiceMode
				# Change button function for retry
				if _practiceMode
					$('#resultsButton').html "Try Again!"
				else
					$('#resultsButton').html "Try Again!<div>(" + (_freeAttemptsLeft) + " more tries)</div>"

				$('#resultsButton').addClass 'show'
				$('#lostPointsMessage').addClass 'show'
				$('#bestScoreMessage').addClass 'show'
				$('#resultsButton').on 'click', ->
					$('#resultsOuter').remove()
					$('.board').removeClass 'dim'
					$('.fade').removeClass 'active'

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
