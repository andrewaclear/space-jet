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
.eqv	DISPLAY_MIDLFT_ADDRESS	0x10008D00					# mid left spot for ship +(64*13)*4
# last address shifts
.eqv	SHIFT_NEXT_ROW		256						# next row shift = width*4 = 64*4
.eqv	SHIFT_SHIP_LAST		1324						# from top left of ship to bottom right = (64*5+11)*4
# number of pixels
.eqv	SIZE			2047						# number of pixels - 1 so can use index

.eqv	COLOUR_NIGHT		0x00112135
.eqv	COLOUR_STAR		0x0019324f
# .eqv	COLOUR_NIGHT		0x00c8ddfd
.eqv	COLOUR_RED		0x00551c3a
.eqv	COLOUR_DARK_ROCK	0x00393f44
# .eqv	COLOUR_BLUE		0x00304698
.eqv	COLOUR_BLUE		0x00383bd6
# .eqv	COLOUR_YELLOW		0x00dcff30
# .eqv	COLOUR_YELLOW		0x005c7173
.eqv	COLOUR_YELLOW		0x007b979a

.eqv	NUM_STARS		160
.eqv	NUM_ROCKS		120

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
		# $t9: temp

	# initialization:
		# ship location
		li	$s1, DISPLAY_MIDLFT_ADDRESS
		li	$s0, DISPLAY_LAST_ADDRESS				# make the previous position some else (I just put the last pixel)
		addi	$s0, $s0, -SHIFT_NEXT_ROW
		
		# all the stars
		jal	init_stars

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
			# shift stars
			jal shift_stars
		# ------------------------------------
		
		# ------------------------------------
		# Check for various collisions (e.g., between ship and 
		# obstacles).
		# ------------------------------------
		
		# ------------------------------------
		# Update other game state and end of game.
		# ------------------------------------
		
		# ------------------------------------
		# Erase objects from the old position on the screen.
		# clear previous ship
		beq	$s0, $s1, main_sleep					# if ship didn't move, restart loop
		move	$a0, $s0
		move	$a1, $s0
		addi	$a1, $a1, SHIFT_SHIP_LAST
		li	$a2, -48
		jal	clear
		# ------------------------------------

		# ------------------------------------
		# Redraw objects in the new position on the screen.
		# redraw ship:
			# paint new
			move	$a0, $s1
			jal	draw_ship						# jump to draw_ship and save position to $ra
		# redraw stars:
		# ------------------------------------

		move 	$s0, $s1						# store previous ship position in $s0

		# ------------------------------------
		# At the end of each iteration, your main loop should sleep 
		# for a short time and go back to step 1.
		main_sleep:
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
		addi	$s1, $s1, -4						# else, move left
		b keypress_done

	# go up
	key_w:
		# make sure ship is not in top row
		blt	$s1, $t2, keypress_done					# if $s1 is in the top row, don't go up
		addi	$s1, $s1, -SHIFT_NEXT_ROW				# else, move up
		b keypress_done

	# go right
	key_d:
		# make sure ship is not in right column
		div	$s1, $t1						# see if ship position is divisible by the width
		mfhi	$t9							# $t9 = $s1 mod $t1 
		addi	$t1, $t1, -48						# need to check if the mod is the row size - 12*4 (width of plane-1)
		beq	$t9, $t1, keypress_done					# if it is in the far right column, we can't go right
		addi	$s1, $s1, 4						# else, move right
		b keypress_done

	# go down
	key_s:
		# make sure ship is not in bottom row
		bgt	$s1, $t3, keypress_done					# if $s1 is in the bottom row, don't go down
		addi	$s1, $s1, SHIFT_NEXT_ROW				# else, move down
		b keypress_done

	keypress_done:
		jr	$ra							# jump to ra
# ------------------------------------

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
		sw	$t0, 0($sp)
		# call draw star
		jal	draw_star
		# restore $t0 and $ra						draw the star at $a0 position
		lw	$t0, 0($sp)
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
# shift stars
shift_stars:
	# $t0: current star address
	# $t1: address of block right after the array
	shift_stars_loop:
		# only shift if they are not in the 
	jr	$ra
# ------------------------------------


# DRAW functions:

# ------------------------------------
# clear screen between given addresses
	# $a0: start address
	# $a1: end address
	# $a2: negative of the width*4 of box to clear
	# use:
		# $t0: COLOUR_NIGHT
		# $t1: negative increment
clear:
	li	$t0, COLOUR_NIGHT
	li	$t1, 0								# increment
	
	clear_loop:
		bgt	$a0, $a1, clear_loop_done
		# if the increment is equal to the negative width, go down a row
		beq	$t1, $a2, clear_loop_next_row
		sw	$t0, 0($a0)						# clear $a0 colour
		addi	$a0, $a0, 4						# $a0 = $a0 + 4
		addi	$t1, $t1, -4						# $t1 = $t1 - 4
		j	clear_loop						# jump to clear_loop
	clear_loop_next_row:
		add	$a0, $a0, $t1						# $a0 = $a0 - width*4
		addi	$a0, $a0, SHIFT_NEXT_ROW				# set $a0 to next row
		li	$t1, 0							# reset increment $t1 = 0
		j clear_loop
	clear_loop_done:
		jr	$ra							# jump to $ra
# ------------------------------------


# ------------------------------------
# draw ship at a certain position
	# $a0: position
draw_ship:
	li	$t0, COLOUR_BLUE						# $t1 = COLOUR_BLUE
	li	$t1, COLOUR_YELLOW						# $t1 = COLOUR_YELLOW
	li	$t2, COLOUR_RED							# $t1 = COLOUR_RED
	
	sw	$t0, 0($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
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
# draw star at given position
	# $a0: position
		# $t9: use temp
draw_star:
	li	$t0, COLOUR_STAR
	sw	$t0, 0($a0)
	jr	$ra
# ------------------------------------

	
	
	
