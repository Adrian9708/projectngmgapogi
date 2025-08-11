extends Control

var money  = 100
var pizzas_delivered = 0
@onready var health_bar: ProgressBar = $ProgressBar
@onready var money_: Label = $"Money Icon/Money label"
@onready var delivered_pizza_label: Label = $"Money Icon/Label"


	 
func update_health(amount):
	health_bar.value += amount

func update_money(money_to_add):
	money_.text = "$"+str(money+money_to_add)
	
	
func deliver_pizza():
	pizzas_delivered+=1
	delivered_pizza_label.text = "Pizza Delivered "+str(pizzas_delivered)+"/10" 
	

	
