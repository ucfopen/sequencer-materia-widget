Namespace('Sequencer').Engine = do ->
	_qset                   = null
	_$board                 = null
	_$tile 					= null
	_tiles            		= [] 		# Array of tile object information
	_numTiles        		= 0 		# Total number of tiles in the qset
	_ids 					= []		# Array which holds random numbers for the tile Id's
	_currentScore           = 0 		# 
	_finalScore             = 0 		# 
	_clueOpen				= false 	# Boolean to help determine if a clue is already open
	_positions 				= [] 		# Array to keep track of the div
	_tilesInSequence		= 0 		# Count for the number of tiles in the OrderArea div
	_sequence 				= [] 		# Order of the submitted tiles
	_tileAngles				= [] 		# Array of tile angles
	_currActiveTile			= null 		# Tile being dragged
	_attempts				= 0			# Number of tries the current user has made
	_dropOrder				= []		# Order to drop the tiles based on randomly calculated z-index
	_playDemo				= false 	# Boolean for demo on/off

	# zIndex of the terms, incremented so that the dragged term is always on top
	_zIndex					= 11000

	# the current dragging term
	_curterm				= null

	# Called by Materia.Engine when your widget Engine should start the user experience.
	start = (instance, qset, version = '1') ->
		_qset = qset
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
		_curterm.style.zIndex = ++_zIndex

		# disable easing while it drags
		#e.target.className = 'tile'
		
		# if its been placed, pull it out of the sequence array
		if i = _sequence.indexOf(~~_curterm.id) != -1
			_sequence.splice(i,1)
			_tilesInSequence--

		# don't scroll the page on an iPad
		e.preventDefault()
		e.stopPropagation() if e.stopPropagation?

	# when the widget area has a cursor or finger move
	_mouseMoveEvent = (e) ->
		# if no term is being dragged, we don't care
		return if not _curterm?

		e = window.event if not e?

		# if it's not a mouse move, it's probably touch
		if not e.clientX
			e.clientX = e.changedTouches[0].clientX
			e.clientY = e.changedTouches[0].clientY

		x = (e.clientX - 30)
		x = 40 if x < 40
		x = 670 if x > 670
		y = (e.clientY - 90)
		y = 0 if y < 0
		y = 500 if y > 500

		# move the current term
		_curterm.style.transform =
		_curterm.style.msTransform =
		_curterm.style.webkitTransform = 'translate(' + x + 'px,' + y + 'px)'

		if x > 360
			console.log 'yellow'
			console.log $('#orderArea').addClass 'hoverTile'
			#$('#'+_currActiveTile).css
			#	'transform': 'rotate(0deg)'

		if x < 360
			$('#orderArea').removeClass 'hoverTile'
			#$('#'+_currActiveTile).css
			#	'transform': 'rotate('+_tiles[_currActiveTile].angle+'deg)'

		# don't scroll on iPad
		e.preventDefault()
		e.stopPropagation() if e.stopPropagation?

	# when we let go of a term
	_mouseUpEvent = (e) ->
		# we don't care if nothing is selected
		return if not _curterm?

		if not e.clientX
			e.clientX = e.changedTouches[0].clientX
			e.clientY = e.changedTouches[0].clientY

		if e.clientX > 360
			# apply easing (for snap back animation)
			#_curterm.className = 'tile ease'
			if _numTiles is 0
				console.log "adding show"
				$('#orderInstructions').addClass 'show'

			_tilesInSequence++
			console.log "number in the dropTile section " + _tilesInSequence + " of " + _numTiles
			
			_curterm.style.transform =
			_curterm.style.msTransform =
			_curterm.style.webkitTransform = 'translate(590px,' + (80  * (_tilesInSequence - 1) - 20) + 'px)'

			newNumbers = _.template $('#numberBar-numbers').html()
			number = $(newNumbers number: _tilesInSequence)
			$('#numberBar').append number
			number.addClass 'show'

			if _tilesInSequence == _numTiles
				_tilesSequenced()

			if _numTiles > 0 
				console.log "adding hide"
				$('#orderInstructions').addClass 'hide'			

			_sequence.push ~~_curterm.id

		_curterm = null


		# prevent iPad/etc from scrolling
		e.preventDefault()
	
	_startDemo = ->
		console.log "starting demo"
		demoScreen = _.template $('#demo-window').html()
		_$demo = $ demoScreen 
			demoTitle: ''
			penalty: _qset.options.penalty
		$('body').append _$demo
		$('.demoButton').offset()
		$('.demoButton').addClass 'show'

		# Exit demo.
		$('.demoButton').on 'click', ->
			$('#demo').remove()
			_makeTilesFall 1

	_makeRandomIdForTiles = (needed) ->
		idArray = []
		i = 0
		while i <= needed
			console.log i+" needed"
			console.log idArray
			newNum = Math.floor (Math.random() * 200) + 1
			if idArray.indexOf(newNum) is -1 then idArray[i] = newNum else i--
			i++
		idArray

	_makeTiles = (items) ->
		console.log "number of items" + items.length
		_ids = _makeRandomIdForTiles items.length
		i = 0

		for tile in items

			_numTiles++
			console.log "ids is: " + _ids[i]
			_tiles[_ids[i]] =
		 		id : _ids[i]
		 		name : tile.questions[0].text
		 		clue : tile.options.description
		 		xpos : 200
		 		ypos : 200
		 		zInd : 0
		 		angle : 0
		 		dropOrder : 0
		 		order : i
		 	i++
		console.log "IDS is: " + _ids

		_tiles

	# Draw the main board.
	_drawBoard = (title) ->
		# Disables right click.
		#document.oncontextmenu = -> false    

		theTiles = _makeTiles _qset.items

		# console.log "all tiles are : " + _tiles[_ids[1]]
		tBoard = _.template $('#t-board').html()

		# color each word in the title individually
		colorTitle = _colorWordsInTitle title

		_$board = $ tBoard
			title: colorTitle
			tiles: theTiles
			score: 100
			penalty: _qset.options.penalty

		cWidth = 240
		cHeight = 300

		$('body').append _$board
		$('.tile').addClass 'noShow'

		# Resize the title if needed.
		_resizeTitle _qset.name.length

		# Set the positions for each tile.
		_positionTiles cWidth, cHeight

		# Set the order of the tiles to be dropped based on their zIndex
		dO = _generateDropOrder()

		# Drop the tiles on the board.
		_makeTilesFall 1, dO unless _playDemo
		###
		$('.tile').on 'mouseover', ->
			unless $(this).hasClass 'fall'
				$(this).addClass 'hover'

		$('.tile').on 'mouseout', ->
			unless $(this).hasClass 'fall'
				$(this).removeClass 'hover'
		###

		$('.tile').on 'touchstart', _mouseDownEvent
		$('.tile').on 'MSPointerDown', _mouseDownEvent
		$('.tile').on 'mousedown', _mouseDownEvent

		# Reveal the clue for clicked tile
		$('#dragContainer').on 'click', '.clue', ->
			_revealClue $(this).data('id')

		# Scroll the numberBar with the orderArea
		$('#orderArea').on 'scroll', ->
			$('#numberBar').scrollTop $('#orderArea').scrollTop()

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

	# Set random tile position, angle, and z-index
	_positionTiles = (maxWidth, maxHeight) ->
		console.log "got to position tiles"

		for tile in $('.tile')
			console.log "\n\nPositioning tile: " + tile.id + " " + _tiles[tile.id].name
			# console.log "got to after first line"
			textLength = _tiles[tile.id].name.length
			tries = 1
			
			_tiles[tile.id].xpos = Math.floor (Math.random() * maxWidth) + 20
			_tiles[tile.id].ypos =  Math.floor (Math.random() * maxHeight) + 70
			_tiles[tile.id].zInd = Math.floor (Math.random() * 4) + 8 
			_tiles[tile.id].dropOrder = _tiles[tile.id].zInd
			_tiles[tile.id].angle = Math.floor (Math.random() * 16) - 8 

			# Get new position if tile is too close to another tile unless too many tries
			# More than likey not worth the computation
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
				'transform': 'rotate('+_tiles[tile.id].angle+'deg)'
				'z-index': ++_zIndex

			# resize text to fit if needed
			if textLength >= 30 
				console.log "\tshrinking text on " + _tiles[tile.id].name
				$('#'+tile.id).css
					'font-size': 16+'px'
			if textLength >= 20 
				console.log "\tshrinking text on " + _tiles[tile.id].name
				$('#'+tile.id).css
					'font-size': 18+'px'

		# _showPositionsArray()

		# Remove the clue symbol if there is no hint available
		unless _tiles[tile.id].clue
			console.log "does not have clue"

	# _generateDropOrder2 = (tileID) ->
	# 	# If no tiles are in the list
	# 	if _dropOrder.length is 0
	# 		_dropOrder.push {
	# 			z: _tiles[tileID].zInd,
	# 			t: tileID
	# 		}

	# 	# There is at least one tile in the list
	# 	else
	# 		for j in [0.._dropOrder.length-1]
	# 			if _tiles[tileID].zInd < _dropOrder[j].z 
	# 				_dropOrder.splice j, 0, {
	# 					z: _tiles[tileID].zInd,
	# 					t: tileID
	# 				}
	# 				break
	# 			if j is _dropOrder.length-1
	# 				_dropOrder.push {
	# 					z: _tiles[tileID].zInd,
	# 					t: tileID
	# 				}

	# 	console.log _dropOrder

	_showPositionsArray = ->
		console.log "Current tile positions:"
		i = 1
		while i <= _numTiles*2
			console.log "\t[x:"+_positions[i-1]+", y:"+_positions[i]+"]"
			i+=2

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
		setTimeout -> 
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
			$('#'+nextTileID).addClass 'fall' + fallversion
			if _dropOrder.length > 0
				_makeTilesFall(fallversion%3+1, dropOrder)
			# Remove the fall classes after the animation
			else 
				$('.tile').removeClass 'fall1'
				$('.tile').removeClass 'fall2'
				$('.tile').removeClass 'fall3'
		, 80

	# Get the drop order for the tiles based on their zindex
	_generateDropOrder = () ->
		console.log "got to make tiles fall"
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
		console.log _dropOrder
		_dropOrder

	# Show the clue from the id of the tile clicked
	_revealClue = (id) -> 
		# Removes the old clue if it is hidden on the page
		if _clueOpen
			console.log "it exists."
			$('#clue-popup').remove()

		# Set up the tile template
		tileClue = _.template $('#tile-clue-window').html()
		$tileC = $ tileClue
			name: _tiles[id].name,
			clue: _tiles[id].clue

		# Add the clue to the page
		$('.board').append $tileC
		$tileC.addClass 'show'
		_clueOpen = true

		$('.close').on 'click', ->
			$('#clue-popup').remove()
			_clueOpen = false

	_dragTile = (event, ui) ->
		if $('#clue-popup').length
			$('#clue-popup').remove()
			_clueOpen = false
		_currActiveTile = this.id
		# console.log "Currently active tile is: " + _currActiveTile

	_dropTileInSequenceArea = (event, ui) ->
		console.log "dropping tile " + _currActiveTile + " to the orderbar"
		
		if _numTiles is 0 
			console.log "adding show"
			$('#orderInstructions').addClass 'show'

		_tilesInSequence++
		console.log "number in the dropTile section " + _tilesInSequence + " of " + _numTiles
		

		$('.tile[data-id='+_currActiveTile+']').css
			'position': 'relative'
			'transform': 'rotate(0deg)'
			'bottom': 'auto'
			'left': 50+'px'
			'margin': '-10px 10px 0px 10px'

		# Fix the font alignment when drop in the order area
		$('.tile[data-id='+_currActiveTile+']', 'tileText').css
			'display': 'table-cell'
			'vertical-align': 'middle'

		$('#orderArea').append $('.tile[data-id='+_currActiveTile+']')

		newNumbers = _.template $('#numberBar-numbers').html()
		number = $(newNumbers number: _tilesInSequence)
		$('#numberBar').append number
		number.addClass 'show'

		if _tilesInSequence == _numTiles
			_tilesSequenced()

		if _numTiles > 0 
			console.log "adding hide"
			$('#orderInstructions').addClass 'hide'			

	_dropTilesInTileSection = (event, ui) ->
		console.log 'dropping tile in tile seciton'
		$('#tileSection').append $('.tile[data-id='+_currActiveTile+']')
		$('#orderArea').removeChild $('.tile[data-id='+_currActiveTile+']')
		
		$('.tile[data-id='+_currActiveTile+']').css
			'position': 'relative'
			'transform': 'rotate('+_tiles[i].angle+'deg)'
			'bottom': 'auto'
			'left': _tiles[i].xpos +'px'
			'margin': '-10px 10px 0px 10px'

		_tilesInSequence--

	# All tiles have been moved to the orderArea. No tiles left on the board
	_tilesSequenced = ->
		console.log "all tiles added"

		newMessage = _.template $('#message-window').html()
		message = $(newMessage title: 'You\'re Done', messageText: 'Make sure you have the right sequence and press the \"Submit Sequence\" button.')
		$('#tileSection').append message
		message.addClass 'show'

		$('#submit').addClass 'enabled'
		$('#submit').on 'click', ->
			_submitSequence()

	# Answer submitted by user
	_submitSequence = ->
		$('.fade').addClass 'active'

		# Get order of the tiles for grading
		console.log _sequence
		# Grade the sequence based on order of tiles
		correct = _determineNumCorrect _sequence
		_showResults correct

	# Compare the order of the submitted sequence to the correct ordering
	_determineNumCorrect = (submitted) ->
		numCorrect = 0
		correctOrder = 0
		for i in submitted
			console.log "checking " + i
			if _tiles[i].order is correctOrder
				console.log "match for " + i
				numCorrect++
			else
				console.log "no good for " + i
			correctOrder++
		return numCorrect

	# Displays the results template after user has submitted a sequence
	_showResults = (results) ->
		_attempts++
		console.log "number of attempts " + _attempts

		# Results template window
		tResults = _.template $('#results-popup').html()
		$results = $ tResults 
			total: _numTiles
			penalty: _qset.options.penalty

		console.log "You got " + results + " of " + _numTiles
		$('body').append $results
		unless results == _numTiles
			# Update the score based on the new results
			scoreString =  "100 - " + _qset.options.penalty * _attempts + " = " + (100 - _qset.options.penalty * _attempts)

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
			if _attempts < 10
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
		# console.log "digits as string" + digits
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

	# # Extracts a number from a string 
	# filterInt = (stringValue) -> 
	# 	if /^(\-|\+)?([0-9]+|Infinity)$/.test(stringValue)
	# 		return Number(stringValue)

	_sendScores = () ->
		answer = 0
		# console.log "sent scores"
		for i in _sequence
			Materia.Score.submitQuestionForScoring _tiles[i].order, ++answer

	_end = () ->
		# console.log "ending..."
		Materia.Engine.end yes

	#public
	manualResize: true
	start: start
