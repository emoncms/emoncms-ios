bootstrap:
	carthage bootstrap --platform iOS

update:
	carthage update --platform iOS
	./ackack.py
