#####################################################################
##           SPACE JET by Andrew D'Amario © April 2021             ##
#####################################################################
#
# CSCB58 Winter 2021 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Andrew D'Amario
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1 - done
# - Milestone 2 - done
# - Milestone 3 - done
# - Milestone 4 - done
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. Smooth graphics: 
# 	- minimized redrawing and clearing to only specific places where needed
# 	- efficiently used and reused registers, and minimized use of memory for optimal speed 
# 2. Scoring system:
# 	- shows score throughout the game and on the final "game over" screen
# 3. Increase the difficulty as the game progresses:
# 	- speed of jet increases every 200 points as caps off at 7ms wait time
# My features: 
# 1. added Stars in the background
# 2. parallax with the shift of stars and rocks so that it gives the feel that you are flying (rocks move faster)
# 3. added splash screen before start of game
# 4. cool darkened neon background for "game over" screen with enjoyable final message
# 5. more detailed graphics of objects, explosions, numbers, and letters
# 6. original game music (played in the background in demo video)
#
# Link to video demonstration for final submission:
# - https://youtu.be/b8rDmOi4d7Q
#
# Are you OK with us sharing the video with people outside course staff?
# - yes :)
# - https://github.com/andrewaclear/SpaceJet-AssemblyGame
#
# Any additional information that the TA needs to know:
# - Have fun! I like to be kind to my TA's and let them enjoy their marking once in a while!
#   (P.S. Tell me your high score.)
#
# Credits: 
# - Thomas - creator of name and cocreator of final message
#
#####################################################################

# defined CONSTANTS
.eqv	DISPLAY_FIRST_ADDRESS	0x10008000
# width = 64, height = 32
.eqv	DISPLAY_LAST_ADDRESS	0x10009FFC					# update this given the values below shift +(64*32-1)*4
.eqv	DISPLAY_MIDLFT_ADDRESS	0x10008C10					# mid left spot for ship (but jump 2 aligned) +(64*12+4)*4
.eqv	DISPLAY_SCORE		0x10009AF0					# bottom right corner +(64*27-4)*4
.eqv	DISPLAY_LIVES		0x100081E8					# top right corner +(64*2-6)*4
.eqv	DISPLAY_DEAD		0x10008C58					# top right corner +(64*13-42)*4
.eqv	DISPLAY_SPLASH		0x10008C14					# top right corner +(64*13-59)*4
# last address shifts
.eqv	SHIFT_NEXT_ROW		256						# next row shift = width*4 = 64*4
.eqv	SHIFT_SHIP_LAST		1324						# from top left of ship to bottom right = (64*5+11)*4
.eqv	SHIFT_ROCK_LAST		1564						# from top left of rock to bottom right = (64*6+7)*4
# number of pixels
.eqv	SIZE			2047						# number of pixels - 1 so can use index
.eqv	ROCK_WIDTH		32						# width of rock (8*4)
# random value ranges
.eqv	HEIGHT			31						# height of pixels - 1 so can use index
.eqv	ROCK_HEIGHT		7						# height of rock - 1

.eqv	COLOUR_NIGHT		0x00112135
.eqv	COLOUR_STAR		0x0019324f
# .eqv	COLOUR_NIGHT		0x00c8ddfd
.eqv	COLOUR_RED		0x00551c3a
.eqv	COLOUR_ROCK_DARK	0x00424242
.eqv	COLOUR_ROCK_LIGHT	0x006c6c6c
# .eqv	COLOUR_SHIP		0x00304698
.eqv	COLOUR_SHIP		0x002764d6
# .eqv	COLOUR_YELLOW		0x00dcff30
# .eqv	COLOUR_YELLOW		0x005c7173
.eqv	COLOUR_YELLOW		0x007b979a
# .eqv	COLOUR_EXPLOSION	0x00e7721f
.eqv	COLOUR_EXPLOSION	0x00ffa006
.eqv	COLOUR_HEART		0x00fb91b3
.eqv	COLOUR_NUMBER		0x0092aed1

.eqv	COLOUR_DIM_SHIFT	1122355						# colour shift 00x00112033

.eqv	NUM_STARS		160						# 40 stars (40*4)
.eqv	NUM_ROCKS		20						# 5 rocks (5*4)

.eqv	STAR_ROCK_PARLX		3
.eqv	INIT_WAIT_MS		23
.eqv	WAIT_CLOCK		200
.eqv	WAIT_EXPLOSION_DRAW	6


.data
# variables
# use arrays for storing obstacle locations
rocks:	.space			NUM_ROCKS					# array of 25 address for all the rock locations
stars:	.space			NUM_STARS					# array of 25 address for all the star locations

.text
.globl main

# SPACE JET

