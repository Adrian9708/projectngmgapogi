extends Control
var money = 100
var pizzas_delivered = 0
@onready var health_bar: ProgressBar = $ProgressBar
@onready var money_: Label = $"Money Icon/Money label"
@onready var delivered_pizza_label: Label = $"Money Icon/Delivery Counts"
@onready var timer_label: Label = $"Delivery time/Timer Label"

# CHANGED: Replace time_elapsed with countdown variables
var countdown_time: float = 1.0
var timer_active: bool = false

func _ready():
	if timer_label:
		timer_label.modulate = Color.YELLOW  # Make it yellow so we can see it
		print("Our timer label found and set to yellow")
	
	# ADDED: Start the countdown timer
	start_delivery_timer()
	update_timer_display()

# CHANGED: Modified _process to count down instead of up
func _process(delta):
	if timer_active:
		countdown_time -= delta  # Count DOWN instead of up
		
		# Check if timer finished
		if countdown_time <= 0:
			countdown_time = 0
			timer_finished()
		
		update_timer_display()

# CHANGED: Modified to show countdown instead of elapsed time
func update_timer_display():
	if timer_label:
		if timer_active:
			# Show countdown with 1 decimal place
			timer_label.text = "Delivery: " + str("%.1f" % countdown_time) + "s"
			
			# Change color when time is low
			if countdown_time < 0.3:
				timer_label.modulate = Color.RED
			else:
				timer_label.modulate = Color.YELLOW
		else:
			timer_label.text = "Ready!"
			timer_label.modulate = Color.GREEN

# ADDED: Function to start the delivery timer
func start_delivery_timer():
	countdown_time = 1.0  # Reset to 1 second
	timer_active = true
	print("Delivery timer started!")

# ADDED: Function when timer finishes
func timer_finished():
	timer_active = false
	print("Delivery timer finished!")
	timer_label.text = "Delivered!"
	timer_label.modulate = Color.GREEN
	
	# Automatically deliver pizza when timer finishes
	deliver_pizza()
	
	# Start next delivery after 1 second delay
	get_tree().create_timer(1.0).timeout.connect(start_delivery_timer)

func update_health(amount):
	if health_bar:
		health_bar.value += amount

func update_money(money_to_add):
	if money_:
		money_.text = "$" + str(money + money_to_add)

func deliver_pizza():
	if pizzas_delivered < 10:
		pizzas_delivered += 1
		if delivered_pizza_label:
			delivered_pizza_label.text = "Pizza Delivered " + str(pizzas_delivered) + "/10"
