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
.eqv	DISPLAY_LAST_ADDRESS	0x10009FFC	# update this given the values below shift +(64*32-1)*4
.eqv	NEXT_ROW		256		# next row shift = width*4 = 64*4

.eqv	COLOUR_NIGHT		0x00112135
.eqv	COLOUR_RED		0x00f40343
.eqv	COLOUR_ROCK		0x00393f44
.eqv	COLOUR_BLUE		0x001d69da
.eqv	COLOUR_YELLOW		0x00dcff30


.data
# variables
# use arrays for storing obstacle locations


.text
.globl main

main:
	# ------------------------------------
	# clear screen
	li	$a0, DISPLAY_FIRST_ADDRESS
	li	$a1, DISPLAY_LAST_ADDRESS
	jal	clear				# jump to clear and save position to $ra
	# ------------------------------------
	
	# $s1: ship location
	main_loop:
		# ------------------------------------
		# Check for keyboard input and update ship location.

		# ------------------------------------
		# Update obstacle location.
		# Check for various collisions (e.g., between ship and obstacles).
		# Update other game state and end of game.
		# Erase objects from the old position on the screen.
		# ------------------------------------
		# Redraw objects in the new position on the screen.
		li	$a0, DISPLAY_FIRST_ADDRESS
		jal	draw_ship				# jump to draw_ship and save position to $ra
		# ------------------------------------

		# At the end of each iteration, your main loop should sleep for a short time and go back to step 1.

# end program
end:
	li	$v0, 10				# $v0 = 10 terminate the program gracefully
	syscall




#####################################################################
#                        my functions                               #
#####################################################################


# ------------------------------------
# clear screen between given addresses
	# $a0: start address
	# $a1: end address
clear:
	li	$t0, COLOUR_NIGHT
	clear_loop:
		beq	$a0, $a1, clear_loop_done
		sw	$t0, 0($a0)
		addi	$a0, $a0, 4			# $a0 = $a0 + 4
		j	clear_loop			# jump to clear_loop
	clear_loop_done:
		jr	$ra				# jump to $ra
# ------------------------------------



# ------------------------------------
# draw ship at a certain position
	# $a0: position
draw_ship:
	li	$t0, COLOUR_BLUE			# $t1 = COLOUR_BLUE
	li	$t1, COLOUR_YELLOW			# $t1 = COLOUR_YELLOW
	li	$t2, COLOUR_RED				# $t1 = COLOUR_RED
	
	addi	$a0, $a0, NEXT_ROW
	addi	$a0, $a0, NEXT_ROW				# go to second row
	sw	$t0, 0($a0)
	addi	$a0, $a0, NEXT_ROW
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	addi	$a0, $a0, NEXT_ROW
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
	addi	$a0, $a0, NEXT_ROW
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
	addi	$a0, $a0, NEXT_ROW
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t2, 16($a0)
	sw	$t2, 20($a0)
	sw	$t2, 24($a0)
	sw	$t2, 28($a0)
	sw	$t2, 32($a0)
	addi	$a0, $a0, NEXT_ROW
	sw	$t2, 8($a0)
	sw	$t2, 12($a0)

	jr	$ra					# jump to 
	


	
	
	