main:
	# ------------------------------------
	# clear screen
	li	$a0, DISPLAY_FIRST_ADDRESS
	li	$a1, DISPLAY_LAST_ADDRESS
	li	$a2, -SHIFT_NEXT_ROW						# negative width
	jal	clear								# jump to clear and save position to $ra
	# ------------------------------------

	# splash screen "SPACE JET"
	jal draw_splash
	# wait 2000 milliseconds
	li	$v0, 32
	li	$a0, 4000
	syscall

	# ------------------------------------
	# clear screen
	li	$a0, DISPLAY_FIRST_ADDRESS
	li	$a1, DISPLAY_LAST_ADDRESS
	li	$a2, -SHIFT_NEXT_ROW						# negative width
	jal	clear								# jump to clear and save position to $ra
	# ------------------------------------
	
	# GLOBAL variables
		# $s0: previous ship location
		# $s1: ship location
		# $s2: star shift increment
		# $s3: 1 if collision happened, 0 if not
		# $s4: clock (number of frames played)
		# $s5: number of lives
		# $s6: wait time (decreases as time goes on)
		# $s7: wait clock

	# main variables
		# $t9: temp
	


	# initialization:
		# ship location
		li	$s1, DISPLAY_MIDLFT_ADDRESS
		li	$s0, DISPLAY_LAST_ADDRESS				# make the previous position some else (I just put the last pixel)
		addi	$s0, $s0, -SHIFT_NEXT_ROW
		# stor vs. rock shift ratio
		li	$s2, STAR_ROCK_PARLX
		# collision flag
		li	$s3, 0
		# clock starts at -1, since it increments
		li	$s4, -1
		# start with 4 lives (each life is worth 10)
		li	$s5, 40
		# start with INIT_WAIT_MS
		li	$s6, INIT_WAIT_MS
		# start with WAIT_CLOCK cylces for this wait time
		li	$s7, WAIT_CLOCK
		
		# all the stars
		jal	init_stars
		# initialize all the rocks positions to 0, so they can be added in slowly
		jal	init_rocks
		
	main_loop:
		# ------------------------------------
		# Check for keyboard input and update ship location.
		li	$a0, 0xffff0000
		lw	$t9, 0($a0)
		bne	$t9, 1, main_update
		jal	keypress						# jump to keypress and save position to $ra
		# ------------------------------------

		# ------------------------------------
		# Update obstacle location.
		main_update:
			# shift stars every four loops (parallax effect)
			addi	$s2, $s2, -1
			bne	$s2, $zero, main_dont_shift_stars
			jal	shift_stars
			li	$s2, STAR_ROCK_PARLX
			main_dont_shift_stars:
			# shift rocks
			jal	shift_rocks
		# ------------------------------------
				
		# ------------------------------------
		# Update other game state and end of game.
			# increment clock
			addi	$s4, $s4, 1
			# update score
			li	$a0, DISPLAY_SCORE
			li	$a1, COLOUR_NUMBER
			move	$a2, $s4
			li	$a3, COLOUR_NIGHT
			jal	draw_number
			# update lives
			li	$a0, DISPLAY_LIVES
			move	$a1, $s5
			jal	draw_lives
			# GAME OVER (no more lives)
			ble	$s5, $zero end

			# decrease wait clock for current wait time
			addi	$s7, $s7, -1
			# decrease wait if wait clock is 0
			bne	$s7, $zero, main_collision
			# set min wait time to be 7
			li	$t9, 7
			beq	$s6, $t9, main_collision
			# reset clock
			li	$s7, WAIT_CLOCK
			addi	$s6, $s6, -1
		# ------------------------------------
	
		# ------------------------------------
		# Check for various collisions (e.g., between ship and 
		# obstacles).
		main_collision:
			# check if ship is colliding with a rock
			jal	rock_collide
		# ------------------------------------

		# ------------------------------------
		# Erase objects from the old position on the screen.
			# if ship HIT something, clear
			beq	$s3, $zero, main_move_check
			addi	$s3, $s3, -1					# let it show
			# lost a life
			addi	$s5, $s5, -1

			beq	$s3, $zero, main_clear
		main_move_check:
			# if ship didn't move, don't clear it
			beq	$s0, $s1, main_draw
		main_clear:
			# clear previous ship, two rows above, and two rows below (for explosion clean up)
			move	$a0, $s0
			addi	$a0, $a0, -SHIFT_NEXT_ROW
			addi	$a0, $a0, -SHIFT_NEXT_ROW
			move	$a1, $s0
			addi	$a1, $a1, SHIFT_SHIP_LAST
			addi	$a1, $a1, SHIFT_NEXT_ROW
			addi	$a1, $a1, SHIFT_NEXT_ROW
			li	$a2, -48
			jal	clear
		# ------------------------------------

		# ------------------------------------
		# Redraw objects in the new position on the screen.
		main_draw:
			# redraw ship:
			move	$a0, $s1
			jal	draw_ship					# jump to draw_ship and save position to $ra
			move 	$s0, $s1					# store previous ship position in $s0
			# if it has HIT something, draw explosion
			ble	$s3, $zero, main_sleep
			move	$a0, $s1
			jal	draw_explosion
		# ------------------------------------


		# ------------------------------------
		# At the end of each iteration, your main loop should sleep 
		# for a short time and go back to step 1.
		main_sleep:
			# Wait one second (20 milliseconds)
			# decremennt if 
			li	$v0, 32
			move	$a0, $s6
			syscall
		# ------------------------------------

		j main_loop
