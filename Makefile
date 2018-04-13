setenv:
	./tools/setenv

build: setenv
	docker build . -t hd-image

run:
	docker run -d -it --name hd-container -p 80:80 -p 9100:9100 hd-image

run-i:
	docker run -it --name hd-container -p 80:80 -p 9100:9100 hd-image

stop:
	/usr/local/bin/docker-clean run -s

rerun: build stop run

rerun-i: build stop run-i
