#####################################################################
#
# CSCB58 Winter 2021 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Andrew D'Amario, 1006618947, damario4
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8 (update this as needed)
# - Unit height in pixels: 8 (update this as needed)
# - Display width in pixels: 256 (update this as needed)# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3/4 (choose the one the applies)
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes / no / yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

# defined CONSTANTS
.eqv	DISPLAY_FIRST_ADDRESS	0x10008000
# width = 64, height = 32
.eqv	DISPLAY_LAST_ADDRESS	0x10009FFC					# update this given the values below shift +(64*32-1)*4
.eqv	DISPLAY_MIDLFT_ADDRESS	0x10008C00					# mid left spot for ship (but jump 2 aligned) +(64*12)*4
# last address shifts
.eqv	SHIFT_NEXT_ROW		256													# next row shift = width*4 = 64*4
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

.eqv	NUM_STARS		160						# 40 stars (40*4)
.eqv	NUM_ROCKS		24						# 5 rocks (5*4)

.eqv	STAR_ROCK_PARLX		3
.eqv	WAIT_MS			5

.data
# variables
# use arrays for storing obstacle locations
rocks:	.space			NUM_ROCKS					# array of 25 address for all the rock locations
stars:	.space			NUM_STARS					# array of 25 address for all the star locations

.text
.globl main

main:
	# ------------------------------------
	# clear screen
	li	$a0, DISPLAY_FIRST_ADDRESS
	li	$a1, DISPLAY_LAST_ADDRESS
	li	$a2, -SHIFT_NEXT_ROW						# negative width
	jal	clear								# jump to clear and save position to $ra
	# ------------------------------------
	
	# main variables
		# $s0: previous ship location
		# $s1: ship location
		# $s2: star shift increment
		# $t9: temp

	# initialization:
		# ship location
		li	$s1, DISPLAY_MIDLFT_ADDRESS
		li	$s0, DISPLAY_LAST_ADDRESS				# make the previous position some else (I just put the last pixel)
		addi	$s0, $s0, -SHIFT_NEXT_ROW
		li	$s2, STAR_ROCK_PARLX
		
		
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

		# ------------------------------------\
		# Update obstacle location.
		main_update:
			# shift stars every four loops (parallax effect)
			addi	$s2, $s2, -1
			bne	$s2, $zero, main_dont_shift_stars
			jal shift_stars
			li	$s2, STAR_ROCK_PARLX
			main_dont_shift_stars:
			# shift rocks
			jal shift_rocks
		# ------------------------------------
		
		# ------------------------------------
		# Check for various collisions (e.g., between ship and 
		# obstacles).
		main_collision:
			# check if ship is colliding with a rock
			# jal	rock_collide
			
		# ------------------------------------
		
		# ------------------------------------
		# Update other game state and end of game.
		# ------------------------------------
		
		# ------------------------------------
		# Erase objects from the old position on the screen.
		main_clear:
			# clear previous ship
			beq	$s0, $s1, main_draw				# if ship didn't move, don't clear it
			move	$a0, $s0
			move	$a1, $s0
			addi	$a1, $a1, SHIFT_SHIP_LAST
			li	$a2, -48
			jal	clear
		# ------------------------------------

		# ------------------------------------
		# Redraw objects in the new position on the screen.
		main_draw:
			# redraw ship:
			move	$a0, $s1
			jal	draw_ship					# jump to draw_ship and save position to $ra
			# redraw stars:
		# ------------------------------------

		move 	$s0, $s1						# store previous ship position in $s0

		# ------------------------------------
		# At the end of each iteration, your main loop should sleep 
		# for a short time and go back to step 1.
		main_sleep:
			# Wait one second (20 milliseconds)
			li	$v0, 32
			li	$a0, WAIT_MS
			syscall
		# ------------------------------------

		j main_loop
# end program
end:
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
		# $t7: corner of ship we are looking at
		#      top-left of ship
		#      top-right of ship
		#      bottom-left of ship
		#      bottom-right of ship
		# $t8:                             --- then x_ship
		# $t9:                             --- then y_ship
	# assumes:
		# $s1: contains the current ship position
rock_collide:
	# load rocks array
	la	$t0, rocks
	la	$t1, rocks
	addi	$t1, $t1, NUM_ROCKS
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)							# store this function's $ra for later	

	move 	$a0, $s1							# set top-left
	addi	$a0, $a0, SHIFT_NEXT_ROW
	addi	$a0, $a0, 4	# 1 to the left
	move 	$a1, $a0							# top-right
	addi	$a1, $a1, SHIFT_NEXT_ROW
	addi	$a1, $a1, 36	# 9 more to the left
	move 	$a2, $a0							# bottom-left
	addi	$a2, $a2, SHIFT_NEXT_ROW
	addi	$a2, $a2, SHIFT_NEXT_ROW
	move 	$a3, $a2							# bottom-right of ship
	addi	$a3, $a3, 36	# 9 more to the left
	
	# for each rock
	rock_collide_loop:
		# get position in $t0, put it in $t2
		lw	$t2, 0($t0)
		# check if the ship box at $s1 has overlap with the rock at position $t2
			# get the corners of the rock
				move 	$t3, $t2				# set top-left
				addi	$t3, $t3, SHIFT_NEXT_ROW
				addi	$t3, $t3, 4	# 1 to the left
				move 	$t4, $t3				# top-right
				addi	$t4, $t4, 20	# 5 more to the left
				move 	$t5, $t3				# bottom-left
				addi	$t5, $t5, SHIFT_NEXT_ROW
				addi	$t5, $t5, SHIFT_NEXT_ROW
				addi	$t5, $t5, SHIFT_NEXT_ROW
				addi	$t5, $t5, SHIFT_NEXT_ROW
				move 	$t6, $t5				# bottom-right of ship
				addi	$t5, $t5, 16	# 4 more to the left
			# check if top-left of ship is in the rock box
				# get top-left of ship x,y
				# x_ship < 
			# if yes, draw_explosion
		# go to next rock, increment $t0
		# break when done, $t0==$t1
	jr	$ra
# ------------------------------------

# ------------------------------------
# get x,y of pixel
	# $a0: pixel position on screen
	# returns:
		# $v0: x
		# $v1: y
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
	# use:
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
# draw "band" when ship smashes rock
	# $a0: position
draw_explosion:

# ------------------------------------


# ------------------------------------
# draw star at given position
	# $a0: position
		# $t9: use temp
draw_star:
	li	$t9, COLOUR_STAR
	sw	$t9, 0($a0)
	jr	$ra
# ------------------------------------

# ------------------------------------
# draw rock
	# $a0: position
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
	
	
