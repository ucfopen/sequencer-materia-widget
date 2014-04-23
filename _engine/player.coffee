Namespace('Sequencer').Engine = do ->
	_qset                   = null
	_$board                 = null
	_$tile 					= null
	_tiles            		= [] 		# Array of tile object information
	_numTiles        		= 0 		# Total number of tiles in the qset
	_ids 					= []		# Array which holds random numbers for the tile Id's
	_positions 				= [] 		# Array to keep track of the div
	_tilesInSequence		= 0 		# Count for the number of tiles in the OrderArea div
	_sequence 				= [-1] 		# Order of the submitted tiles
	_tileAngles				= [] 		# Array of tile angles
	_currActiveTile			= null 		# Tile being dragged
	_attempts				= 0			# Number of tries the current user has made
	_dropOrder				= []		# Order to drop the tiles based on randomly calculated z-index
	_playDemo				= true 		# Boolean for demo on/off
	_insertAfter			= 0 		# Number to where to drop tile inbetween other tiles
	_ORDERHEIGHT			= 70
	_addTempNum 			= true
	_tempNumber				= null
	_freeAttemptsLeft 		= 0

	# zIndex of the terms, incremented so that the dragged term is always on top
	_zIndex					= 11000

	# the current dragging term and its position info
	_curterm				= null
	_relativeX				= 0
	_relativeY				= 0
	_deltaX 				= 0
	_deltaY 				= 0
	_curXstart				= 0
	_curYstart				= 0
	
	# Called by Materia.Engine when your widget Engine should start the user experience.
	start = (instance, qset, version = '1') ->
		_qset = qset
		_freeAttemptsLeft = _qset.options.freeAttempts
	
		if _playDemo 
			_startDemo()

		# attach document listeners
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
	
	# when a term is mouse downed
	_mouseDownEvent = (e) ->
		e = window.event if not e?
		
		# set current dragging term
		_curterm = e.target

		if _curterm.className == "clue"
			_curterm = _curterm.parentNode
		_curterm.style.zIndex = ++_zIndex
		_curterm.style.position = 'fixed'

		# disable easing while it drags
		# e.target.className = 'tile'

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

			# move the current term
			_curterm.style.transform = 
			_curterm.style.msTransform =
			_curterm.style.webkitTransform = 'translate(' + moveX + 'px,' + moveY + 'px)'

		# if its been placed, pull it out of the sequence array
		if (i = _sequence.indexOf(~~_curterm.id)) != -1
			_sequence.splice(i,1)
			_tilesInSequence--
		
		_insertAfter = -1

	#	don't scroll the page on an iPad
	# 	e.preventDefault()
	# 	e.stopPropagation() if e.stopPropagation?
		
		_addTempNum = true
		_updateTileNums()

		_mouseMoveEvent(e)

	# when the widget area has a cursor or finger move
	_mouseMoveEvent = (e) ->
		# if no term is being dragged, we don't care
		return if not _curterm?

		e = window.event if not e?
		
		# if it's not a mouse move, it's probably touch
		if not e.clientX
			e.clientX = e.changedTouches[0].clientX
			e.clientY = e.changedTouches[0].clientY
		
		_deltaX = (e.clientX - _curXstart)
		moveX = (_curXstart + _deltaX - _relativeX) 
		# x boundaries
		moveX = 20 if moveX < 20
		moveX = 565 if moveX > 565
		
		_deltaY = (e.clientY - _curYstart - 10)
		moveY = (_curYstart + _deltaY - _relativeY)
		# y boundaries
		moveY = 5 if moveY < 5
		moveY = 420 if moveY > 420

		for i in [0..._sequence.length]
			if _sequence[i] is -1
				_sequence.splice(i, 1)
				i--

		# move the current term
		_curterm.style.transform = 
		_curterm.style.msTransform =
		_curterm.style.webkitTransform = 'translate(' + moveX + 'px,' + moveY + 'px)'

		# Drag tile into the order area
		if moveX > 420
			_insertAfter = 0

			# Add an extra temporary number when you drag the tile into the tile area
			if _addTempNum is true
				newNumbers = _.template $('#numberBar-numbers').html()
				_tempNumber = $(newNumbers number: 1 + $('#numberBar').children().length)
				$('#numberBar').append _tempNumber
				_tempNumber.addClass 'show'
				_addTempNum = false
			
			_curterm.style.webkitTransform += ' rotate(' + 0 + 'deg)'
			
			for i in [0..._sequence.length]
				if moveY > ((_ORDERHEIGHT * i) + 50) - $('#dragContainer').scrollTop()
					_insertAfter = _sequence[i]
			if _insertAfter is -1
				# dont do it
			else if _insertAfter == 0
				_sequence.splice(0, -1, -1)
			# else if _insertAfter is _sequence[_sequence.length-1]
				# also don't do it
			else if _insertAfter
				_sequence.splice(_sequence.indexOf(_insertAfter) + 1, 0, -1)

			# Code for highlighting the numbers when hover in order spot
			numSpot = $('#numberBar').children()[_sequence.indexOf(-1)]
			unless numSpot?
				numSpot = _tempNumber
			$('.highlight').removeClass 'highlight'
			$(numSpot).addClass 'highlight'
		
		else
			if _addTempNum is false
				$('#numberBar').children()[$('#numberBar').children().length-1].remove()
				_addTempNum = true 

		_repositionOrderedTiles() 
		console.log _sequence

		if moveX <= 420
			for i in [0..._sequence.length]
				if _sequence[i] is -1
					_sequence.splice(i, 1)
			# Rotate the tile back to the current tile object's stored angle
			_curterm.style.webkitTransform += ' rotate(' + _tiles[_curterm.id].angle + 'deg)'

		# don't scroll on iPad
		# e.preventDefault()
		# e.stopPropagation() if e.stopPropagation?

	# when we let go of a term
	_mouseUpEvent = (e, moveY, moveX) ->
		# we don't care if nothing is selected
		return if not _curterm?
		_addTempNum = true
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
			# apply easing (for snap back animation)
			#_curterm.className = 'tile ease'
			if _numTiles is 0
				$('#orderInstructions').addClass 'show'

			_tilesInSequence++

			$('#message').remove()
			if _tilesInSequence == _numTiles
				_tilesSequenced()
			if _numTiles > 0 
				$('#orderInstructions').addClass 'hide'
			if _insertAfter == 0
				# insert at beginning
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
			if moveY > 400
				moveY = 400 
				changed = true
			
			if changed
				_curterm.style.transform = 
				_curterm.style.msTransform =
				_curterm.style.webkitTransform = 'translate(' + moveX + 'px,' + moveY + 'px) rotate(' + _tiles[_curterm.id].angle + 'deg)'
				
			$('#message').remove()
			$('#tileSection').removeClass 'fade'
			$('#submit').removeClass 'enabled'

		if _numTiles is 0
			$('#numberBar').empty()
			$('#orderInstructions').addClass 'show'

		_repositionOrderedTiles()
		_updateTileNums()

		_curterm = null

		# Prevent iPad/etc from scrolling
		e.preventDefault()
	
	_startDemo = ->
		demoScreen = _.template $('#demo-window').html()
		_$demo = $ demoScreen 
			demoTitle: ''
			penalty: _qset.options.penalty
			freeAttempts : _qset.options.freeAttempts
		$('body').append _$demo
		$('.demoButton').offset()
		$('.demoButton').addClass 'show'

		# Exit demo.
		$('.demoButton').on 'click', ->
			$('#demo').remove()

			_makeTilesFall 1, _generateDropOrder()

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

	# Draw the main board.
	_drawBoard = (title) ->
		# Disables right click.
		#document.oncontextmenu = -> false

		theTiles = _makeTiles _qset.items

		tBoard = _.template $('#t-board').html()

		# color each word in the title individually
		colorTitle = _colorWordsInTitle title
		
		_$board = $ tBoard
			title: colorTitle
			tiles: theTiles
			score: 100
			penalty: _qset.options.penalty
			freeAttempts: _qset.options.freeAttempts

		cWidth = 250
		cHeight = 280

		$('body').append _$board
		$('.tile').addClass 'noShow'

		# Resize the title if needed.
		_resizeTitle _qset.name.length

		# Set the positions for each tile.
		_setInitialTilePosition cWidth, cHeight

		# Set the order of the tiles to be dropped based on their zIndex
		dO = _generateDropOrder()

		# Drop the tiles on the board.
		_makeTilesFall 1, dO unless _playDemo

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
		if length > 50 
			$('.words').css
				'font-size': 15+'px'
		if length > 40
			$('.words').css
				'font-size': 17+'px'
		if length > 32 
			$('.words').css
				'font-size': 19+'px'
		if length > 25 
			$('.words').css
				'font-size': 21+'px'

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

			# Get new position if tile is too close to another tile unless too many tries
			while ! _checkTilePosition _tiles[tile.id].xpos , _tiles[tile.id].ypos 
				if tries > 10
					_positions.push _tiles[tile.id].xpos 
					_positions.push _tiles[tile.id].ypos 
					break

				# Generates random placement for this tile
				x = Math.floor (Math.random() * maxWidth) + 20
				y = Math.floor (Math.random() * maxHeight) + 70
				
				tries++
			
			_tiles[tile.id].xpos = _positions[_positions.length-2]
			_tiles[tile.id].ypos = _positions[_positions.length-1]

			$('#'+tile.id).css
				'transform': 'rotate('+_tiles[tile.id].angle+'deg) translate(' + _tiles[tile.id].xpos + 'px,' + _tiles[tile.id].ypos+ 'px)'
				'z-index': ++_zIndex
				'position': 'fixed'

			# resize text to fit if needed
			if textLength >= 30 
				$('#'+tile.id).css
					'font-size': 16+'px'
			if textLength >= 20 
				$('#'+tile.id).css
					'font-size': 18+'px'

		# Remove the clue symbol if there is no hint available
		#unless _tiles[tile.id].clue
			# TODO

	# Check potential position to see if there is already a tile in the area
	_checkTilePosition = (w, h) ->
		# If found Ok spot
		if ((_getClosestTileSpot w, 1) >= 80 or (_getClosestTileSpot h, 2) >= 50)
			_positions.push w
			_positions.push h
			return true
		# Bad spot try again
		else 
			return false

	# Get the tile spot nearest to the potential spot. Start denotes the x or y component
	_getClosestTileSpot = (target, start) ->
		smallest = 1000

		# Very first tile
		if _positions.length == 0
			return smallest
		
		for index in [start-1.._positions.length-1] by 2
			if smallest > Math.abs(target - _positions[index])
				smallest = Math.abs(target - _positions[index])
				direct = if start is 2 then "y" else "x"
		return smallest

	# Runs after the demo is over. Drops all tiles with 3 slightly different drop animations
	_makeTilesFall = (fallversion, dropOrder) ->

		# Uncomment for the drop animation
		# setTimeout -> 
		nextTileID = dropOrder.shift()
		# foundFlag = false
		# for tile in $('.tile')
		# 	if _tiles[tile.id].zInd == minZ
		# 		nextTileID = tile.id
		# 		foundFlag = true
		# 		console.log "tiles: " + nextTileID + " " + _tiles[tile.id].name + "'s Z is: "+ _tiles[tile.id].zInd
		# 		console.log "minZ is: " + minZ + " foundFlag is " + foundFlag
		# 		# Udpdate for new drop order.
		# 		_tiles[tile.id].zInd = 0
		# 	if tile.id is 9 and foundflag is false and minZ >= 12
		# 		console.log "foundflag is false incrememting minZ to " + minZ
		# 		minZ++

		$('#'+nextTileID).removeClass 'noShow'
		# $('#'+nextTileID).addClass 'fall' + fallversion
		if _dropOrder.length > 0
			_makeTilesFall(fallversion%3+1, dropOrder)
		# Remove the fall classes after the animation
		# else 
		# 	$('.tile').removeClass 'fall1'
		# 	$('.tile').removeClass 'fall2'
		# 	$('.tile').removeClass 'fall3'
		# , 100

	# Get the drop order for the tiles based on their zindex
	_generateDropOrder = () ->
		minZ = 99
		maxZ = 0
		for tile in $('.tile')
			if _tiles[tile.id].zInd < minZ 
				minZ = _tiles[tile.id].zInd
			if _tiles[tile.id].zInd > maxZ 
				maxZ = _tiles[tile.id].zInd

		while minZ <= maxZ
			for tile in $('.tile')
				tileFound = false
				if _tiles[tile.id].zInd is minZ
					tileFound = true
					_dropOrder.push tile.id
					_tiles[tile.id].zInd = 0
					
			minZ++ 
		_dropOrder

	# Show the clue from the id of the tile clicked
	_revealClue = (id) -> 
		# Get data for new clue
		tileClue = _.template $('#tile-clue-window').html()
		$tileC = $ tileClue
			name: _tiles[id].name,
			clue: _tiles[id].clue

		# Remove old clue
		clueBox = $('#clueHeader')
		clueBox.animate({height: 0}, 200);

		# Add the clue to the page
		# $('.board').append $tileC

		# setTimeout ->
		# 	$('#clueHeader').remove()
		# 	$('.board').append $tileC
		# 	$('#clueHeader').addClass 'slideDown'
		# ,500

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
			for i in [1.._tilesInSequence]
				newNumbers = _.template $('#numberBar-numbers').html()
				number = $(newNumbers number: i)
				$('#numberBar').append number
				number.addClass 'show'

	# All tiles have been moved to the orderArea. No tiles left on the board
	_tilesSequenced = ->
		newMessage = _.template $('#message-window').html()
		message = $(newMessage title: 'You\'re Done', messageText: 'Make sure you have the right sequence and press the \"Submit Sequence\" button.')
		$('#tileSection').append message
		message.addClass 'show'
		$('#tileSection').addClass 'fade'
		$('#submit').addClass 'enabled'

	# Answer submitted by user
	_submitSequence = () ->
		$('.fade').addClass 'active'

		# Get order of the tiles for grading
		# Grade the sequence based on order of tiles
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
			penalty: _qset.options.penalty 
			freeAttemptsLeft: --_freeAttemptsLeft

		$('body').append $results
		# Only if not 100%
		unless results == _numTiles

			if _freeAttemptsLeft >= 0
				$('#attemptsLeft').html _freeAttemptsLeft
				if _freeAttemptsLeft is 0
					$('#attempts-info').addClass 'hidden'
					$('#score-info').removeClass 'hidden'

			else
				_attempts++
				# Update the score based on the new results
				scoreString =  "100 - " + _qset.options.penalty * _attempts + " = " + (100 - _qset.options.penalty * _attempts)
				$('#score').html scoreString
		
		# Restore Free Attempts counter
		else 
			_freeAttemptsLeft++

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
			# Still have more attempts
			if _freeAttemptsLeft >= 0
				# Change button function for retry
				$('#resultsButton').html "Try Again!"
				$('#resultsButton').addClass 'show'
				$('#freeAttemptsLeftMessage').addClass 'show'
				$('#resultsButton').on 'click', ->
					$('#resultsOuter').remove()
					$('.board').removeClass 'dim'
					$('.fade').removeClass 'active'

			# Still have more attempts
			else if _attempts < 10
				# Change button function for retry
				$('#resultsButton').html "Try Again!"
				$('#resultsButton').addClass 'show'
				$('#lostPointsMessage').addClass 'show'
				$('#resultsButton').on 'click', ->
					$('#resultsOuter').remove()
					$('.board').removeClass 'dim'
					$('.fade').removeClass 'active'

			# Used last attempt
			else
				_sendScores()
				# Change button function for end
				$('#resultsButton').html "Visit Score Screen"
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
		for i in _sequence
			Materia.Score.submitQuestionForScoring _tiles[i].qid, _tiles[i].order, 100

	_end = () ->
		Materia.Engine.end yes
		# Go to Materia score page

	#public
	manualResize: true
	start: start