# end program
end:
	# clear last life
	li	$a0, DISPLAY_LIVES
	jal draw_heart_clear
	# draw dead
	jal	draw_dead
	# darken screen
	jal	draw_dark
	# end program
	li	$v0, 10								# $v0 = 10 terminate the program gracefully
	syscall




#####################################################################
#                        my functions                               #
#####################################################################

# ------------------------------------
# handling different keypresses
	# $a0: 0xfff0000
	# use:
		# $t1: width
		# $t2: address of first of second row
		# $t3: address of last of second last row 
		# $t
		# $t9: temp
keypress:
	li	$t1, SHIFT_NEXT_ROW
	li	$t2, DISPLAY_FIRST_ADDRESS
	addi	$t2, $t2, SHIFT_NEXT_ROW
	li	$t3, DISPLAY_LAST_ADDRESS
	addi	$t3, $t3, -SHIFT_SHIP_LAST
	addi	$t3, $t3, -SHIFT_NEXT_ROW
	
	lw	$t0, 4($a0)
	beq	$t0, 0x61, key_a						# ASCII code of 'a' is 0x61 or 97 in decimal
	beq	$t0, 0x77, key_w						# ASCII code of 'w' is 0x77
	beq	$t0, 0x64, key_d						# ASCII code of 'd' is 0x64
	beq	$t0, 0x73, key_s						# ASCII code of 's' is 0x73
	beq	$t0, 0x70, key_p						# ASCII code of 'p' is 0x70

	# go left
	key_a:
		# make sure ship is not in left column
		div	$s1, $t1						# see if ship position is divisible by the width
		mfhi	$t9							# $t9 = $s1 mod $t1 
		beq	$t9, $zero, keypress_done				# if it is in the left column, we can't go left
		addi	$s1, $s1, -8						# else, move left
		b keypress_done

	# go up
	key_w:
		# make sure ship is not in top row
		blt	$s1, $t2, keypress_done					# if $s1 is in the top row, don't go up
		addi	$s1, $s1, -SHIFT_NEXT_ROW				# else, move up
		addi	$s1, $s1, -SHIFT_NEXT_ROW				# else, move up
		b keypress_done

	# go right
	key_d:
		# make sure ship is not in right column
		div	$s1, $t1						# see if ship position is divisible by the width
		mfhi	$t9							# $t9 = $s1 mod $t1 
		addi	$t1, $t1, -48						# need to check if the mod is the row size - 12*4 (width of plane-1)
		beq	$t9, $t1, keypress_done					# if it is in the far right column, we can't go right
		addi	$s1, $s1, 8						# else, move right
		b keypress_done

	# go down
	key_s:
		# make sure ship is not in bottom row
		bgt	$s1, $t3, keypress_done					# if $s1 is in the bottom row, don't go down
		addi	$s1, $s1, SHIFT_NEXT_ROW				# else, move down
		addi	$s1, $s1, SHIFT_NEXT_ROW				# else, move down
		b keypress_done

	key_p:
		# restart game
		la	$ra, main
		b keypress_done

	keypress_done:
		jr	$ra							# jump to ra
# ------------------------------------



# COLLIDE

# ------------------------------------
# check if the ship has smashed into any rocks
	# use:
		# $t0: current rock address
		# $t1: address of block right after the array
		# $t2: position of current rock (and corner we are checking)
		# --
		# $t3: top-left of current rock    --- then x_top-left
		# $t4:                             --- then y_top-left
		# $t5: top-right of current rock   --- then x_top-right
		# $t6: bottom-left of current rock --- then y_bottom-left			# don't need bottom-right      $t6: bottom-right of current rock
		# --
		# $t7: current ship corner:        --- x_ship
		# $t8:                             --- y_ship
	# assumes:
		# $s1: contains the current ship position
