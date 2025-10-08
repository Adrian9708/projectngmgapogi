extends Control
var money = 0
var pizzas_delivered = 0
@onready var health_bar: ProgressBar = $Health
@onready var money_: Label = $"Money Icon/Money label"
@onready var delivered_pizza_label: Label = $"Money Icon/Delivery Counts"
@onready var timer_label: Label = $"Money Icon/Timer Label"

# CHANGED: 60 second delivery timer
var countdown_time: float = 60.0
var timer_active: bool = false
var space_was_pressed: bool = false  # Add this as a class variable

func _ready():
	# IMPORTANT: Make sure this node can receive input
	set_process_input(true)
	
	# Initialize health bar to full (100)
	if health_bar:
		health_bar.max_value = 100
		health_bar.value = 100
	
	# Initialize UI
	if money_:
		money_.text = "$" + str(money)
	
	if delivered_pizza_label:
		delivered_pizza_label.text = "Pizza Delivered " + str(pizzas_delivered) + "/10"
	
	if timer_label:
		timer_label.modulate = Color.YELLOW
		print("Timer label found and ready")
	
	# Start first delivery timer
	start_delivery_timer()

# FIXED: Use _unhandled_input instead of _input
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("SPACE KEY DETECTED!")  # Keep this one for space key confirmation
			trigger_delivery()
			get_viewport().set_input_as_handled()  # Mark input as handled

# ALTERNATIVE: Also check in _process for direct key polling
func _process(delta):
	# Simple space key detection - this should definitely work
	if Input.is_action_just_pressed("ui_accept"):  # Space is mapped to ui_accept by default
		print("SPACE KEY PRESSED!")
		trigger_delivery()
	
	if timer_active:
		countdown_time -= delta  # Count down from 60 seconds
		
		# Check if timer finished (time ran out)
		if countdown_time <= 0:
			countdown_time = 0
			timer_failed()  # Player didn't deliver in time
		
		update_timer_display()

func update_timer_display():
	if timer_label:
		if timer_active:
			# Show countdown in minutes:seconds format
			var minutes = int(countdown_time) / 60
			var seconds = int(countdown_time) % 60
			timer_label.text = "Deliver in: " + str(minutes) + ":" + "%02d" % seconds
			
			# Make sure timer is visible
			timer_label.visible = true
			
			# Change color when time is running low
			if countdown_time < 10.0:  # Last 10 seconds
				timer_label.modulate = Color.RED
			elif countdown_time < 30.0:  # Last 30 seconds
				timer_label.modulate = Color.ORANGE
			else:
				timer_label.modulate = Color.YELLOW
				
			#print("Timer display updated: ", timer_label.text)  # Debug line
		else:
			timer_label.text = "Ready for delivery!"
			timer_label.modulate = Color.GREEN
			timer_label.visible = true
	else:
		print("Timer label not found!")  # Debug line

func start_delivery_timer():
	countdown_time = 60.0  # 1 minute timer
	timer_active = true
	print("New delivery started! You have 60 seconds!")
	
	# Make sure timer label is visible and updated
	if timer_label:
		timer_label.visible = true
		update_timer_display()
	else:
		print("ERROR: Timer label not found in start_delivery_timer!")

# Called when player successfully delivers pizza (call this from your delivery mechanism)
func deliver_pizza_success():
	if timer_active:  # Only if timer is still running
		timer_active = false
		pizzas_delivered += 1
		
		# Update UI
		if delivered_pizza_label:
			delivered_pizza_label.text = "Pizza Delivered " + str(pizzas_delivered) + "/10"
		
		if timer_label:
			timer_label.text = "Pizza Delivered!"
			timer_label.modulate = Color.GREEN
		
		# Add money for successful delivery
		money += 20  # $20 per pizza
		if money_:
			money_.text = "$" + str(money)
		
		print("Pizza delivered successfully! +$20")
		
		# Check if game is complete
		if pizzas_delivered >= 10:
			game_complete()
		else:
			# Start next delivery after 2 seconds
			await get_tree().create_timer(2.0).timeout
			start_delivery_timer()

# Called when timer runs out (player failed to deliver)
func timer_failed():
	timer_active = false
	print("Delivery failed! Time ran out!")
	
	# Remove health
	if health_bar:
		health_bar.value -= 10  # Lose 10 health points
		print("Health reduced! Current health: ", health_bar.value)
		
		# Check if player is dead
		if health_bar.value <= 0:
			game_over()
			return
	
	if timer_label:
		timer_label.text = "FAILED - Try again!"
		timer_label.modulate = Color.RED
	
	# Start new delivery after 3 seconds
	await get_tree().create_timer(3.0).timeout
	start_delivery_timer()

func update_health(amount):
	print("updating health")
	if health_bar:
		health_bar.value += amount
		# Make sure health doesn't exceed maximum
		if health_bar.value > health_bar.max_value:
			health_bar.value = health_bar.max_value


func update_money(money_to_add):
	money += money_to_add
	if money_:
		money_.text = "$" + str(money)

func game_complete():
	print("Congratulations! All 10 pizzas delivered!")
	if timer_label:
		timer_label.text = "ALL PIZZAS DELIVERED!"
		timer_label.modulate = Color.GOLD
	# Add your win condition code here

func game_over():
	print("Game Over! Health reached zero!")
	if timer_label:
		timer_label.text = "GAME OVER"
		timer_label.modulate = Color.RED
	# Add your game over code here (restart, menu, etc.)

# Call this function when the player reaches the delivery destination
func trigger_delivery():
	print("TRIGGER_DELIVERY CALLED!")  # Debug line
	if timer_active:
		print("Timer is active, delivering pizza!")  # Debug line
		deliver_pizza_success()
	else:
		print("Timer is not active, cannot deliver!")  # Debug line

# Add this function for compatibility with other scripts that might call it
func deliver_pizza():
	print("deliver_pizza() called - redirecting to deliver_pizza_success()")
	deliver_pizza_success()
