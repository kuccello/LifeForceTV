go:
	thin start --debug --threaded -R config.ru -p 8080

model:
	cd model
	ruby xampl-gen.rb