rock_collide:
	# load rocks array
	la	$t0, rocks
	la	$t1, rocks
	addi	$t1, $t1, NUM_ROCKS
	# store this function's $ra for later
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	
	# for each rock
	rock_collide_loop:
		# get position in $t0, put it in $t2
		lw	$t2, 0($t0)
		# check if the ship box at $s1 has overlap with the rock at position $t2
			# get the corners of the rock
				# get top-left
				move 	$t3, $t2
				addi	$t3, $t3, SHIFT_NEXT_ROW
				addi	$t3, $t3, 4	# 1 to the left
				# get top-right
				move 	$t5, $t3
				addi	$t5, $t5, 20	# 5 more to the left
				# get bottom-left
				move 	$t6, $t3
				addi	$t6, $t6, SHIFT_NEXT_ROW
				addi	$t6, $t6, SHIFT_NEXT_ROW
				addi	$t6, $t6, SHIFT_NEXT_ROW
				addi	$t6, $t6, SHIFT_NEXT_ROW
			# get x,y of corners
				# get $t3 = x_top-left, $t4 = y_top-left
				move 	$a0, $t3
				jal	get_xy
				move 	$t3, $v0
				move 	$t4, $v1
				# get $t5 = x_top-right
				move 	$a0, $t5
				jal	get_xy
				move 	$t5, $v0
				# get $t6 = y_bottom-left
				move 	$a0, $t6
				jal	get_xy
				move 	$t6, $v1
			# check if any of the hit points of ship are in the rock box (HIT)
				# get x,y of ship: $t7 = x_ship, $t8 = y_ship
				move 	$a0, $s1
				jal	get_xy
				move 	$t7, $v0
				move 	$t8, $v1
				# check top-left ship pixel
				addi	$t7, $t7, 16	# 4 right
				addi	$t8, $t8, 1	# 1 down		# NOTE: vertical y moves by 1s!!
				# check if it collided				#       horizontal x moves by 4s!!
				jal	check_collide
				
				# check top-right ship pixel
				addi	$t7, $t7, 20	# 5 right
				addi	$t8, $t8, 1	# 1 down
				# check if it collided
				jal	check_collide

				# check bottom-right ship pixel
				addi	$t7, $t7, -4	# 1 left
				addi	$t8, $t8, 1	# 1 down
				# check if it collided
				jal	check_collide

				# check bottom-left ship pixel
				addi	$t7, $t7, -20	# 5 left
				# check if it collided
				jal	check_collide

		# go to next rock, increment $t0
		addi	$t0, $t0, 4
		# break when done, $t0==$t1
		bne	$t0, $t1, rock_collide_loop
		
	# pop saved $ra
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
# ------------------------------------
# ------------------------------------
# direct helper part of rock_collide
	# uses (does not change): register setup in rock_collide
check_collide:
	# save return register $ra
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# check 
	# x_top-left <= x_ship
	bgt	$t3, $t7, check_collide_done
	# x_top-right >= x_ship
	blt	$t5, $t7, check_collide_done
	# y_top-left <= y_ship
	bgt	$t4, $t8, check_collide_done
	# y_bottom-left >= y_ship
	blt	$t6, $t8, check_collide_done
	# if all true, HIT!
	move 	$a0, $s1
	# want to draw it for 4 frames: $s3 = 4
	li	$s3, WAIT_EXPLOSION_DRAW
	jal	draw_explosion
	
	# done
	check_collide_done:
		# return to saved $ra
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr	$ra
# ------------------------------------

# ------------------------------------
# get x,y of pixel
	# $a0: pixel position on screen
	# returns:
		# $v0: x
		# $v1: y	NOTE: y counts down!
	# use: 
		# $a1: temp
get_xy:
	addi	$a0, $a0, -DISPLAY_FIRST_ADDRESS				# get the relative position
	li	$a1, SHIFT_NEXT_ROW
	div	$a0, $a1							# $a0 / $t9
	mflo	$v1								# $v1 = y = floor($a0 / $t9) 
	mfhi	$v0								# $v0 = x = $a0 mod $t9 
	jr	$ra
# ------------------------------------



# STARS and ROCKS

# ------------------------------------
# initialize the stars
	# use:
		# $t0: current star address
		# $t1: address of block right after the array
		# $t2: random position for current star
init_stars:
	la	$t0, stars
	la	$t1, stars
	addi	$t1, $t1, NUM_STARS						# address of the block right after the array, this is where we stop
	addi	$sp, $sp, -8							# use stack to hold $t0 and $ra when call draw_star
	sw	$ra, 4($sp)		
	
	init_stars_loop:
		# get random shift for the star position
		li	$v0, 42
		li	$a0, 0
		li	$a1, SIZE
		syscall
		# pseudo-random number is in $a0
		# let this be the position of the current star
		sll	$a0, $a0, 2						# multiply that shift by 4
		addi	$a0, $a0, DISPLAY_FIRST_ADDRESS			 	# add it to the first address of the image
		sw	$a0, 0($t0)						# set that address to be the position of the current star
		# save $t0 and $ra
		# sw	$t0, 0($sp)
		# call draw star
		jal	draw_star
		# restore $t0 and $ra						draw the star at $a0 position
		# lw	$t0, 0($sp)
		# set the next star
		addi	$t0, $t0, 4
		beq	$t0, $t1, init_stars_loop_done				# stop once we've set all the stars
		j init_stars_loop
	init_stars_loop_done:
		lw	$ra, 4($sp)		
		addi	$sp, $sp, 8
		jr	$ra							# jump to $ra
# ------------------------------------

# ------------------------------------
# initialize rock positions to just 0 and add them in slowly
	# use:
		# $t0: current rock address
		# $t1: address of block right after the array
		# $t2: random position for current rock
init_rocks:
	la	$t0, rocks
	la	$t1, rocks
	addi	$t1, $t1, NUM_ROCKS						# address of the block right after the array, this is where we stop
	addi	$sp, $sp, -8							# use stack to hold $t0 and $ra when call draw_star
	sw	$ra, 4($sp)		
	
	init_rocks_loop:
		# get random shift for the rock position
		li	$v0, 42
		li	$a0, 0
		li	$a1, SIZE
		syscall
		# pseudo-random number is in $a0
		# let this be the position of the current rock
		sll	$a0, $a0, 2						# multiply that shift by 4
		addi	$a0, $a0, DISPLAY_FIRST_ADDRESS			 	# add it to the first address of the image
		sw	$a0, 0($t0)						# set that address to be the position of the current star
		# save $t0 and $ra
		# sw	$t0, 0($sp)
		# call draw star
		jal	draw_rock
		# restore $t0 and $ra						draw the star at $a0 position
		# lw	$t0, 0($sp)
		# set the next star
		addi	$t0, $t0, 4
		beq	$t0, $t1, init_rocks_loop_done				# stop once we've set all the stars
		j init_rocks_loop
	init_rocks_loop_done:
		lw	$ra, 4($sp)		
		addi	$sp, $sp, 8
		jr	$ra							# jump to $ra
# ------------------------------------

# ------------------------------------
# shift stars
	# use:
		# $t0: current star address
		# $t1: address of block right after the array
		# $t2: position of current star
		# $t9: temp
shift_stars:
	la	$t0, stars
	la	$t1, stars
	addi	$t1, $t1, NUM_STARS
	# make room on the stack to store needed values
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)							# store this function's $ra for later	
	
	shift_stars_loop:
		lw	$t2, 0($t0)
		# clear previous spot
			move 	$a0, $t2
			move 	$a1, $a0
			li	$a2, -4
			# save needed values
			# sw	$t0, 0($sp)
			# sw	$t1, 4($sp)
			# sw	$t2, 8($sp)
			# call
			jal	clear
			# restore needed values
			# lw	$t0, 0($sp)
			# lw	$t1, 4($sp)
			# lw	$t2, 8($sp)
		# only shift if they are not in the left column
			li	$t9, SHIFT_NEXT_ROW
			div	$t2, $t9					# $t2 / $t9
			mfhi	$t9						# $t9 = $t2 mod $t9
			beq	$t9, $zero, shift_stars_reset			# if the star is in the left column, we need to reset it
			addi	$t2, $t2, -4					# else move left
		# redraw new position
		shift_stars_redraw:
			move 	$a0, $t2
			# save needed values
			# sw	$t0, 0($sp)
			# sw	$t1, 4($sp)
			# sw	$t2, 8($sp)
			# call
			jal	draw_star
			# restore needed values
			# lw	$t0, 0($sp)
			# lw	$t1, 4($sp)
			# lw	$t2, 8($sp)
		# update the position of that star and go to next star
		sw	$t2, 0($t0)
		addi	$t0, $t0, 4
		# if we are at the block right after the array, we are done, else continue
		beq	$t0, $t1, shift_stars_loop_done
		j	shift_stars_loop

		# find position for new star
		shift_stars_reset:
			# use random to get new value for star on the right
			li	$v0, 42
			li	$a0, 0
			li	$a1, HEIGHT
			syscall
			# pseudo-random number is in $a0
			# let this be the position of the current star in the right most column
			addi	$a0, $a0, 1
			li	$t9, SHIFT_NEXT_ROW
			mult	$t9, $a0
			mflo	$t9						# we got y position in left column
			addi	$t9, $t9, -4
			addi	$t9, $t9, DISPLAY_FIRST_ADDRESS
			# now we have position for new star
			move 	$t2, $t9
			j shift_stars_redraw		
	shift_stars_loop_done:
		lw	$ra, 12($sp)						# restore this functions $ra
		addi	$sp, $sp, 16						# put the stack pointer back
		jr	$ra
# ------------------------------------

# ------------------------------------
# shift rocks
	# use:
		# $t0: current rock address
		# $t1: address of block right after the array
		# $t2: position of current rock
		# $t9: temp
shift_rocks:
	la	$t0, rocks
	la	$t1, rocks
	addi	$t1, $t1, NUM_ROCKS
	# make room on the stack to store needed values
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)							# store this function's $ra for later	
	
	shift_rocks_loop:
		lw	$t2, 0($t0)
		# clear previous spot
			move 	$a0, $t2
			move 	$a1, $a0
			addi	$a1, $a1, SHIFT_ROCK_LAST
			li	$t9, DISPLAY_LAST_ADDRESS
			blt	$a1, $t9, full_rock
			li	$a1, DISPLAY_LAST_ADDRESS
			full_rock:
			li	$a2, -ROCK_WIDTH
			# save needed values
			# sw	$t0, 0($sp)
			# sw	$t1, 4($sp)
			# sw	$t2, 8($sp)
			# call
			jal	clear
			# restore needed values
			# lw	$t0, 0($sp)
			# lw	$t1, 4($sp)
			# lw	$t2, 8($sp)
		# only shift if they are not in the left column
			li	$t9, SHIFT_NEXT_ROW
			div	$t2, $t9					# $t2 / $t9
			mfhi	$t9						# $t9 = $t2 mod $t9
			beq	$t9, $zero, shift_rocks_reset			# if the star is in the left column, we need to reset it
			addi	$t2, $t2, -4					# else move left
		# redraw new position
		shift_rocks_redraw:
			move 	$a0, $t2
			# save needed values
			# sw	$t0, 0($sp)
			# sw	$t1, 4($sp)
			# sw	$t2, 8($sp)
			# call
			jal	draw_rock
			# restore needed values
			# lw	$t0, 0($sp)
			# lw	$t1, 4($sp)
			# lw	$t2, 8($sp)
		# update the position of that rocks and go to next rock
		sw	$t2, 0($t0)
		addi	$t0, $t0, 4
		# if we are at the block right after the array, we are done, else continue
		beq	$t0, $t1, shift_rocks_loop_done
		j	shift_rocks_loop

		# find position for new star
		shift_rocks_reset:
			# use random to get new value for rock on the right
			li	$v0, 42
			li	$a0, 0
			li	$a1, HEIGHT
			syscall
			# pseudo-random number is in $a0
			# let this be the position of the current rock in the right most column
			addi	$a0, $a0, 1
			li	$t9, SHIFT_NEXT_ROW
			mult	$t9, $a0
			mflo	$t9						# we got y position in left column
			addi	$t9, $t9, -4
			addi	$t9, $t9, DISPLAY_FIRST_ADDRESS
			# now we have position for new rock
			move 	$t2, $t9
			j shift_rocks_redraw		
	shift_rocks_loop_done:
		lw	$ra, 12($sp)						# restore this functions $ra
		addi	$sp, $sp, 16						# put the stack pointer back
		jr	$ra
# ------------------------------------







# DRAW functions:

# ------------------------------------
# clear screen between given addresses
	# $a0: start address
	# $a1: end address
	# $a2: negative of the width*4 of box to clear
	# useS:
		# $t8: COLOUR_NIGHT
		# $t9: negative increment
clear:
	li	$t8, COLOUR_NIGHT
	li	$t9, 0								# increment
	
	clear_loop:
		bgt	$a0, $a1, clear_loop_done
		# if the increment is equal to the negative width, go down a row
		beq	$t9, $a2, clear_loop_next_row
		sw	$t8, 0($a0)						# clear $a0 colour
		addi	$a0, $a0, 4						# $a0 = $a0 + 4
		addi	$t9, $t9, -4						# $t9 = $t9 - 4
		j	clear_loop						# jump to clear_loop
	clear_loop_next_row:
		add	$a0, $a0, $t9						# $a0 = $a0 - width*4
		addi	$a0, $a0, SHIFT_NEXT_ROW				# set $a0 to next row
		li	$t9, 0							# reset increment $t9 = 0
		j clear_loop
	clear_loop_done:
		jr	$ra							# jump to $ra
# ------------------------------------


# ------------------------------------
# draw ship at a certain position
	# $a0: position
	# uses:
		# $t0, COLOUR_SHIP
		# $t1, COLOUR_YELLOW
		# $t2, COLOUR_RED
draw_ship:
	li	$t0, COLOUR_SHIP						# $t1 = COLOUR_SHIP
	li	$t1, COLOUR_YELLOW						# $t1 = COLOUR_YELLOW
	li	$t2, COLOUR_RED							# $t1 = COLOUR_RED
	
	sw	$t2, 0($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t2, 0($a0)
	sw	$t2, 4($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	sw	$t0, 28($a0)
	sw	$t0, 32($a0)
	sw	$t0, 36($a0)
	sw	$t0, 40($a0)
	sw	$t0, 44($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	# sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	sw	$t0, 28($a0)
	sw	$t0, 32($a0)
	sw	$t0, 36($a0)
	sw	$t2, 40($a0)
	sw	$t2, 44($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t2, 16($a0)
	sw	$t2, 20($a0)
	sw	$t2, 24($a0)
	sw	$t2, 28($a0)
	sw	$t2, 32($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t2, 8($a0)
	sw	$t2, 12($a0)

	jr	$ra								# jump to 
# ------------------------------------

# ------------------------------------
# draw "bang" when ship smashes rock
	# $a0: position
	# uses:
		# $a1: COLOUR_EXPLOSION
		# $
draw_explosion:
	li	$a1, COLOUR_EXPLOSION
	# maybe set it more right
	addi	$a0, $a0, 8

	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	sw	$a1, 20($a0)
	sw	$a1, 24($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 12($a0)
	sw	$a1, 24($a0)
	sw	$a1, 28($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 32($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 16($a0)
	sw	$a1, 28($a0)
	sw	$a1, 32($a0)
	sw	$a1, 36($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 8($a0)
	sw	$a1, 36($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 24($a0)
	sw	$a1, 32($a0)
	sw	$a1, 36($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 16($a0)
	sw	$a1, 28($a0)
	sw	$a1, 32($a0)
	sw	$a1, 36($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 20($a0)
	sw	$a1, 32($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 20($a0)
	sw	$a1, 24($a0)
	sw	$a1, 28($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 8($a0)
	
	jr	$ra
# ------------------------------------

# ------------------------------------
# draw star at given position
	# $a0: position
	# uses:
		# $t9: use temp
draw_star:
	li	$t9, COLOUR_STAR
	sw	$t9, 0($a0)
	jr	$ra
# ------------------------------------

# ------------------------------------
# draw rock
	# use:
		# $t8: COLOUR_ROCK_DARK
		# $t9: COLOUR_ROCK_LIGHT
draw_rock:
	li	$t8, COLOUR_ROCK_DARK
	li	$t9, COLOUR_ROCK_LIGHT

	sw	$t8, 8($a0)
	sw	$t8, 12($a0)
	sw	$t8, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 4($a0)
	sw	$t9, 8($a0)
	sw	$t8, 12($a0)
	sw	$t8, 16($a0)
	sw	$t8, 20($a0)
	sw	$t8, 24($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 0($a0)
	sw	$t8, 4($a0)
	sw	$t9, 8($a0)
	sw	$t8, 12($a0)
	sw	$t8, 16($a0)
	sw	$t9, 20($a0)
	sw	$t9, 24($a0)
	sw	$t9, 28($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 0($a0)
	sw	$t8, 4($a0)
	sw	$t8, 8($a0)
	sw	$t8, 12($a0)
	sw	$t8, 16($a0)
	sw	$t8, 20($a0)
	sw	$t8, 24($a0)
	sw	$t9, 28($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t8, 4($a0)
	sw	$t8, 8($a0)
	sw	$t8, 12($a0)
	sw	$t8, 16($a0)
	sw	$t8, 20($a0)
	sw	$t9, 24($a0)
	sw	$t9, 28($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 4($a0)
	sw	$t8, 8($a0)
	sw	$t8, 12($a0)
	sw	$t8, 16($a0)
	sw	$t9, 20($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t8, 12($a0)
	sw	$t8, 16($a0)

	jr	$ra
# ------------------------------------

# ------------------------------------
# draw dark
draw_dark:
	li	$a0, DISPLAY_FIRST_ADDRESS
	li	$a1, DISPLAY_LAST_ADDRESS

	draw_dark_loop:
		lw	$t7, 0($a0)
		addi	$t7, $t7, -COLOUR_DIM_SHIFT
		sw	$t7, 0($a0)
		addi	$a0, $a0, 4
		bgt	$a1, $a0, draw_dark_loop
	
	jr	$ra
# ------------------------------------





# ------------------------------------
# draw DEAD
	# uses:
		# $a0: DISPLAY_DEAD
		# $a1: COLOUR_NUMBER
		# #t9: hold old $ra
draw_dead:
	li	$a1, COLOUR_NUMBER
	move 	$t9, $ra

	li	$a0, DISPLAY_DEAD
	jal	draw_D
	li	$a0, DISPLAY_DEAD
	addi	$a0, $a0, 20
	jal	draw_E
	li	$a0, DISPLAY_DEAD
	addi	$a0, $a0, 40
	jal	draw_A
	li	$a0, DISPLAY_DEAD
	addi	$a0, $a0, 60
	jal	draw_D
	
	jr	$t9
# ------------------------------------

# ------------------------------------
# draw slash
		# $a0: DISPLAY_SPLASH
		# $a1: COLOUR_NUMBER
		# #t9: hold old $ra
draw_splash:
	li	$a1, COLOUR_NUMBER
	move 	$t9, $ra

	li	$a0, DISPLAY_SPLASH
	jal	draw_S
	li	$a0, DISPLAY_SPLASH
	addi	$a0, $a0, 20
	jal	draw_P
	li	$a0, DISPLAY_SPLASH
	addi	$a0, $a0, 40
	jal	draw_A
	li	$a0, DISPLAY_SPLASH
	addi	$a0, $a0, 60
	jal	draw_C
	li	$a0, DISPLAY_SPLASH
	addi	$a0, $a0, 80
	jal	draw_E
	li	$a0, DISPLAY_SPLASH
	addi	$a0, $a0, 108
	jal	draw_J
	li	$a0, DISPLAY_SPLASH
	addi	$a0, $a0, 128
	jal	draw_E
	li	$a0, DISPLAY_SPLASH
	addi	$a0, $a0, 148
	jal	draw_T

	li	$a0, DISPLAY_SPLASH
	addi	$a0, $a0, 168
	jal	draw_ship

	jr	$t9
# ------------------------------------






# DRAW LIVES

# ------------------------------------
# draw lives
	# $a0: position
	# $a1: number of lives
draw_lives:
	b	draw_heart
	draw_lives_next:
	addi	$a1, $a1, -10
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -24
	bgt	$a1, $zero, draw_lives
	# clear last heart
	b draw_heart_clear
	draw_lives_end:
	jr	$ra
# ------------------------------------

# ------------------------------------
# draw heart
	# $a0: position
		# $t9: COLOUR_HEART
draw_heart:
	li	$t9, COLOUR_HEART
	
	sw	$t9, 0($a0)
	sw	$t9, 4($a0)
	sw	$t9, 12($a0)
	sw	$t9, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 0($a0)
	sw	$t9, 4($a0)
	sw	$t9, 8($a0)
	sw	$t9, 12($a0)
	sw	$t9, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 4($a0)
	sw	$t9, 8($a0)
	sw	$t9, 12($a0)	
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 8($a0)
	
	b	draw_lives_next
# ------------------------------------

# ------------------------------------
# draw heart clear
	# $a0: position
		# $t9: COLOUR_NIGHT
draw_heart_clear:
	li	$t9, COLOUR_NIGHT
	
	sw	$t9, 0($a0)
	sw	$t9, 4($a0)
	sw	$t9, 12($a0)
	sw	$t9, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 0($a0)
	sw	$t9, 4($a0)
	sw	$t9, 8($a0)
	sw	$t9, 12($a0)
	sw	$t9, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 4($a0)
	sw	$t9, 8($a0)
	sw	$t9, 12($a0)	
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 8($a0)
	
	b	draw_lives_end
# ------------------------------------





# DRAW NUMBERS

# ------------------------------------
# draw number
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a2: number to draw
	# $a3: COLOUR_NIGHT
		# $t7: temp
		# $t8: tens place we are looking at
		# $t9: current digit to draw 
draw_number:
	li	$t8, 10
	div	$a2, $t8							# $a2 / $t8
	mflo	$a2								# $a2 = floor($a2 / $t8) 
	mfhi	$t9								# $t9 = $a2 mod $t8 

	# if both the division and the remainder are 0 than stop
	bne	$a2, $zero, draw_number_zero
	bne	$t9, $zero, draw_number_zero
	jr	$ra

	draw_number_zero: 
	li	$t7, 0
	bne	$t9, $t7, draw_number_one
	b	draw_zero
	draw_number_one: 
	li	$t7, 1
	bne	$t9, $t7, draw_number_two
	b	draw_one
	draw_number_two: 
	li	$t7, 2
	bne	$t9, $t7, draw_number_three
	b	draw_two
	draw_number_three: 
	li	$t7, 3
	bne	$t9, $t7, draw_number_four
	b	draw_three
	draw_number_four: 
	li	$t7, 4
	bne	$t9, $t7, draw_number_five
	b	draw_four
	draw_number_five: 
	li	$t7, 5
	bne	$t9, $t7, draw_number_six
	b	draw_five
	draw_number_six: 
	li	$t7, 6
	bne	$t9, $t7, draw_number_seven
	b	draw_six
	draw_number_seven: 
	li	$t7, 7
	bne	$t9, $t7, draw_number_eight
	b	draw_seven
	draw_number_eight: 
	li	$t7, 8
	bne	$t9, $t7, draw_number_nine
	b	draw_eight
	draw_number_nine: 
	li	$t7, 9
	bne	$t9, $t7, draw_number_next
	b	draw_nine

	draw_number_next:
	# shift draw number position
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -16

	b draw_number

# ------------------------------------

# ------------------------------------
# draw_zero
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_zero:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_one
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_one:
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_two
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_two:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a3, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_three
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_three:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_four
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_four:
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_five
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_five:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a3, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_six
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_six:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a3, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_seven
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_seven:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_eight
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_eight:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_nine
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_nine:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------






# DRAW LETTERS

# ------------------------------------
# draw A
	# $a0: position
	# $a1: colour
draw_A:
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	
	jr	$ra
# ------------------------------------

# ------------------------------------
# draw C
	# $a0: position
	# $a1: colour
draw_C:
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	
	jr	$ra
# ------------------------------------

# ------------------------------------
# draw D
	# $a0: position
	# $a1: colour
draw_D:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	
	jr	$ra
# ------------------------------------

# ------------------------------------
# draw E
	# $a0: position
	# $a1: colour
draw_E:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 12($a0)
	
	jr	$ra
# ------------------------------------

# ------------------------------------
# draw J
	# $a0: position
	# $a1: colour
draw_J:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	
	jr	$ra
# ------------------------------------

# ------------------------------------
# draw P
	# $a0: position
	# $a1: colour
draw_P:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	
	jr	$ra
# ------------------------------------

# ------------------------------------
# draw S
	# $a0: position
	# $a1: colour
draw_S:
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	
	jr	$ra
# ------------------------------------

# ------------------------------------
# draw T
	# $a0: position
	# $a1: colour
draw_T:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 8($a0)
	
	jr	$ra
# ------------------------------------
